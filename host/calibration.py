"""
Element geometry / timing calibration from single-element wire-echo captures.

Input: array_*.csv files saved by the client with the "fire one element at a
time" delay table (delays.py calibration_main): scanline i fires pulser
channel i alone, and every ADC channel records the echo from a wire target
in a water tank.  Each file is one wire position; use as many positions
(laterally spread out) as you can.

Model (all times relative to the start-of-line marker, element i at
(x_i, z_i) in the imaging plane with z towards the target, wire k a point
at (wx_k, wy_k)):

    t[i, j, k] = T0 + tau_i + tau_j + (|w_k - e_i| + |w_k - e_j|) / c

    T0     hardware latency from start-of-line to firing at delay-table 0,
           plus the echo-shape fiducial offset (the envelope peak).  It is
           degenerate with the wire depths (a later T0 is a nearer wire),
           so it is fixed from the transmit artifact (~0.8 us onset plus
           ~0.7 us to the echo envelope peak) rather than fitted; see --t0.
           Getting it wrong by dt only shifts the depth axis by c*dt/2.
    tau_i  per-element extra delay, the same on transmit and receive (the
           measured matrices are symmetric to within one sample), bounded
           to +-1 us with a weak pull towards 0 (it is nearly degenerate
           with z_i over the calibrated angles).
    e_i    element position; pulser channel 0 at the origin and the
           least-squares line through the elements as the x axis.  The
           elements are not collinear: 6 and 7 sit ~10 mm from the rest
           and ~1.5 mm behind, i.e. the probe face is curved.

Receive polarity per element is estimated as well: some receive channels
are inverted relative to the others and would cancel in a delay-and-sum.

Output: calibration.csv, one row per pulser channel `x_m,z_m,tau_s,sign`, with
`# t0_s=...` and `# c_m_s=...` header lines.  Load it in the client (it
also drives delays.py).

    python calibration.py array_*.csv --out calibration.csv --plot calib.png
"""

import argparse
import glob
import os
import sys

import numpy as np
import pandas as pd
import scipy.optimize
import scipy.signal

SAMPLE_RATE = 50e6
SPEED = 1482.0  # m/s, water at ~20 C.  Sets the geometric scale.

# echo band; the pulse comes back centred around 1.8-2 MHz
BAND = (1.0e6, 3.5e6)

# ADC channel letter driven by each pulser channel
PULSER_TO_ADC = {0: 'E', 1: 'F', 2: 'H', 3: 'G', 4: 'A', 5: 'B', 6: 'D', 7: 'C'}
ADC_NAMES = 'ABCDEFGH'

# echoes closer than this are inside the transmit ringing
MIN_ECHO_TIME = 12e-6
# records are cropped here; the wire echo is well before the tank bottom
MAX_RECORD_TIME = 120e-6
# keep clear of the (saturating) tank bottom echo
BOTTOM_GUARD = 5e-6
# echo search half-window around the frame's mean echo time: elements can be
# >10 mm apart so their echoes differ by several us
COARSE_HALF_WINDOW = 5e-6
# T0 (see module docstring): fixed by default, --t0-free bounds it instead
T0_DEFAULT_US = 1.5
T0_FREE_BOUNDS_US = (1.0, 2.5)
TAU_MAX_US = 1.0
# weak ridge on tau (residual = TAU_PRIOR * tau): tau and an element's z
# offset are nearly degenerate over the calibrated angles, so prefer the
# geometric explanation unless the data insist
TAU_PRIOR = 0.1
Z_MAX_MM = 5.0

MIN_SNR = 8.0
MIN_CORR = 0.5

_SOS = scipy.signal.butter(4, BAND, btype='band', fs=SAMPLE_RATE, output='sos')


