import pandas as pd
import numpy as np
import scipy.signal
import scipy.optimize
import matplotlib.pyplot as plt


SAMPLE_RATE = 50e6
SPEED = 1480
# APPROX_DEPTH = 1.6e-2
# DEPTH_TOLERANCE = 1.5e-2  # 1 cm
MIN_DEPTH = 8e-3
MAX_DEPTH= 32e-3

CUTOFF_FREQ_LO = 1.2e6
CUTOFF_FREQ_HI = 2.0e6

ULTRASOUND_FREQ = 2e6

QUAL_THRES = 0.50e-6 # time certinty required to be useful

def depth_to_index(depth):
    return int(round(depth / SPEED * SAMPLE_RATE * 2))

def index_to_depth(index):
    return index / SAMPLE_RATE * SPEED / 2

def index_to_dist(index):
    return index / SAMPLE_RATE * SPEED



def find_calib_point(wave):
    start_idx = depth_to_index(MIN_DEPTH)
    end_idx = depth_to_index(MAX_DEPTH)
    # maxidx = int(np.argmax(wave[start_idx:end_idx]))

    t = np.arange(-3e-6, 3e-6, 1/SAMPLE_RATE)
    pulse = scipy.signal.gausspulse(t, fc=ULTRASOUND_FREQ, bw=0.6, bwr=-6)
    pulse -= np.mean(pulse)
    pulse /= np.linalg.norm(pulse)

    sect_norm = wave[start_idx:end_idx] / np.linalg.norm(wave[start_idx:end_idx])

    corr = np.correlate(sect_norm, pulse, mode='valid')
    # peaks, props = scipy.signal.find_peaks(corr, distance=len(pulse)//2)
    maxidx = np.argmax(corr) + len(pulse) // 2

    # print(peaks, props)
    # maxidx = peaks[0]

    # plt.plot(pulse)
    # plt.plot(sect_norm)
    # plt.plot(corr)
    # plt.plot([maxidx, maxidx], [min(corr), max(corr)], 'r--')

    return maxidx + start_idx
    # print(start_idx, end_idx)

    # plt.plot(wave)
    # plt.plot([start_idx, start_idx], [min(wave), max(wave)], 'r--')
    # plt.plot([end_idx, end_idx], [min(wave), max(wave)], 'r--')

    # plt.plot(np.array(wave[start_idx:depth_to_index(APPROX_DEPTH+DEPTH_TOLERANCE)]))
    # plt.plot([maxidx, maxidx], [min(wave[start_idx:end_idx]), max(wave[start_idx:end_idx])], 'r--')
    # plt.plot(peaks, wave[start_idx:depth_to_index(APPROX_DEPTH+DEPTH_TOLERANCE)][peaks], "x")
    # plt.show()


def read_calib_csv(filename):
    df = pd.read_csv(filename)

    channel_name = {
        0: 'E',
        1: 'F',
        2: 'H',
        3: 'G',
        4: 'A',
        5: 'B',
        6: 'D',
        7: 'C',
    }
    raw_data = np.zeros((8, 8, len(df)))
    for scanline in range(8):
        for channel in range(8):
            raw_data[scanline, channel, :] = df[f'sl{scanline}_ch{channel_name[channel]}']
    return raw_data


def find_calib_time(raw_data):
    points = np.zeros((8, 8))  # 8 scanlines, 8 channels
    for scanline in range(8):
        for channel in range(8):
            wave = raw_data[scanline, channel, :]
            calib_point = find_calib_point(wave)
            calib_dist = index_to_dist(calib_point)
            points[scanline, channel] = calib_point / SAMPLE_RATE
            # print(f"Scanline {scanline}, Channel {chr(ord('A')+channel)}: Calibration Point = {calib_point}, Depth = {calib_depth}")

    return points

def solve(raw_datas):
    k = len(raw_datas)
    
    times = [find_calib_time(raw_data) for raw_data in raw_datas]

    # plt.plot(np.concatenate([np.abs(d - d.T) for d in times]))
    # plt.show()

    time_ests = np.concatenate([d.reshape((8, 8, 1)) for d in times], axis=2)
    time_estsT = np.swapaxes(time_ests, 0, 1)

    errs = np.abs(time_ests - time_estsT) > QUAL_THRES

    print(np.sum(errs), '/', k*8*8, 'errored measurements')
    
    filtered_time_ests = (time_ests + time_estsT) / 2
    filtered_time_ests[errs] = np.nan

    # independent variables:
    # channel1_offset[7] (note: channel0 assumed to be at 0, all assumed to be at zero y, so these are all x offsets)
    # wire_x[k]
    # wire_y[k]
    # channel_tau[8]
    # speed
    
    def residuals(x: np.ndarray) -> np.ndarray:
        chan_offsets = np.concatenate([[0], x[0:7]]).reshape((8, 1))
        wire_x = x[7:7+k].reshape((1, 1, k))
        wire_y = x[7+k:7+2*k].reshape((1, 1, k))
        tau = x[7+2*k:7+2*k+8].reshape((8, 1))
        speed = x[7+2*k+8]

        chan_src = chan_offsets.reshape((1, 8, 1))
        chan_dst = chan_offsets.reshape((8, 1, 1))


        time_model = + (
            np.sqrt((wire_x - chan_src)**2 + (wire_y)**2) +
            np.sqrt((wire_x - chan_dst)**2 + (wire_y)**2)) / SPEED
        print(time_model.shape)


        ret = time_model - filtered_time_ests
        ret[np.isnan(ret)] = 0 # these are always 'perfect' as they aren't beint treated as real points
        return ret.flatten()

    x0 = np.concatenate([np.linspace(0, 1e-2, 7), np.zeros(k), np.zeros(k) + 1e-2, np.zeros(8), [1540]])
    bounds= (
        np.concatenate([np.zeros(7) - 25e-3, np.zeros(k) - 50e-3, np.zeros(k), np.zeros(8), [1000]]),
        np.concatenate([np.zeros(7) + 25e-3, np.zeros(k) + 50e-3, np.zeros(k) + 20e-3, np.zeros(8) + 60e-6, [2000]]),
    )

    return scipy.optimize.least_squares(
        residuals, 
        x0=x0,
        bounds=bounds,

    )