def read_calib_csv(filename):
    """raw[tx pulser channel, rx pulser channel, sample]"""
    df = pd.read_csv(filename)
    n = min(len(df), int(MAX_RECORD_TIME * SAMPLE_RATE))
    raw = np.zeros((8, 8, n), dtype=np.float32)
    for tx in range(8):
        for rx in range(8):
            raw[tx, rx] = df[f'sl{tx}_ch{PULSER_TO_ADC[rx]}'].to_numpy()[:n]
    return raw


def bandpass(raw):
    return scipy.signal.sosfiltfilt(_SOS, raw.astype(np.float64), axis=-1).astype(np.float32)


def coarse_pick(raw, filt):
    """Envelope-peak echo times [8, 8] (s) and SNR for one file."""
    n = raw.shape[2]
    env = np.abs(scipy.signal.hilbert(filt.astype(np.float64), axis=-1)).astype(np.float32)
    t_min = int(MIN_ECHO_TIME * SAMPLE_RATE)
    sat = np.any(np.abs(raw[:, :, t_min:]) >= 2040, axis=(0, 1))
    t_bot = (int(np.argmax(sat)) + t_min) if sat.any() else n
    t_max = min(n, t_bot - int(BOTTOM_GUARD * SAMPLE_RATE))
    if t_max - t_min < int(4e-6 * SAMPLE_RATE):
        raise ValueError('no usable window between transmit ringing and bottom echo')
    mean_env = env[:, :, t_min:t_max].mean(axis=(0, 1))
    g = int(np.argmax(mean_env)) + t_min
    half = int(COARSE_HALF_WINDOW * SAMPLE_RATE)
    lo, hi = max(t_min, g - half), min(t_max, g + half)
    peaks = np.argmax(env[:, :, lo:hi], axis=2) + lo
    noise = np.median(env[:, :, t_min:t_max], axis=2)
    ii, jj = np.meshgrid(range(8), range(8), indexing='ij')
    snr = env[ii, jj, peaks] / noise
    return peaks / SAMPLE_RATE, snr


def rx_signs(filt, times, snr):
    """Receive polarity of each element relative to element 0, from the
    sign of the peak cross-correlation between rx j and rx 0 for the same
    transmitter."""
    seg = int(2e-6 * SAMPLE_RATE)
    lag = int(0.7e-6 * SAMPLE_RATE)
    n = filt.shape[2]
    votes = np.zeros(8)
    for i in range(8):
        p0 = int(round(times[i, 0] * SAMPLE_RATE))
        if not (seg + lag < p0 < n - seg - lag) or snr[i, 0] < MIN_SNR:
            continue
        ref = filt[i, 0, p0 - seg:p0 + seg]
        for j in range(8):
            pj = int(round(times[i, j] * SAMPLE_RATE))
            if not (seg + lag < pj < n - seg - lag) or snr[i, j] < MIN_SNR:
                continue
            c = np.correlate(filt[i, j, pj - seg - lag:pj + seg + lag], ref, mode='valid')
            votes[j] += np.sign(c[np.argmax(np.abs(c))]) * min(snr[i, j], 50)
    return votes


# --- model -----------------------------------------------------------------
# parameter vector (scaled: us and mm):
#   [T0, tau_1..7, x_1..7, z_2..7, wx_0..K-1, wy_0..K-1]
# (z_0 = z_1 = 0 fixes the rotation during the fit; the result is rotated
# onto the least-squares element line afterwards)
C_MM_US = SPEED * 1e-3
NP = 1 + 7 + 7 + 6


def unpack(x, k):
    t0 = x[0]
    tau = np.concatenate([[0.0], x[1:8]])
    ex = np.concatenate([[0.0], x[8:15]])
    ez = np.concatenate([[0.0, 0.0], x[15:21]])
    wx = x[NP:NP + k]
    wy = x[NP + k:NP + 2 * k]
    return t0, tau, ex, ez, wx, wy


def model(x, k):
    t0, tau, ex, ez, wx, wy = unpack(x, k)
    d = np.sqrt((wx[None, :] - ex[:, None]) ** 2 + (wy[None, :] - ez[:, None]) ** 2)  # [elem, k]
    return t0 + tau[:, None, None] + tau[None, :, None] + (d[:, None, :] + d[None, :, :]) / C_MM_US


def fit(times_us, weights, x0, loss='linear', f_scale=0.1, t0_bounds=(T0_DEFAULT_US, T0_DEFAULT_US)):
    k = times_us.shape[2]

    def residuals(x):
        return np.concatenate([((model(x, k) - times_us) * weights).ravel(), TAU_PRIOR * x[1:8]])

    lb = np.concatenate([[t0_bounds[0] - 1e-6], np.full(7, -TAU_MAX_US), np.full(7, -60), np.full(6, -Z_MAX_MM), np.full(k, -45), np.full(k, 8)])
    ub = np.concatenate([[t0_bounds[1] + 1e-6], np.full(7, TAU_MAX_US), np.full(7, 60), np.full(6, Z_MAX_MM), np.full(k, 45), np.full(k, 80)])
    x0 = np.clip(x0, lb + 1e-9, ub - 1e-9)
    return scipy.optimize.least_squares(
        residuals, x0, bounds=(lb, ub), loss=loss, f_scale=f_scale,
        max_nfev=3000, xtol=1e-10, ftol=1e-10, gtol=1e-10)


def initial_layout(times_us, weights):
    """Element x ordering from the rank-1 structure of the receive-time
    profiles across wire positions (far-field: profile ~ x_j * sin(theta_k))."""
    k = times_us.shape[2]
    good = [kk for kk in range(k) if (weights[:, :, kk] > 0).sum() >= 32]
    prof = np.zeros((8, len(good)))
    for n, kk in enumerate(good):
        w = weights[:, :, kk]
        t = times_us[:, :, kk]
        col = np.array([np.average(t[:, j], weights=w[:, j]) if w[:, j].sum() else np.nan for j in range(8)])
        prof[:, n] = col - np.nanmean(col)
    prof = np.nan_to_num(prof - np.nanmean(prof, axis=1, keepdims=True))
    u, s, _ = np.linalg.svd(prof, full_matrices=False)
    shape = u[:, 0] - u[0, 0]
    return shape


def refine(filt, pred_us, snr, signs, lag_us):
    """Sub-sample echo times by correlating each echo against a per-file
    template built from the (polarity-corrected) echoes aligned on the model
    prediction.  The lobe nearest the prediction within +-lag_us wins."""
    fs = SAMPLE_RATE
    n = filt.shape[2]
    seg = int(2.0e-6 * fs)
    lag = int(lag_us * 1e-6 * fs)
    p = np.round(pred_us * 1e-6 * fs).astype(int)
    ok = (p > seg + lag) & (p < n - seg - lag - 1) & (snr >= MIN_SNR)
    segs = np.zeros((8, 8, 2 * seg))
    for i in range(8):
        for j in range(8):
            if ok[i, j]:
                segs[i, j] = filt[i, j, p[i, j] - seg:p[i, j] + seg] * signs[j]
    w = np.where(ok, np.minimum(snr, 60.0), 0.0)
    if w.sum() == 0:
        return np.full((8, 8), np.nan), np.zeros((8, 8))
    tmpl = (segs * w[:, :, None]).sum((0, 1)) / w.sum()
    fid = int(np.argmax(np.abs(scipy.signal.hilbert(tmpl))))
    tn = np.linalg.norm(tmpl) + 1e-12
    times = np.full((8, 8), np.nan)
    quality = np.zeros((8, 8))
    for i in range(8):
        for j in range(8):
            if not ok[i, j]:
                continue
            s = filt[i, j, p[i, j] - seg - lag:p[i, j] + seg + lag] * signs[j]
            c = np.correlate(s, tmpl, mode='valid')
            m = int(np.argmax(c))
            frac = 0.0
            if 0 < m < len(c) - 1:
                y0, y1, y2 = c[m - 1], c[m], c[m + 1]
                den = y0 - 2 * y1 + y2
                if den != 0:
                    frac = 0.5 * (y0 - y2) / den
            times[i, j] = (p[i, j] - seg + (m - lag + frac) + fid) / fs * 1e6
            quality[i, j] = c[m] / (np.linalg.norm(s[lag:lag + 2 * seg]) * tn + 1e-12)
    return times, quality


class Result:
    pass


def solve(raws, names=None, t0_bounds=(T0_DEFAULT_US, T0_DEFAULT_US), verbose=True):
    """Full calibration from a list of raw[tx, rx, t] arrays (one per wire
    position)."""
    k = len(raws)
    names = names or [f'file{i}' for i in range(k)]
    log = print if verbose else (lambda *a, **kw: None)

    filts, coarse, snrs, votes = [], [], [], np.zeros(8)
    usable = []
    for kk, raw in enumerate(raws):
        f = bandpass(raw)
        try:
            t, s = coarse_pick(raw, f)
        except ValueError as e:
            log(f'{names[kk]}: skipped ({e})')
            t, s = np.full((8, 8), np.nan), np.zeros((8, 8))
        filts.append(f)
        coarse.append(t)
        snrs.append(s)
        if np.isfinite(t).all():
            votes += rx_signs(f, t, s)
            usable.append(kk)
        log('%-30s echo %5.1f us  median SNR %6.1f' % (names[kk], np.nanmedian(t) * 1e6, np.median(s)))
    coarse = np.stack(coarse, axis=2)
    snrs = np.stack(snrs, axis=2)
    signs = np.where(votes < 0, -1.0, 1.0)
    log('receive polarity votes:', votes.round(0), '->', signs.astype(int))

    times_us = np.nan_to_num(coarse * 1e6)
    weights = np.ones_like(times_us)
    weights[~np.isfinite(coarse)] = 0
    weights[snrs < MIN_SNR] = 0
    # transmit/receive symmetry: t[i,j] == t[j,i]; a broken pair is a bad pick
    weights[np.abs(coarse - np.swapaxes(coarse, 0, 1)) > 100e-9] = 0
    # echoes inside the transmit ringing are unreliable
    too_close = np.nanmedian(coarse, axis=(0, 1)) < 20e-6
    weights[:, :, too_close] = 0
    log('coarse picks kept: %d / %d' % ((weights > 0).sum(), weights.size))

    # --- coarse fit, multi-start over the aperture scale ---
    shape = initial_layout(times_us, weights)
    g = np.array([np.nanmedian(times_us[:, :, kk]) if weights[:, :, kk].any() else 40.0 for kk in range(k)])
    best = None
    t0_init = np.clip(T0_DEFAULT_US, *t0_bounds)
    for scale in (5, 10, 15, 20, 30):
        for sign in (1, -1):
            for zsign in (0, 1, -1):
                # elements far from the origin may sit off the line
                ez0 = np.where(np.abs(shape[2:]) > 0.3, zsign * 2.0, 0.0)
                x0 = np.concatenate([[t0_init], np.zeros(7), sign * shape[1:] * scale, ez0, np.zeros(k), g * C_MM_US / 2])
                r = fit(times_us, weights, x0, t0_bounds=t0_bounds)
                if best is None or r.cost < best.cost:
                    best = r
    x = fit(times_us, weights, best.x, loss='soft_l1', f_scale=0.15, t0_bounds=t0_bounds).x
    resid = (model(x, k) - times_us) * 1e3
    m = weights > 0
    log('coarse fit rms %.0f ns (n=%d)' % (np.sqrt((resid[m] ** 2).mean()), m.sum()))

    # --- fine (phase) refinement, iterated with the fit ---
    fine = np.zeros_like(times_us)
    quality = np.zeros_like(times_us)
    for it, lag_us in enumerate((0.6, 0.6, 0.3, 0.3)):
        pred = model(x, k)
        for kk in range(k):
            fine[:, :, kk], quality[:, :, kk] = refine(filts[kk], pred[:, :, kk], snrs[:, :, kk], signs, lag_us)
        w = weights.copy()
        w[~np.isfinite(fine)] = 0
        w[quality < MIN_CORR] = 0
        # a pick that wandered far from its coarse estimate landed on something else
        w[np.abs(np.nan_to_num(fine) - times_us) > 0.6] = 0
        fine = np.nan_to_num(fine)
        w[np.abs(fine - np.swapaxes(fine, 0, 1)) > 0.12] = 0
        x = fit(fine, w, x, loss='soft_l1', f_scale=0.03, t0_bounds=t0_bounds).x
        resid = (model(x, k) - fine) * 1e3
        m = w > 0
        log('refine %d: rms %.0f ns  median |r| %.0f ns  n=%d' % (it, np.sqrt((resid[m] ** 2).mean()), np.median(np.abs(resid[m])), m.sum()))

    # rotate the frame (about element 0) so the least-squares line through
    # the elements is the x axis; a rigid rotation leaves the fit unchanged
    t0, tau, ex, ez, wx, wy = unpack(x, k)
    slope = np.polyfit(ex, ez, 1)[0]
    ang = -np.arctan(slope)
    ca, sa = np.cos(ang), np.sin(ang)
    ex, ez = ca * ex - sa * ez, sa * ex + ca * ez
    wx, wy = ca * wx - sa * wy, sa * wx + ca * wy

    res = Result()
    res.x = x  # unrotated fit parameters, for model()
    res.t0_us, res.tau_us, res.x_mm, res.z_mm, res.wire_x_mm, res.wire_y_mm = t0, tau, ex, ez, wx, wy
    res.signs = signs
    res.times_us = fine
    res.weights = w
    res.snr = snrs
    res.resid_ns = resid
    res.names = names
    res.filts = filts
    return res


def write_calibration_csv(path, res):
    with open(path, 'w') as f:
        f.write('# element calibration, one row per pulser channel (calibration.py)\n')
        f.write('# t0_s=%.6e\n' % (res.t0_us * 1e-6))
        f.write('# c_m_s=%.1f\n' % SPEED)
        f.write('# x_m,z_m,tau_s,sign\n')
        for i in range(8):
            f.write('%.6e,%.6e,%.6e,%d\n' % (res.x_mm[i] * 1e-3, res.z_mm[i] * 1e-3, res.tau_us[i] * 1e-6, int(res.signs[i])))


def report(res):
    np.set_printoptions(linewidth=200, precision=3, suppress=True)
    print('T0 = %.3f us' % res.t0_us)
    print('element x (mm):   ', res.x_mm.round(3))
    print('element z (mm):   ', res.z_mm.round(3))
    print('element tau (ns): ', (res.tau_us * 1e3).round(0))
    print('receive polarity: ', res.signs.astype(int))
    print('wire x (mm):      ', res.wire_x_mm.round(1))
    print('wire y (mm):      ', res.wire_y_mm.round(1))
    m = res.weights > 0
    r = res.resid_ns
    print('residuals (n=%d): rms %.0f ns, median |r| %.0f ns, 90%% %.0f ns, max %.0f ns' % (
        m.sum(), np.sqrt((r[m] ** 2).mean()), np.median(np.abs(r[m])), np.percentile(np.abs(r[m]), 90), np.abs(r[m]).max()))
    for kk, name in enumerate(res.names):
        mk = m[:, :, kk]
        if not mk.any():
            print('  %-30s dropped' % name)
            continue
        rr = r[:, :, kk][mk]
        print('  %-30s n=%2d rms %4.0f ns  max %4.0f ns  wire (%.1f, %.1f) mm' % (
            name, mk.sum(), np.sqrt((rr ** 2).mean()), np.abs(rr).max(), res.wire_x_mm[kk], res.wire_y_mm[kk]))


def plot(res, path):
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt
    k = len(res.names)
    fig, axes = plt.subplots(2, 2, figsize=(16, 11))
    ax = axes[0, 0]
    m = res.weights > 0
    used = m.any(axis=(0, 1))
    ax.scatter(res.wire_x_mm[used], res.wire_y_mm[used], c='C1', label='wire positions')
    ax.scatter(res.x_mm, res.z_mm, c='C0', marker='s', label='elements')
    for i in range(8):
        ax.annotate(str(i), (res.x_mm[i], res.z_mm[i]), textcoords='offset points', xytext=(0, 6), ha='center')
    ax.set_aspect('equal'); ax.invert_yaxis(); ax.grid(alpha=0.3); ax.legend()
    ax.set_xlabel('x (mm)'); ax.set_ylabel('depth (mm)'); ax.set_title('fitted geometry')
    ax = axes[0, 1]
    ax.hist(res.resid_ns[m], bins=60)
    ax.set_xlabel('residual (ns)'); ax.set_title('timing residuals, all kept pairs')
    ax = axes[1, 0]
    per_file = [np.sqrt((res.resid_ns[:, :, kk][m[:, :, kk]] ** 2).mean()) if m[:, :, kk].any() else np.nan for kk in range(k)]
    ax.bar(range(k), per_file)
    ax.set_xticks(range(k)); ax.set_xticklabels([n[-12:-4] for n in res.names], rotation=90, fontsize=7)
    ax.set_ylabel('rms residual (ns)'); ax.set_title('per file')
    ax = axes[1, 1]
    # aligned, polarity-corrected echoes from the best well-populated file
    n_kept = m.sum(axis=(0, 1))
    score = np.where(n_kept >= 40, per_file, np.inf)
    kk = int(np.argmin(score)) if np.isfinite(score).any() else int(np.nanargmin(per_file))
    f = res.filts[kk]
    pred = model(res.x, k)[:, :, kk]
    seg = int(2e-6 * SAMPLE_RATE)
    t = (np.arange(-seg, seg) / SAMPLE_RATE) * 1e6
    for i in range(8):
        for j in range(8):
            p = int(round(pred[i, j] * 1e-6 * SAMPLE_RATE))
            if m[i, j, kk] and seg < p < f.shape[2] - seg:
                ax.plot(t, f[i, j, p - seg:p + seg] * res.signs[j], lw=0.5, alpha=0.5)
    ax.set_xlabel('time from predicted echo (us)'); ax.set_title(f'echoes aligned by the model, polarity corrected ({res.names[kk]})')
    fig.tight_layout()
    fig.savefig(path, dpi=90)
    print('wrote', path)


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('files', nargs='*', help='array_*.csv captures (default: array_*.csv in cwd)')
    ap.add_argument('--out', default='calibration.csv')
    ap.add_argument('--plot', default=None, help='write a diagnostic png')
    ap.add_argument('--t0', type=float, default=T0_DEFAULT_US, help='T0 (us), see the module docstring')
    ap.add_argument('--t0-free', action='store_true', help='fit T0 within %s us instead of fixing it' % (T0_FREE_BOUNDS_US,))
    args = ap.parse_args(argv)
    files = args.files or sorted(glob.glob('array_*.csv'))
    if not files:
        ap.error('no input files')
    raws = [read_calib_csv(f) for f in files]
    bounds = T0_FREE_BOUNDS_US if args.t0_free else (args.t0, args.t0)
    res = solve(raws, [os.path.basename(f) for f in files], t0_bounds=bounds)
    report(res)
    write_calibration_csv(args.out, res)
    print('wrote', args.out)
    if args.plot:
        plot(res, args.plot)
    return res


if __name__ == '__main__':
    main()
