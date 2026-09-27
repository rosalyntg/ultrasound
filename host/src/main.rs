use std::collections::VecDeque;
use std::fmt::Write as _;
use std::io;
use std::num::NonZero;
use std::ops::RangeInclusive;
use std::sync::Arc;
use std::sync::atomic::{AtomicU64, Ordering::Relaxed};
use std::sync::mpsc as std_mpsc;
use std::time::{Duration, Instant, SystemTime, UNIX_EPOCH};
use std::{env, fmt};

use compio::driver::ProactorBuilder;
use libc::{SO_RCVBUF, SOL_SOCKET};
use rustfft::FftPlanner;
use rustfft::num_complex::Complex;

use iced::futures::channel::mpsc;
use iced::futures::{SinkExt, Stream, StreamExt};
use iced::mouse;
use iced::widget::{
    button, canvas, column, combo_box, container, radio, row, scrollable, slider, text, text_input,
    toggler,
};
use iced::{Center, Color, Element, Fill, Point, Rectangle, Renderer, Size, Subscription, Theme};
use iced::alignment;

use crate::ultrasound::Ultrasound;

mod ad34jx;
mod hvsupply;
mod i2c;
mod jesd204bphy;
mod mcp3021;
mod mcp401x;
#[allow(dead_code)]
mod net;
mod pulser;
mod ramp;
mod si5338;
mod ultrasound;
mod xfcp;
mod xgpio;
mod xspi;

const PULSE_DURATION_RANGE: RangeInclusive<f32> = 100.0..=2000.0; // ns (full period)
const RAMP_DELAY_RANGE: RangeInclusive<f32> = 0.0..=200.0; // µs
const RECV_TIME_RANGE: RangeInclusive<f32> = 10.0..=2000.0; // µs per scanline
const HOLDOFF_RANGE: RangeInclusive<f32> = 0.0..=131_072.0; // samples
const TRIGGER_POSITION_RANGE: RangeInclusive<f32> = 0.0..=90.0; // % of window before the trigger
const X_SCALE_EXP_RANGE: RangeInclusive<f32> = 8.0..=16.0; // samples across = 2^exp
const Y_SCALE_RANGE: RangeInclusive<f32> = 16.0..=2048.0; // ± ADC codes
const Y_OFFSET_RANGE: RangeInclusive<f32> = -2048.0..=2047.0; // ADC codes
const CONTRAST_RANGE: RangeInclusive<f32> = 0.1..=10.0; // brightness gain
const NOTCH_FREQ_RANGE: RangeInclusive<f32> = 0.0..=25.0; // MHz, up to Nyquist
const IDLE_TIME_RANGE: RangeInclusive<f32> = 0.0..=5000.0; // µs after recv before the next scanline
const NUM_SCANLINES_RANGE: RangeInclusive<f32> = 1.0..=256.0;
const BEAM_WIDTH_RANGE: RangeInclusive<f32> = 0.0..=120.0; // degrees, total steering span
const FOCAL_DISTANCE_RANGE: RangeInclusive<f32> = 5.0..=200.0; // mm

const NUM_SAMPLES_PER_PACKET: usize = 80;

/// Safety cap on samples accumulated per scanline if start-of-line
/// markers stop arriving.
const MAX_SCANLINE_SAMPLES: usize = 1 << 16;

const ADC_SAMPLE_RATE_HZ: f32 = 50e6;
const UDP_DECIMATION: f32 = 1.0;
const SAMPLE_PERIOD_S: f32 = UDP_DECIMATION / ADC_SAMPLE_RATE_HZ;

/// Default speed of sound (soft tissue), for the depth axis and the
/// transmit/receive beamforming geometry. Adjustable in the GUI: the
/// water-tank tests want ~1482 m/s.
const SPEED_OF_SOUND_M_S: f32 = 1540.0;
const SPEED_OF_SOUND_RANGE: RangeInclusive<f32> = 1400.0..=1650.0; // m/s

/// Pulser delay-table clock.
const PULSER_CLK_HZ: f32 = 156.25e6;

/// Delay-table value meaning "do not fire this channel".
const DELAY_NO_FIRE: u16 = 0xffff;

/// ADC channel index → pulser channel index. Pulser channels 0-7 drive
/// the elements read back on ADC channels E, F, H, G, A, B, D, C (see
/// read_calib_csv in calibration.py). Calibration data is stored in
/// pulser order; the RF data is in ADC order.
const ADC_TO_PULSER: [usize; 8] = [4, 5, 7, 6, 0, 1, 3, 2];

const HV_POLL_PERIOD: Duration = Duration::from_secs(1);
const RECONNECT_DELAY: Duration = Duration::from_secs(3);

/// Fastest the scope thread publishes completed captures to the GUI.
const CAPTURE_PUBLISH_PERIOD: Duration = Duration::from_millis(25);
/// Fastest the scope thread publishes completed pulsed-array frames.
const FRAME_PUBLISH_PERIOD: Duration = Duration::from_millis(50);
/// How often the in-progress pulsed-array frame is snapshotted to the
/// GUI while no complete frame has been published recently.
const PROGRESS_PUBLISH_PERIOD: Duration = Duration::from_millis(200);

pub fn main() -> iced::Result {
    // tracing_subscriber::fmt::init();
    console_subscriber::init();

    if let Some(arg1) = env::args().nth(1)
        && arg1 == "cmd"
    {
        net::main();
        return Ok(());
    }

    iced::application(App::default, App::update, App::view)
        .subscription(App::subscription)
        .title("Ultrasound Client")
        .centered()
        .run()
}

struct App {
    ramp_rate_us: f32,
    hv_plus_setpoint: f32,
    hv_minus_setpoint: f32, // magnitude, displayed negative
    pulse_duration_ns: f32,
    ramp_delay_us: f32, // gain ramp delay after the pulse
    recv_time_us: f32,  // receive window per scanline
    pulsing: bool,

    hv_plus_reading: Option<f32>,
    hv_minus_reading: Option<f32>,
    /// Setpoint limits, reported by the hardware task at connect;
    /// the setpoint controls are greyed out until then.
    hv_plus_range: Option<RangeInclusive<f32>>,
    hv_minus_range: Option<RangeInclusive<f32>>,
    ramp_rate_range: Option<RangeInclusive<f32>>, // µs

    status: String,
    hw: Option<mpsc::Sender<HwCommand>>,
    /// Commands that didn't fit in the hardware channel (a slider being
    /// dragged faster than the hardware task keeps up), one per kind
    /// with the newest replacing older ones; flushed as the task
    /// reports progress.
    hw_backlog: Vec<HwCommand>,
    /// Commands to the scope-processing thread; the GUI keeps mirrors of
    /// the settings below and forwards them on change.
    scope: Option<std_mpsc::Sender<ScopeCommand>>,

    /// Last completed capture — what the plot shows.
    traces: [Vec<f32>; 8],
    /// Notch-filtered copy of `traces`, shown instead when the notch
    /// filter is enabled. Display-only: the trigger sees raw data.
    filtered: [Vec<f32>; 8],
    notch_enabled: bool,
    notch_low_mhz: f32,
    notch_high_mhz: f32,
    channel_enabled: [bool; 8],
    acquisition: Acquisition,
    trigger_mode: TriggerMode,
    trigger_channel: usize,
    trigger_channel_cb: combo_box::State<ChannelChoice>,
    trigger_level: f32, // ADC codes
    trigger_level_text: String,
    holdoff_samples: usize,
    trigger_position_pct: f32, // portion of the window shown before the trigger
    /// Where the trigger landed in the displayed capture.
    display_trigger_index: usize,
    x_scale: usize, // samples across the plot, power of two
    y_auto: bool,
    y_scale: f32,  // ± ADC codes around the offset
    y_offset: f32, // center, ADC codes
    view_tab: ViewTab,
    bmode_mode: BModeMode,
    /// Completed pulsed-array frame: one trace per scanline, built from
    /// `array_source`. What the pulsed-array b-mode shows.
    scanlines: Vec<Vec<f32>>,
    /// Snapshot of the frame the scope thread is assembling, shown until
    /// the first frame completes.
    scanline_capture: Vec<Vec<f32>>,
    /// Full per-channel data of the last completed frame, for CSV export.
    scanline_channels: Vec<[Vec<f32>; 8]>,
    /// Live pulsed-array frame rate, measured by the scope thread.
    array_fps: Option<f32>,
    /// Latest pipeline health counters, for the stats area.
    stats: PipelineStatsSnapshot,
    show_stats: bool,
    show_scope: bool,
    show_notch: bool,
    array_source: ArraySource,
    array_source_cb: combo_box::State<ArraySource>,
    idle_time_us: f32,  // wait after recv before the next scanline
    /// Scanlines per frame, set by the loaded or generated delay table.
    num_scanlines: u32,
    delay_source: DelaySource,
    delay_csv_path: String,
    calib_csv_path: String,
    /// Element positions / channel offsets from the calibration csv,
    /// pulser channel order.
    calibration: Option<Calibration>,
    /// Add the calibrated per-channel time offsets (τ) to the transmit
    /// delays and receive beamformer.
    use_tau: bool,
    speed_of_sound: f32,   // m/s, transmit + receive beamforming and depth axis
    beam_width_deg: f32,   // total steering span of a generated table
    gen_scanlines: u32,    // scanlines in a generated table
    focal_distance_mm: f32,
    /// Geometry of the last generated delay table, for the receive
    /// beamformer. None until a table has been generated.
    beamform: Option<BeamformSettings>,
    contrast: f32, // b-mode brightness gain
    /// What the b-mode depth axis labels show.
    y_units: YUnits,
    /// Scan-convert the pulsed-array image into a sector spanning the
    /// beam width (the traditional fan), instead of one column per line.
    sector_scan: bool,
    plot_cache: canvas::Cache,
    bmode_cache: canvas::Cache,
}

/// Which visualization the main area shows.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum ViewTab {
    Scope,
    /// Amplitude as brightness vs depth, top = trigger point.
    BMode,
}

/// What the pulsed-array scanlines are built from.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum ArraySource {
    /// Average of the enabled channels.
    Average,
    /// A single channel.
    Channel(usize),
    /// Delay-and-sum receive beamforming along each scanline's transmit
    /// direction using the calibrated element geometry, then the
    /// envelope. Falls back to the average until a delay table has been
    /// generated.
    Beamformed,
}

impl fmt::Display for ArraySource {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            ArraySource::Average => write!(f, "average"),
            ArraySource::Beamformed => write!(f, "beamformed"),
            ArraySource::Channel(ch) => write!(f, "ch{}", CHANNEL_NAMES[*ch]),
        }
    }
}

/// Where the pulser's transmit delay table comes from.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum DelaySource {
    /// A raw table loaded from a csv (test / calibration patterns).
    Csv,
    /// Generated from the calibrated element geometry and the beam
    /// width / scanline count / focal distance settings, regenerated
    /// whenever any of them change.
    Beamforming,
}

/// Per-element calibration from calibration.csv (written by
/// calibration.py): one row per pulser channel, `x_m,z_m,tau_s,sign`.
/// Element position in the imaging plane relative to pulser channel 0
/// (x along the array, z towards the target), the element's extra
/// delay (applied on both transmit and receive) and its receive
/// polarity. A `# t0_s=...` header line gives the time from the
/// start-of-line marker to the firing of a channel with delay-table
/// value 0 (including the echo-shape fiducial the τ's were measured
/// against). Legacy two-column `x_m,tau_s` files load with z = 0,
/// sign = +1, t0 = 0.
#[derive(Debug, Clone, Copy, PartialEq)]
struct Calibration {
    x_el: [f32; 8], // metres, pulser order
    z_el: [f32; 8], // metres, pulser order
    tau: [f32; 8],  // seconds, pulser order
    sign: [f32; 8], // ±1, pulser order
    t0: f32,        // seconds
}

/// What the receive beamformer needs to know about the transmitted
/// frame: element geometry (in ADC channel order, matching the RF data)
/// and the scan pattern the delay table was generated for.
#[derive(Debug, Clone, Copy, PartialEq)]
struct BeamformSettings {
    x_el: [f32; 8], // metres, ADC order
    z_el: [f32; 8], // metres, ADC order
    tau: [f32; 8],  // seconds, ADC order (zero when τ is disabled)
    sign: [f32; 8], // receive polarity, ADC order
    /// Speed of sound the table was generated for.
    c: f32,
    /// Aperture (element x range, metres): scanline origins are spread
    /// across it, see scanline_origin.
    x_min: f32,
    x_max: f32,
    /// Total steering span; scanline i is steered to
    /// `scanline_angle(width, n, i)`.
    beam_width_deg: f32,
    num_scanlines: u32,
    /// Time from the start-of-line marker at which the transmit
    /// wavefront leaves the beam origin (pulser channel 0).
    t0_s: f32,
}

/// Steering angle (radians, positive = +x) of scanline `i` of `n`
/// spanning `width_deg`: numpy.linspace(+width/2, -width/2, n), as in
/// delays.py.
fn scanline_angle(width_deg: f32, n: u32, i: usize) -> f32 {
    let half = width_deg.to_radians() / 2.0;
    if n <= 1 {
        return 0.0;
    }
    let i = (i as u32).min(n - 1) as f32;
    half - i * (2.0 * half) / (n - 1) as f32
}

/// x (metres) of the boundary between scanlines `j - 1` and `j` of `n`
/// when the beam origins are spread across the aperture `x_min..x_max`:
/// boundary 0 sits half a step beyond `x_max` (the +θ end, drawn at the
/// left) and boundary n half a step beyond `x_min`. A single line's
/// boundaries are the aperture ends.
fn sector_boundary_x(x_min: f32, x_max: f32, n: u32, j: usize) -> f32 {
    let width = x_max - x_min;
    if n <= 1 {
        x_max - j as f32 * width
    } else {
        let step = width / (n - 1) as f32;
        x_max + step / 2.0 - j as f32 * step
    }
}

/// Steering angle (radians) of the boundary between scanlines `j - 1`
/// and `j`; the counterpart of sector_boundary_x.
fn sector_boundary_angle(width_deg: f32, n: u32, j: usize) -> f32 {
    let half = width_deg.to_radians() / 2.0;
    if n <= 1 {
        half - j as f32 * 2.0 * half
    } else {
        let pitch = 2.0 * half / (n - 1) as f32;
        half + pitch / 2.0 - j as f32 * pitch
    }
}

/// Beam origin (x, metres, at z = 0) of scanline `i` of `n`: the lines
/// start spread evenly across the aperture, from `x_max` for line 0 to
/// `x_min` for the last, so the image is a trapezoid rather than a fan
/// from a point. The midpoint of the line's two boundaries.
fn scanline_origin(x_min: f32, x_max: f32, n: u32, i: usize) -> f32 {
    let i = (i as u32).min(n.max(1) - 1) as usize;
    (sector_boundary_x(x_min, x_max, n, i) + sector_boundary_x(x_min, x_max, n, i + 1)) / 2.0
}

/// How the b-mode tab renders.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum BModeMode {
    /// One column per scanline, assembled from the packet start-of-frame
    /// / start-of-line markers — the traditional ultrasound image.
    PulsedArray,
    /// One column per channel from the scope capture, for debugging.
    Raw,
}

/// What the b-mode depth axis labels show.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum YUnits {
    /// Round-trip depth at the selected speed of sound.
    Depth,
    /// Time from the start of the line/trigger.
    Time,
}

/// How an armed acquisition starts a capture.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum TriggerMode {
    /// Capture immediately — continuously scrolling data.
    Auto,
    /// Wait for the trigger channel to cross the trigger level upward.
    Normal,
    /// Wait for a start-of-line packet marker, aligning the capture to
    /// a pulsed-array scanline.
    Line,
}

/// Software-trigger acquisition state.
#[derive(Debug, Clone, Copy)]
enum Acquisition {
    Stopped,
    /// Waiting for the trigger channel to cross the trigger level upward.
    Armed {
        continuous: bool,
    },
    /// Filling the capture buffers up to `x_scale` samples.
    Capturing {
        continuous: bool,
    },
}

#[derive(Clone)]
struct ChannelChoice(usize);

impl fmt::Display for ChannelChoice {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{}", CHANNEL_NAMES[self.0])
    }
}

impl Default for App {
    fn default() -> Self {
        Self {
            ramp_rate_us: 46.0,
            hv_plus_setpoint: 0.0,
            hv_minus_setpoint: 0.0,
            pulse_duration_ns: 500.0, // 2 MHz
            ramp_delay_us: 35.0,
            recv_time_us: 1000.0,
            pulsing: false,
            hv_plus_reading: None,
            hv_minus_reading: None,
            hv_plus_range: None,
            hv_minus_range: None,
            ramp_rate_range: None,
            status: String::from("starting..."),
            hw: None,
            hw_backlog: Vec::new(),
            scope: None,
            traces: Default::default(),
            filtered: Default::default(),
            notch_enabled: false,
            notch_low_mhz: 1.0,
            notch_high_mhz: 3.0,
            channel_enabled: [true; 8],
            acquisition: Acquisition::Armed { continuous: true },
            trigger_mode: TriggerMode::Line,
            trigger_channel: 0,
            trigger_channel_cb: combo_box::State::new((0..8).map(ChannelChoice).collect()),
            trigger_level: 0.0,
            trigger_level_text: String::from("0"),
            holdoff_samples: 0,
            trigger_position_pct: 0.0,
            display_trigger_index: 0,
            x_scale: 4096,
            y_auto: true,
            y_scale: 2048.0,
            y_offset: 0.0,
            view_tab: ViewTab::Scope,
            bmode_mode: BModeMode::PulsedArray,
            scanlines: Vec::new(),
            scanline_capture: Vec::new(),
            scanline_channels: Vec::new(),
            array_fps: None,
            stats: PipelineStatsSnapshot::default(),
            show_stats: false,
            show_scope: false,
            show_notch: false,
            array_source: ArraySource::Average,
            array_source_cb: combo_box::State::new(
                [ArraySource::Average, ArraySource::Beamformed]
                    .into_iter()
                    .chain((0..8).map(ArraySource::Channel))
                    .collect(),
            ),
            idle_time_us: 100.0,
            num_scanlines: 16,
            delay_source: DelaySource::Beamforming,
            delay_csv_path: String::new(),
            calib_csv_path: String::from("calibration.csv"),
            // best effort: picked up if the default file is there
            calibration: load_calibration_csv("calibration.csv").ok(),
            use_tau: true,
            speed_of_sound: SPEED_OF_SOUND_M_S,
            beam_width_deg: 40.0,
            gen_scanlines: 64,
            focal_distance_mm: 30.0,
            beamform: None,
            contrast: 1.0,
            y_units: YUnits::Depth,
            sector_scan: true,
            plot_cache: canvas::Cache::new(),
            bmode_cache: canvas::Cache::new(),
        }
    }
}

#[derive(Debug, Clone)]
enum Message {
    RampRateChanged(f32),
    ApplyRampRate,
    HvPlusSetpointChanged(f32),
    ApplyHvPlus,
    HvMinusSetpointChanged(f32),
    ApplyHvMinus,
    PulseDurationChanged(f32),
    ApplyPulseDuration,
    RampDelayChanged(f32),
    ApplyRampDelay,
    RecvTimeChanged(f32),
    ApplyRecvTime,
    InitHw,
    PulsingToggled,
    RunToggled,
    SingleShot,
    TriggerModeSelected(TriggerMode),
    TriggerChannelSelected(usize),
    TriggerLevelChanged(f32),
    TriggerLevelInputChanged(String),
    TriggerLevelInputSubmitted,
    HoldoffChanged(f32),
    TriggerPositionChanged(f32),
    XScaleChanged(f32),
    YScaleChanged(f32),
    YOffsetChanged(f32),
    YAutoPressed,
    ViewTabSelected(ViewTab),
    BModeModeSelected(BModeMode),
    ArraySourceSelected(ArraySource),
    IdleTimeChanged(f32),
    ApplyArrayConfig,
    DelayCsvPathChanged(String),
    LoadDelayCsv,
    DelaySourceSelected(DelaySource),
    /// Also (re)loads the file at the new path.
    CalibCsvPathChanged(String),
    LoadCalibCsv,
    UseTauToggled(bool),
    SpeedOfSoundChanged(f32),
    BeamWidthChanged(f32),
    GenScanlinesChanged(f32),
    FocalDistanceChanged(f32),
    ContrastChanged(f32),
    YUnitsSelected(YUnits),
    SectorScanToggled(bool),
    ChannelToggled(usize),
    NotchToggled(bool),
    NotchLowChanged(f32),
    NotchHighChanged(f32),
    SaveCsv,
    StatsToggled,
    ScopeSectionToggled,
    NotchSectionToggled,
    Hardware(HwEvent),
    Scope(ScopeEvent),
}

/// Events flowing from the hardware task to the GUI.
#[derive(Debug, Clone)]
enum HwEvent {
    Connected(mpsc::Sender<HwCommand>),
    Disconnected(String),
    Status(String),
    /// Whether the pulser is free-running, read once at connect so the
    /// pulsing toggle starts out matching the hardware.
    PulsingState(bool),
    HvPlusVoltage(f32),
    HvMinusVoltage(f32),
    /// Usable ramp times in µs (min = fastest ramp), reported once at
    /// connect.
    RampRateInfo {
        min_us: f32,
        max_us: f32,
    },
    /// Supply limits and the target currently set in hardware, reported
    /// once at connect.
    HvPlusInfo {
        min: f32,
        max: f32,
        target: f32,
    },
    HvMinusInfo {
        min: f32,
        max: f32,
        target: f32,
    },
}

/// One parsed UDP data packet, flowing from the ingest thread to the
/// scope-processing thread.
struct DataPacket {
    /// The packet begins a new pulsed-array frame (header bit 6).
    start_of_frame: bool,
    /// The packet begins a new scanline (header bit 7).
    start_of_line: bool,
    /// Channel-major samples: all of channel 0, then all of channel 1, …
    /// so each channel is a contiguous slice of len `samples.len() / 8`.
    samples: Vec<f32>,
}

/// Counters the ingest thread increments; the scope thread snapshots
/// them once a second for the GUI's stats area.
#[derive(Default)]
struct IngestStats {
    /// UDP packets received.
    packets: AtomicU64,
    /// recv errors, i.e. io_uring buffer-ring exhaustion (data waits in
    /// the socket buffer; only a loss if the socket buffer then fills).
    recv_stalls: AtomicU64,
    /// Packets dropped because the ingest→scope channel was full.
    channel_drops: AtomicU64,
}

/// Cumulative pipeline health counters shown in the GUI stats area.
#[derive(Debug, Clone, Copy, Default)]
struct PipelineStatsSnapshot {
    packets_per_sec: u64,
    /// Kernel-side drops on the data socket (socket buffer full).
    socket_drops: u64,
    recv_stalls: u64,
    ingest_drops: u64,
    /// Scope→GUI events deferred because the channel was full.
    gui_busy: u64,
    /// Samples discarded because a scanline hit MAX_SCANLINE_SAMPLES.
    line_overflow: u64,
    /// Frames force-split at MAX_SCANLINES — a start-of-frame marker
    /// went missing.
    frame_overflow: u64,
}

/// The scope settings the processing thread needs, mirrored from the GUI.
#[derive(Debug, Clone, Copy)]
struct ScopeSettings {
    trigger_mode: TriggerMode,
    trigger_channel: usize,
    trigger_level: f32, // ADC codes
    holdoff_samples: usize,
    trigger_position_pct: f32,
    x_scale: usize,
    array_source: ArraySource,
    channel_enabled: [bool; 8],
    beamform: Option<BeamformSettings>,
}

impl Default for ScopeSettings {
    fn default() -> Self {
        // must match App::default so the thread behaves before the GUI's
        // first sync
        Self {
            trigger_mode: TriggerMode::Line,
            trigger_channel: 0,
            trigger_level: 0.0,
            holdoff_samples: 0,
            trigger_position_pct: 0.0,
            x_scale: 4096,
            array_source: ArraySource::Average,
            channel_enabled: [true; 8],
            beamform: None,
        }
    }
}

/// Commands flowing from the GUI to the scope-processing thread.
#[derive(Debug)]
enum ScopeCommand {
    Settings(ScopeSettings),
    /// Run (armed, continuous) or stop.
    Run(bool),
    /// Arm for a single capture.
    Single,
}

/// Display-rate events flowing from the scope-processing thread to the
/// GUI: at most a few tens per second, each carrying a finished result.
#[derive(Debug, Clone)]
enum ScopeEvent {
    /// Sent once at startup so the GUI can command the thread.
    Ready(std_mpsc::Sender<ScopeCommand>),
    /// A completed capture. `stopped` reports that the acquisition ended
    /// (single-shot) so the GUI can update its run/stop state.
    Capture {
        traces: [Vec<f32>; 8],
        trigger_index: usize,
        stopped: bool,
    },
    /// A pulsed-array frame: completed if `complete`, otherwise a
    /// snapshot of the one being assembled (which also means frames have
    /// stalled, so `fps` is None).
    Scanlines {
        /// Display traces, one per scanline, derived per the array source.
        lines: Vec<Vec<f32>>,
        /// Full per-channel data, carried by complete frames (for CSV
        /// export).
        channels: Option<Vec<[Vec<f32>; 8]>>,
        complete: bool,
        /// Live frame rate, from the spacing of start-of-frame markers.
        fps: Option<f32>,
    },
    /// Pipeline health counters, published once a second.
    Stats(PipelineStatsSnapshot),
}

/// Pulser settings applied together via Pulser::setup.
#[derive(Debug, Clone, Copy)]
struct PulserConfig {
    duration_ns: f32,
    ramp_delay_us: f32,
    recv_time_us: f32,
}

/// Commands flowing from the GUI to the hardware task.
#[derive(Debug, Clone)]
enum HwCommand {
    SetRampRate(f32), // µs
    SetHvPlus(f32),   // V
    SetHvMinus(f32),  // V (magnitude)
    SetupPulser(PulserConfig),
    InitHw,
    /// Arm and start; the pulser auto-restarts itself after the idle
    /// time until stopped.
    StartPulses(PulserConfig),
    StopPulses,
    SetupArray {
        idle_us: f32,
        num_scanlines: u32,
        /// Restart the pulser after applying: the FPGA's line counter
        /// only fires start-of-frame on equality, so lowering the count
        /// below the current counter would stop SOF markers entirely.
        restart: bool,
    },
    /// Per-channel delays (clock cycles), one row per scanline.
    LoadDelays(Vec<[u16; 8]>),
}

impl App {
    fn update(&mut self, message: Message) {
        match message {
            Message::RampRateChanged(v) => {
                self.ramp_rate_us = v;
                self.update(Message::ApplyRampRate);
            }
            Message::ApplyRampRate => {
                self.send(HwCommand::SetRampRate(self.ramp_rate_us));
            }
            Message::HvPlusSetpointChanged(v) => {
                self.hv_plus_setpoint = v;
                self.update(Message::ApplyHvPlus);
            }
            Message::ApplyHvPlus => {
                self.send(HwCommand::SetHvPlus(self.hv_plus_setpoint));
            }
            Message::HvMinusSetpointChanged(v) => {
                self.hv_minus_setpoint = v;
                self.update(Message::ApplyHvMinus);
            }
            Message::ApplyHvMinus => {
                self.send(HwCommand::SetHvMinus(self.hv_minus_setpoint));
            }
            Message::PulseDurationChanged(v) => {
                self.pulse_duration_ns = v;
                self.update(Message::ApplyPulseDuration);
            }
            Message::ApplyPulseDuration => {
                self.send(HwCommand::SetupPulser(self.pulser_config()));
            }
            Message::RampDelayChanged(v) => {
                self.ramp_delay_us = v;
                self.update(Message::ApplyRampDelay);
            }
            Message::ApplyRampDelay => {
                self.send(HwCommand::SetupPulser(self.pulser_config()));
            }
            Message::RecvTimeChanged(v) => {
                self.recv_time_us = v;
                self.update(Message::ApplyRecvTime);
            }
            Message::ApplyRecvTime => {
                self.send(HwCommand::SetupPulser(self.pulser_config()));
            }
            Message::InitHw => {
                self.send(HwCommand::InitHw);
            }
            Message::PulsingToggled => {
                self.pulsing = !self.pulsing;
                if self.pulsing {
                    self.send(HwCommand::StartPulses(self.pulser_config()));
                } else {
                    self.send(HwCommand::StopPulses);
                }
            }
            Message::RunToggled => {
                self.acquisition = match self.acquisition {
                    Acquisition::Stopped => Acquisition::Armed { continuous: true },
                    _ => Acquisition::Stopped,
                };
                let running = !matches!(self.acquisition, Acquisition::Stopped);
                self.send_scope(ScopeCommand::Run(running));
            }
            Message::SingleShot => {
                self.acquisition = Acquisition::Armed { continuous: false };
                self.send_scope(ScopeCommand::Single);
            }
            Message::TriggerModeSelected(mode) => {
                self.trigger_mode = mode;
                self.sync_scope();
            }
            Message::TriggerChannelSelected(ch) => {
                self.trigger_channel = ch;
                self.sync_scope();
                self.plot_cache.clear();
                self.bmode_cache.clear();
            }
            Message::TriggerLevelChanged(level) => {
                self.trigger_level = level;
                self.trigger_level_text = format!("{level:.0}");
                self.sync_scope();
                self.plot_cache.clear();
                self.bmode_cache.clear();
            }
            Message::TriggerLevelInputChanged(input) => {
                if let Ok(level) = input.trim().parse::<f32>() {
                    self.trigger_level = level.clamp(-2048.0, 2047.0);
                    self.sync_scope();
                    self.plot_cache.clear();
                    self.bmode_cache.clear();
                }
                self.trigger_level_text = input;
            }
            Message::TriggerLevelInputSubmitted => {
                self.trigger_level_text = format!("{:.0}", self.trigger_level);
            }
            Message::HoldoffChanged(samples) => {
                self.holdoff_samples = samples as usize;
                self.sync_scope();
            }
            Message::TriggerPositionChanged(pct) => {
                self.trigger_position_pct = pct;
                self.sync_scope();
            }
            Message::XScaleChanged(exp) => {
                self.x_scale = 1 << exp as u32;
                for trace in &mut self.traces {
                    trace.truncate(self.x_scale);
                }
                self.sync_scope();
                self.apply_notch();
                self.plot_cache.clear();
                self.bmode_cache.clear();
            }
            Message::YScaleChanged(scale) => {
                self.y_scale = scale;
                self.y_auto = false;
                self.plot_cache.clear();
                self.bmode_cache.clear();
            }
            Message::YOffsetChanged(offset) => {
                self.y_offset = offset;
                self.y_auto = false;
                self.plot_cache.clear();
                self.bmode_cache.clear();
            }
            Message::YAutoPressed => {
                self.y_auto = true;
                self.plot_cache.clear();
                self.bmode_cache.clear();
            }
            Message::ViewTabSelected(tab) => {
                self.view_tab = tab;
            }
            Message::BModeModeSelected(mode) => {
                self.bmode_mode = mode;
                // both modes share the cache
                self.bmode_cache.clear();
            }
            Message::ArraySourceSelected(source) => {
                // takes effect as new scanlines are ingested
                self.array_source = source;
                self.sync_scope();
            }
            Message::IdleTimeChanged(v) => {
                self.idle_time_us = v;
                self.update(Message::ApplyArrayConfig);
            }
            Message::ApplyArrayConfig => {
                self.send(HwCommand::SetupArray {
                    idle_us: self.idle_time_us,
                    num_scanlines: self.num_scanlines,
                    restart: self.pulsing,
                });
            }
            Message::DelayCsvPathChanged(path) => self.delay_csv_path = path,
            Message::LoadDelayCsv => match load_delay_csv(&self.delay_csv_path) {
                Ok(table) => {
                    let n = table.len();
                    self.send(HwCommand::LoadDelays(table));
                    // the table defines the frame: one scanline per row
                    self.num_scanlines = n as u32;
                    self.send(HwCommand::SetupArray {
                        idle_us: self.idle_time_us,
                        num_scanlines: self.num_scanlines,
                        restart: self.pulsing,
                    });
                    self.status = format!("loaded delay table: {n} scanlines");
                }
                Err(e) => self.status = format!("delay csv: {e}"),
            },
            Message::DelaySourceSelected(source) => {
                self.delay_source = source;
                self.regenerate_delays();
            }
            Message::CalibCsvPathChanged(path) => {
                self.calib_csv_path = path;
                // typed paths are reloaded as they change; a path that
                // doesn't parse yet just leaves the previous calibration
                if let Ok(calib) = load_calibration_csv(&self.calib_csv_path) {
                    self.set_calibration(calib);
                }
            }
            Message::LoadCalibCsv => match load_calibration_csv(&self.calib_csv_path) {
                Ok(calib) => self.set_calibration(calib),
                Err(e) => self.status = format!("calibration csv: {e}"),
            },
            Message::UseTauToggled(on) => {
                self.use_tau = on;
                self.regenerate_delays();
            }
            Message::SpeedOfSoundChanged(c) => {
                self.speed_of_sound = c;
                self.regenerate_delays();
            }
            Message::BeamWidthChanged(v) => {
                self.beam_width_deg = v;
                self.regenerate_delays();
            }
            Message::GenScanlinesChanged(v) => {
                self.gen_scanlines = v as u32;
                self.regenerate_delays();
            }
            Message::FocalDistanceChanged(v) => {
                self.focal_distance_mm = v;
                self.regenerate_delays();
            }
            Message::ContrastChanged(contrast) => {
                self.contrast = contrast;
                self.bmode_cache.clear();
            }
            Message::YUnitsSelected(units) => {
                self.y_units = units;
                self.bmode_cache.clear();
            }
            Message::SectorScanToggled(on) => {
                self.sector_scan = on;
                self.bmode_cache.clear();
            }
            Message::ChannelToggled(ch) => {
                self.channel_enabled[ch] = !self.channel_enabled[ch];
                self.sync_scope();
                self.plot_cache.clear();
                self.bmode_cache.clear();
            }
            Message::NotchToggled(enabled) => {
                self.notch_enabled = enabled;
                self.apply_notch();
                self.plot_cache.clear();
                self.bmode_cache.clear();
            }
            Message::NotchLowChanged(mhz) => {
                self.notch_low_mhz = mhz;
                self.apply_notch();
                self.plot_cache.clear();
                self.bmode_cache.clear();
            }
            Message::NotchHighChanged(mhz) => {
                self.notch_high_mhz = mhz;
                self.apply_notch();
                self.plot_cache.clear();
                self.bmode_cache.clear();
            }
            Message::SaveCsv => {
                self.status = match self.save_csv() {
                    Ok(path) => format!("saved {path}"),
                    Err(e) => format!("csv save failed: {e}"),
                };
            }
            Message::StatsToggled => self.show_stats = !self.show_stats,
            Message::ScopeSectionToggled => self.show_scope = !self.show_scope,
            Message::NotchSectionToggled => self.show_notch = !self.show_notch,
            Message::Hardware(event) => match event {
                HwEvent::Connected(commands) => {
                    self.hw = Some(commands);
                    self.status = String::from("connected");
                }
                HwEvent::PulsingState(pulsing) => self.pulsing = pulsing,
                HwEvent::Disconnected(reason) => {
                    self.hw = None;
                    self.hw_backlog.clear();
                    self.hv_plus_reading = None;
                    self.hv_minus_reading = None;
                    self.hv_plus_range = None;
                    self.hv_minus_range = None;
                    self.ramp_rate_range = None;
                    self.pulsing = false;
                    self.status = format!("disconnected: {reason}");
                }
                HwEvent::Status(status) => {
                    self.status = status;
                    self.flush_backlog();
                }
                HwEvent::HvPlusVoltage(v) => self.hv_plus_reading = Some(v),
                HwEvent::HvMinusVoltage(v) => self.hv_minus_reading = Some(v),
                HwEvent::RampRateInfo { min_us, max_us } => {
                    self.ramp_rate_us = self.ramp_rate_us.clamp(min_us, max_us);
                    self.ramp_rate_range = Some(min_us..=max_us);
                }
                HwEvent::HvPlusInfo { min, max, target } => {
                    self.hv_plus_range = Some(min..=max);
                    self.hv_plus_setpoint = target;
                }
                HwEvent::HvMinusInfo { min, max, target } => {
                    self.hv_minus_range = Some(min..=max);
                    self.hv_minus_setpoint = target;
                }
            },
            Message::Scope(event) => match event {
                ScopeEvent::Ready(tx) => {
                    self.scope = Some(tx);
                    self.sync_scope();
                    let running = !matches!(self.acquisition, Acquisition::Stopped);
                    self.send_scope(ScopeCommand::Run(running));
                }
                ScopeEvent::Capture {
                    traces,
                    trigger_index,
                    stopped,
                } => {
                    self.traces = traces;
                    self.display_trigger_index = trigger_index;
                    if stopped {
                        self.acquisition = Acquisition::Stopped;
                    }
                    self.apply_notch();
                    self.plot_cache.clear();
                    self.bmode_cache.clear();
                }
                ScopeEvent::Scanlines {
                    lines,
                    channels,
                    complete,
                    fps,
                } => {
                    if complete {
                        self.scanlines = lines;
                        self.scanline_channels = channels.unwrap_or_default();
                        self.scanline_capture.clear();
                    } else {
                        self.scanline_capture = lines;
                    }
                    self.array_fps = fps;
                    if self.bmode_mode == BModeMode::PulsedArray {
                        self.bmode_cache.clear();
                    }
                }
                ScopeEvent::Stats(snapshot) => self.stats = snapshot,
            },
        }
    }

    /// Recomputes `filtered` from `traces`: FFT, zero the bins inside the
    /// notch band, inverse FFT. Applied only to the displayed capture, not
    /// the incoming stream, so triggering is unaffected.
    fn apply_notch(&mut self) {
        if !self.notch_enabled {
            return;
        }

        let lo_hz = self.notch_low_mhz.min(self.notch_high_mhz) * 1e6;
        let hi_hz = self.notch_low_mhz.max(self.notch_high_mhz) * 1e6;

        let mut planner = FftPlanner::<f32>::new();
        for (filtered, trace) in self.filtered.iter_mut().zip(&self.traces) {
            filtered.clear();
            let n = trace.len();
            if n < 2 {
                filtered.extend_from_slice(trace);
                continue;
            }

            let mut buf: Vec<Complex<f32>> = trace.iter().map(|&y| Complex::new(y, 0.0)).collect();
            planner.plan_fft_forward(n).process(&mut buf);

            let bin_hz = ADC_SAMPLE_RATE_HZ / n as f32;
            for k in 0..=n / 2 {
                let f = k as f32 * bin_hz;
                if f >= lo_hz && f <= hi_hz {
                    buf[k] = Complex::ZERO;
                    // mirror bin (the input is real)
                    if k != 0 && k != n - k {
                        buf[n - k] = Complex::ZERO;
                    }
                }
            }

            planner.plan_fft_inverse(n).process(&mut buf);
            filtered.extend(buf.iter().map(|c| c.re / n as f32));
        }
    }

    /// The pulsed-array frame currently on screen: the last completed
    /// one, or the one in progress before the first frame completes.
    fn shown_scanlines(&self) -> &[Vec<f32>] {
        if !self.scanlines.is_empty() {
            &self.scanlines
        } else {
            &self.scanline_capture
        }
    }

    /// Geometry of the frame on screen: the generated table's, or — for
    /// a csv table, whose geometry is unknown — the width setting with
    /// the calibrated aperture (a point if no calibration is loaded).
    fn sector_geometry(&self) -> SectorGeometry {
        match self.beamform {
            Some(bf) => SectorGeometry {
                width_deg: bf.beam_width_deg,
                x_min: bf.x_min,
                x_max: bf.x_max,
                num_scanlines: bf.num_scanlines,
            },
            None => {
                let (x_min, x_max) = self.calibration.map_or((0.0, 0.0), |c| {
                    (
                        c.x_el.iter().copied().fold(f32::MAX, f32::min),
                        c.x_el.iter().copied().fold(f32::MIN, f32::max),
                    )
                });
                SectorGeometry {
                    width_deg: self.beam_width_deg,
                    x_min,
                    x_max,
                    num_scanlines: self.num_scanlines,
                }
            }
        }
    }

    /// The traces currently on screen and their trigger index.
    fn shown(&self) -> (&[Vec<f32>; 8], usize) {
        let traces = if self.notch_enabled {
            &self.filtered
        } else {
            &self.traces
        };
        (traces, self.display_trigger_index)
    }

    /// Writes the data currently on screen to a timestamped CSV in the
    /// working directory: in the pulsed-array view, all channels of all
    /// scanlines of the last completed frame; otherwise the shown traces
    /// (filtered, if the notch is enabled).
    fn save_csv(&self) -> Result<String, io::Error> {
        if self.view_tab == ViewTab::BMode && self.bmode_mode == BModeMode::PulsedArray {
            return self.save_array_csv();
        }

        let (shown, trigger_index) = self.shown();
        let rows = shown.iter().map(Vec::len).max().unwrap_or(0);
        if rows == 0 {
            return Err(io::Error::other("no data on screen"));
        }

        let mut csv = String::from("time_us");
        for name in CHANNEL_NAMES {
            let _ = write!(csv, ",ch{name}");
        }
        csv.push('\n');
        for i in 0..rows {
            // t = 0 at the trigger point
            let t = (i as f32 - trigger_index as f32) * SAMPLE_PERIOD_S * 1e6;
            let _ = write!(csv, "{t:.4}");
            for trace in shown {
                csv.push(',');
                if let Some(v) = trace.get(i) {
                    let _ = write!(csv, "{v}");
                }
            }
            csv.push('\n');
        }

        let name = format!("scope_{}.csv", utc_timestamp());
        std::fs::write(&name, csv)?;
        Ok(name)
    }

    /// Writes every channel of every scanline of the last completed
    /// pulsed-array frame, one column per (scanline, channel), with time
    /// from the start of each line.
    fn save_array_csv(&self) -> Result<String, io::Error> {
        let lines = &self.scanline_channels;
        let rows = lines
            .iter()
            .flat_map(|line| line.iter().map(Vec::len))
            .max()
            .unwrap_or(0);
        if rows == 0 {
            return Err(io::Error::other("no completed pulsed-array frame yet"));
        }

        let mut csv = String::from("time_us");
        for i in 0..lines.len() {
            for name in CHANNEL_NAMES {
                let _ = write!(csv, ",sl{i}_ch{name}");
            }
        }
        csv.push('\n');
        for r in 0..rows {
            let t = r as f32 * SAMPLE_PERIOD_S * 1e6;
            let _ = write!(csv, "{t:.4}");
            for line in lines {
                for channel in line {
                    csv.push(',');
                    if let Some(v) = channel.get(r) {
                        let _ = write!(csv, "{v}");
                    }
                }
            }
            csv.push('\n');
        }

        let name = format!("array_{}.csv", utc_timestamp());
        std::fs::write(&name, csv)?;
        Ok(name)
    }

    fn pulser_config(&self) -> PulserConfig {
        PulserConfig {
            duration_ns: self.pulse_duration_ns,
            ramp_delay_us: self.ramp_delay_us,
            recv_time_us: self.recv_time_us,
        }
    }

    fn send(&mut self, command: HwCommand) {
        match &mut self.hw {
            Some(tx) => {
                if let Err(e) = tx.try_send(command) {
                    if e.is_full() {
                        let command = e.into_inner();
                        self.hw_backlog
                            .retain(|c| std::mem::discriminant(c) != std::mem::discriminant(&command));
                        self.hw_backlog.push(command);
                    } else {
                        self.status = String::from("hardware task gone, command dropped");
                    }
                }
            }
            None => self.status = String::from("not connected, command ignored"),
        }
    }

    /// Resends backlogged commands, oldest first, as far as the channel
    /// allows.
    fn flush_backlog(&mut self) {
        while !self.hw_backlog.is_empty() {
            let Some(tx) = &mut self.hw else { break };
            let command = self.hw_backlog.remove(0);
            if let Err(e) = tx.try_send(command) {
                if e.is_full() {
                    self.hw_backlog.insert(0, e.into_inner());
                }
                break;
            }
        }
    }

    fn set_calibration(&mut self, calib: Calibration) {
        let changed = self.calibration != Some(calib);
        self.calibration = Some(calib);
        let span = calib.x_el.iter().copied().fold(f32::MIN, f32::max)
            - calib.x_el.iter().copied().fold(f32::MAX, f32::min);
        self.status = format!(
            "loaded calibration: aperture {:.1} mm, t0 {:.2} µs, {} inverted rx channel(s)",
            span * 1e3,
            calib.t0 * 1e6,
            calib.sign.iter().filter(|&&s| s < 0.0).count()
        );
        if changed {
            self.regenerate_delays();
        }
    }

    /// Regenerates and loads the transmit delay table from the current
    /// beamforming settings — a no-op unless the delay source is
    /// beamforming, a calibration is loaded and the hardware is
    /// connected.
    fn regenerate_delays(&mut self) {
        if self.delay_source != DelaySource::Beamforming
            || self.calibration.is_none()
            || self.hw.is_none()
        {
            return;
        }
        match self.generate_delays() {
            Ok((table, beamform)) => {
                let n = table.len();
                self.send(HwCommand::LoadDelays(table));
                self.num_scanlines = n as u32;
                self.send(HwCommand::SetupArray {
                    idle_us: self.idle_time_us,
                    num_scanlines: self.num_scanlines,
                    restart: self.pulsing,
                });
                self.beamform = Some(beamform);
                self.sync_scope();
                self.status = format!(
                    "generated delay table: {n} scanlines over {:.0}°",
                    beamform.beam_width_deg
                );
            }
            Err(e) => self.status = format!("generate delays: {e}"),
        }
    }

    /// Builds a focused/steered transmit delay table from the loaded
    /// calibration and the beam width / scanline count / focal distance
    /// settings, per delays.py, along with the matching receive geometry.
    fn generate_delays(&self) -> Result<(Vec<[u16; 8]>, BeamformSettings), String> {
        let calib = self.calibration.ok_or("load a calibration csv first")?;
        let width_deg = self.beam_width_deg;
        let n = self.gen_scanlines.clamp(1, pulser::MAX_SCANLINES as u32);
        let focus_m = self.focal_distance_mm * 1e-3;
        let c = self.speed_of_sound;
        let tau = if self.use_tau { calib.tau } else { [0.0; 8] };

        // raw delays in clock cycles (f64, so the rounding matches numpy),
        // pulser order, one row per scanline. An element with extra
        // latency τ fires τ earlier so its wave leaves on time.
        let x_min = calib.x_el.iter().copied().fold(f32::MAX, f32::min);
        let x_max = calib.x_el.iter().copied().fold(f32::MIN, f32::max);
        let mut raw = vec![[0.0f64; 8]; n as usize];
        for (i, row) in raw.iter_mut().enumerate() {
            let theta = scanline_angle(width_deg, n, i) as f64;
            let origin = scanline_origin(x_min, x_max, n, i) as f64;
            for (ch, d) in row.iter_mut().enumerate() {
                let seconds = transmit_delay(
                    calib.x_el[ch] as f64 - origin,
                    calib.z_el[ch] as f64,
                    theta,
                    focus_m as f64,
                    c as f64,
                ) - tau[ch] as f64;
                *d = (seconds * PULSER_CLK_HZ as f64).round();
            }
        }
        // shift so the earliest-firing channel of the frame fires at 0
        let min = raw.iter().flatten().copied().fold(f64::MAX, f64::min);
        let mut table = Vec::with_capacity(raw.len());
        for row in &raw {
            let mut out = [0u16; 8];
            for (ch, d) in row.iter().enumerate() {
                let cycles = d - min;
                if cycles >= DELAY_NO_FIRE as f64 {
                    return Err(format!(
                        "delay {:.1} µs exceeds the table range",
                        cycles / PULSER_CLK_HZ as f64 * 1e6
                    ));
                }
                out[ch] = cycles as u16;
            }
            table.push(out);
        }
        let min = (min / PULSER_CLK_HZ as f64) as f32;

        // receive geometry in ADC order
        let mut x_el = [0.0f32; 8];
        let mut z_el = [0.0f32; 8];
        let mut tau_adc = [0.0f32; 8];
        let mut sign = [1.0f32; 8];
        for adc in 0..8 {
            x_el[adc] = calib.x_el[ADC_TO_PULSER[adc]];
            z_el[adc] = calib.z_el[ADC_TO_PULSER[adc]];
            tau_adc[adc] = tau[ADC_TO_PULSER[adc]];
            sign[adc] = calib.sign[ADC_TO_PULSER[adc]];
        }
        // a channel with table delay 0 fires at t0 after the line marker;
        // the shift moved the frame's earliest channel to 0, so the
        // wavefront passes the beam origin at t0 - min (for a focused
        // beam, reaches the focus at t0 - min + F/c)
        let beamform = BeamformSettings {
            x_el,
            z_el,
            tau: tau_adc,
            sign,
            c,
            x_min,
            x_max,
            beam_width_deg: width_deg,
            num_scanlines: n,
            t0_s: calib.t0 - min,
        };
        Ok((table, beamform))
    }

    fn scope_settings(&self) -> ScopeSettings {
        ScopeSettings {
            trigger_mode: self.trigger_mode,
            trigger_channel: self.trigger_channel,
            trigger_level: self.trigger_level,
            holdoff_samples: self.holdoff_samples,
            trigger_position_pct: self.trigger_position_pct,
            x_scale: self.x_scale,
            array_source: self.array_source,
            channel_enabled: self.channel_enabled,
            beamform: self.beamform,
        }
    }

    fn send_scope(&mut self, command: ScopeCommand) {
        if let Some(tx) = &self.scope {
            let _ = tx.send(command);
        }
    }

    /// Forwards the current scope settings to the processing thread.
    fn sync_scope(&mut self) {
        let settings = self.scope_settings();
        self.send_scope(ScopeCommand::Settings(settings));
    }

    fn subscription(&self) -> Subscription<Message> {
        Subscription::batch([
            Subscription::run(hardware_ctrl_worker).map(Message::Hardware),
            Subscription::run(hardware_data_worker).map(Message::Scope),
        ])
    }

    fn view(&self) -> Element<'_, Message> {
        let connected = self.hw.is_some();

        let status_section = column![
            text("Status").size(16),
            text(if connected {
                "● connected"
            } else {
                "○ disconnected"
            })
            .size(14),
            text(&self.status).size(13),
            button("init hw").on_press_maybe(connected.then_some(Message::InitHw)),
        ]
        .spacing(5);

        // greyed out until the hardware task reports the usable range
        let ramp_control: Element<'_, Message> = match &self.ramp_rate_range {
            Some(range) => column![
                text(format!("ramp rate: {:.1} µs", self.ramp_rate_us)).size(14),
                slider(range.clone(), self.ramp_rate_us, Message::RampRateChanged)
                    .step(0.5),
            ]
            .spacing(5)
            .into(),
            None => Element::from(text("ramp rate: waiting for hardware...").size(13)),
        };
        let vga_section = column![
            text("VGA").size(16),
            ramp_control,
            text(format!("ramp delay: {:.0} µs", self.ramp_delay_us)).size(14),
            slider(
                RAMP_DELAY_RANGE,
                self.ramp_delay_us,
                Message::RampDelayChanged
            )
            .step(1.0),
        ]
        .spacing(5);

        // setpoint controls are greyed out until the hardware task reports
        // the supply's range and current target
        let hv_setpoint = |range: &Option<RangeInclusive<f32>>,
                           setpoint: f32,
                           on_change: fn(f32) -> Message| {
            match range {
                Some(range) => column![
                    text(format!("setpoint: {setpoint:.1} V",)).size(14),
                    slider(range.clone(), setpoint, on_change)
                        .step(1.0),
                ]
                .spacing(5)
                .into(),
                None => Element::from(text("setpoint: waiting for hardware...").size(13)),
            }
        };

        let delay_controls: Element<'_, Message> = match self.delay_source {
            DelaySource::Csv => column![
                text("delay table csv").size(14),
                text_input("path/to/delays.csv", &self.delay_csv_path)
                    .on_input(Message::DelayCsvPathChanged)
                    .on_submit(Message::LoadDelayCsv)
                    .size(13),
                button("load delays").on_press_maybe(connected.then_some(Message::LoadDelayCsv)),
            ]
            .spacing(5)
            .into(),
            DelaySource::Beamforming => column![
                text(format!(
                    "calibration csv ({})",
                    if self.calibration.is_some() {
                        "loaded"
                    } else {
                        "not found"
                    }
                ))
                .size(14),
                text_input("path/to/calibration.csv", &self.calib_csv_path)
                    .on_input(Message::CalibCsvPathChanged)
                    .on_submit(Message::LoadCalibCsv)
                    .size(13),
                toggler(self.use_tau)
                    .label("apply channel τ offsets")
                    .on_toggle(Message::UseTauToggled)
                    .size(16),
                text(format!(
                    "beam width: {:.0}° (±{:.0}°)",
                    self.beam_width_deg,
                    self.beam_width_deg / 2.0
                ))
                .size(14),
                slider(BEAM_WIDTH_RANGE, self.beam_width_deg, Message::BeamWidthChanged)
                    .step(1.0),
                text(format!("scanlines: {}", self.gen_scanlines)).size(14),
                slider(
                    NUM_SCANLINES_RANGE,
                    self.gen_scanlines as f32,
                    Message::GenScanlinesChanged
                )
                .step(1.0),
                text(format!("focal distance: {:.0} mm", self.focal_distance_mm)).size(14),
                slider(
                    FOCAL_DISTANCE_RANGE,
                    self.focal_distance_mm,
                    Message::FocalDistanceChanged
                )
                .step(1.0),
            ]
            .spacing(5)
            .into(),
        };

        let pulser_section = column![
            text("Pulser").size(16),
            text(format!(
                "HV+ measured: {}",
                fmt_voltage(self.hv_plus_reading)
            ))
            .size(14),
            hv_setpoint(
                &self.hv_plus_range,
                self.hv_plus_setpoint,
                Message::HvPlusSetpointChanged,
            ),
            text(format!(
                "HV− measured: {}",
                fmt_voltage(self.hv_minus_reading)
            ))
            .size(14),
            hv_setpoint(
                &self.hv_minus_range,
                self.hv_minus_setpoint,
                Message::HvMinusSetpointChanged,
            ),
            text(format!(
                "pulse duration: {:.0} ns ({:.2} MHz)",
                self.pulse_duration_ns,
                1000.0 / self.pulse_duration_ns
            ))
            .size(14),
            slider(
                PULSE_DURATION_RANGE,
                self.pulse_duration_ns,
                Message::PulseDurationChanged
            )
            .step(25.0),
            text("delay source").size(14),
            row![
                radio(
                    "csv",
                    DelaySource::Csv,
                    Some(self.delay_source),
                    Message::DelaySourceSelected,
                )
                .size(16),
                radio(
                    "beamforming",
                    DelaySource::Beamforming,
                    Some(self.delay_source),
                    Message::DelaySourceSelected,
                )
                .size(16),
            ]
            .spacing(10),
            delay_controls,
            button(if self.pulsing {
                "stop pulsing"
            } else {
                "start pulsing"
            })
            .on_press_maybe(connected.then_some(Message::PulsingToggled)),
        ]
        .spacing(5);

        let scan_section = column![
            text("Scan settings").size(16),
            text(format!("recv time: {:.0} µs", self.recv_time_us)).size(14),
            slider(
                RECV_TIME_RANGE,
                self.recv_time_us,
                Message::RecvTimeChanged
            )
            .step(10.0),
            text(format!("idle time: {:.0} µs", self.idle_time_us)).size(14),
            slider(IDLE_TIME_RANGE, self.idle_time_us, Message::IdleTimeChanged)
                .step(10.0),
        ]
        .spacing(5);

        let running = !matches!(self.acquisition, Acquisition::Stopped);
        let scope_contents = column![
            row![
                button(if running { "stop" } else { "run" }).on_press(Message::RunToggled),
                button("single").on_press(Message::SingleShot),
                button("save csv").on_press(Message::SaveCsv),
            ]
            .spacing(10),
            text(match self.acquisition {
                Acquisition::Stopped => "stopped",
                Acquisition::Armed { .. } => "armed, waiting for trigger",
                Acquisition::Capturing { .. } => "capturing...",
            })
            .size(13),
            text("trigger mode").size(14),
            row![
                radio(
                    "auto",
                    TriggerMode::Auto,
                    Some(self.trigger_mode),
                    Message::TriggerModeSelected,
                )
                .size(16),
                radio(
                    "normal",
                    TriggerMode::Normal,
                    Some(self.trigger_mode),
                    Message::TriggerModeSelected,
                )
                .size(16),
                radio(
                    "line",
                    TriggerMode::Line,
                    Some(self.trigger_mode),
                    Message::TriggerModeSelected,
                )
                .size(16),
            ]
            .spacing(10),
            text("trigger channel").size(14),
            // row(
            combo_box(
                &self.trigger_channel_cb,
                "trigger channel",
                Some(&ChannelChoice(self.trigger_channel)),
                |ch| { Message::TriggerChannelSelected(ch.0) }
            ),
            //     (0..8).map(|ch| {
            //     radio(
            //         CHANNEL_NAMES[ch],
            //         ch,
            //         Some(self.trigger_channel),
            //         Message::TriggerChannelSelected,
            //     )
            //     .size(16)
            //     .into()
            // })
            // )
            // .spacing(10),
            row![
                text("trigger level").size(14),
                text_input("level", &self.trigger_level_text)
                    .on_input(Message::TriggerLevelInputChanged)
                    .on_submit(Message::TriggerLevelInputSubmitted)
                    .size(13)
                    .width(70),
            ]
            .spacing(10)
            .align_y(Center),
            slider(
                -2048.0..=2047.0,
                self.trigger_level,
                Message::TriggerLevelChanged
            )
            .step(16.0),
            text(format!(
                "trigger position: {:.0}%",
                self.trigger_position_pct
            ))
            .size(14),
            slider(
                TRIGGER_POSITION_RANGE,
                self.trigger_position_pct,
                Message::TriggerPositionChanged
            )
            .step(5.0),
            text(format!(
                "holdoff: {} samples ({})",
                self.holdoff_samples,
                fmt_samples_as_time(self.holdoff_samples)
            ))
            .size(14),
            slider(
                HOLDOFF_RANGE,
                self.holdoff_samples as f32,
                Message::HoldoffChanged
            )
            .step(1024.0),
            text("X scale").size(14),
            text(format!(
                "{} samples ({})",
                self.x_scale,
                fmt_samples_as_time(self.x_scale)
            ))
            .size(14),
            slider(
                X_SCALE_EXP_RANGE,
                self.x_scale.max(1).ilog2() as f32,
                Message::XScaleChanged
            )
            .step(1.0),
            text("Y axis").size(14),
            text(if self.y_auto {
                String::from("auto")
            } else {
                String::from("manual")
            })
            .size(13),
            text(format!("scale: ±{:.0}", self.y_scale)).size(14),
            slider(Y_SCALE_RANGE, self.y_scale, Message::YScaleChanged).step(16.0),
            text(format!("offset: {:.0}", self.y_offset)).size(14),
            slider(Y_OFFSET_RANGE, self.y_offset, Message::YOffsetChanged).step(16.0),
            button("auto").on_press_maybe((!self.y_auto).then_some(Message::YAutoPressed)),
        ]
        .spacing(5);

        let mut scope_section = column![
            button(
                text(if self.show_scope {
                    "Scope ▾"
                } else {
                    "Scope ▸"
                })
                .size(16)
            )
            .style(button::text)
            .padding(0)
            .on_press(Message::ScopeSectionToggled),
        ]
        .spacing(5);
        if self.show_scope {
            scope_section = scope_section.push(scope_contents);
        }

        let notch_contents = column![
            text("applied to displayed data only").size(12),
            toggler(self.notch_enabled)
                .label(if self.notch_enabled {
                    "enabled"
                } else {
                    "disabled"
                })
                .on_toggle(Message::NotchToggled),
            text(format!("low cutoff: {:.2} MHz", self.notch_low_mhz)).size(14),
            slider(
                NOTCH_FREQ_RANGE,
                self.notch_low_mhz,
                Message::NotchLowChanged
            )
            .step(0.05),
            text(format!("high cutoff: {:.2} MHz", self.notch_high_mhz)).size(14),
            slider(
                NOTCH_FREQ_RANGE,
                self.notch_high_mhz,
                Message::NotchHighChanged
            )
            .step(0.05),
        ]
        .spacing(5);

        let mut notch_section = column![
            button(
                text(if self.show_notch {
                    "Notch filter ▾"
                } else {
                    "Notch filter ▸"
                })
                .size(16)
            )
            .style(button::text)
            .padding(0)
            .on_press(Message::NotchSectionToggled),
        ]
        .spacing(5);
        if self.show_notch {
            notch_section = notch_section.push(notch_contents);
        }

        let bmode_section = column![
            text("B-mode").size(16),
            row![
                radio(
                    "pulsed array",
                    BModeMode::PulsedArray,
                    Some(self.bmode_mode),
                    Message::BModeModeSelected,
                )
                .size(16),
                radio(
                    "raw",
                    BModeMode::Raw,
                    Some(self.bmode_mode),
                    Message::BModeModeSelected,
                )
                .size(16),
            ]
            .spacing(10),
            text("scanline source").size(14),
            combo_box(
                &self.array_source_cb,
                "scanline source",
                Some(&self.array_source),
                Message::ArraySourceSelected,
            ),
            text(format!("contrast: {:.1}×", self.contrast)).size(14),
            slider(CONTRAST_RANGE, self.contrast, Message::ContrastChanged).step(0.1),
            text(format!("speed of sound: {:.0} m/s", self.speed_of_sound)).size(14),
            slider(
                SPEED_OF_SOUND_RANGE,
                self.speed_of_sound,
                Message::SpeedOfSoundChanged
            )
            .step(1.0),
            toggler(self.sector_scan)
                .label("sector scan (warp by beam width)")
                .on_toggle(Message::SectorScanToggled)
                .size(16),
            text("y units").size(14),
            row![
                radio(
                    "depth",
                    YUnits::Depth,
                    Some(self.y_units),
                    Message::YUnitsSelected,
                )
                .size(16),
                radio(
                    "time",
                    YUnits::Time,
                    Some(self.y_units),
                    Message::YUnitsSelected,
                )
                .size(16),
            ]
            .spacing(10),
        ]
        .spacing(5);

        let mut stats_section = column![
            button(
                text(if self.show_stats {
                    "Stats ▾"
                } else {
                    "Stats ▸"
                })
                .size(16)
            )
            .style(button::text)
            .padding(0)
            .on_press(Message::StatsToggled),
        ]
        .spacing(5);
        if self.show_stats {
            let s = &self.stats;
            let line = |label: &str, value: u64| text(format!("{label}: {value}")).size(13);
            stats_section = stats_section
                .push(line("scanlines", self.shown_scanlines().len() as u64))
                .push(line("packets/s", s.packets_per_sec))
                .push(line("udp socket drops", s.socket_drops))
                .push(line("recv buffer stalls", s.recv_stalls))
                .push(line("ingest→scope drops", s.ingest_drops))
                .push(line("scope→gui deferrals", s.gui_busy))
                .push(line("scanline overflow (samples)", s.line_overflow))
                .push(line("frame splits (missed sof)", s.frame_overflow));
        }

        let sidebar = container(scrollable(
            column![
                text("Ultrasound").size(24),
                status_section,
                vga_section,
                pulser_section,
                scan_section,
                scope_section,
                notch_section,
                bmode_section,
                stats_section,
            ]
            .spacing(20)
            .padding(15),
        ))
        .style(container::bordered_box)
        .width(280)
        .height(Fill);

        let (shown, shown_trigger_index) = self.shown();
        // capture progress lives on the scope thread now; at 50 MSPS a
        // capture fills in ~1 ms, so the sweep marker was never visible
        let fill = 0;

        let tab_button = |label, tab| {
            button(label)
                .style(if self.view_tab == tab {
                    button::primary
                } else {
                    button::secondary
                })
                .on_press(Message::ViewTabSelected(tab))
        };
        let tab_bar = row![
            tab_button("scope", ViewTab::Scope),
            tab_button("b-mode", ViewTab::BMode),
        ]
        .spacing(10);

        let content: Element<'_, Message> = match self.view_tab {
            ViewTab::Scope => canvas(Plot {
                traces: shown,
                enabled: self.channel_enabled,
                x_scale: self.x_scale,
                trigger_channel: self.trigger_channel,
                trigger_level: self.trigger_level,
                trigger_index: shown_trigger_index,
                fill,
                y_range: (!self.y_auto)
                    .then_some((self.y_offset - self.y_scale, self.y_offset + self.y_scale)),
                cache: &self.plot_cache,
            })
            .width(Fill)
            .height(Fill)
            .into(),
            ViewTab::BMode => match self.bmode_mode {
                BModeMode::PulsedArray => canvas(ArrayPlot {
                    scanlines: self.shown_scanlines(),
                    sector: self.sector_scan.then(|| self.sector_geometry()),
                    fps: self.array_fps,
                    contrast: self.contrast,
                    y_units: self.y_units,
                    speed_of_sound: self.speed_of_sound,
                    cache: &self.bmode_cache,
                })
                .width(Fill)
                .height(Fill)
                .into(),
                BModeMode::Raw => canvas(BModePlot {
                    traces: shown,
                    enabled: self.channel_enabled,
                    x_scale: self.x_scale,
                    trigger_index: shown_trigger_index,
                    contrast: self.contrast,
                    y_units: self.y_units,
                    speed_of_sound: self.speed_of_sound,
                    cache: &self.bmode_cache,
                })
                .width(Fill)
                .height(Fill)
                .into(),
            },
        };

        let plot = container(column![tab_bar, content].spacing(10))
            .width(Fill)
            .height(Fill)
            .padding(10);

        row![sidebar, plot].into()
    }
}

/// `YYYYMMDD_HHMMSS` in UTC, for CSV filenames (avoids a chrono
/// dependency; date math per Howard Hinnant's civil_from_days).
fn utc_timestamp() -> String {
    let secs = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap_or_default()
        .as_secs() as i64;
    let (days, rem) = (secs.div_euclid(86400), secs.rem_euclid(86400));
    let (h, min, s) = (rem / 3600, rem % 3600 / 60, rem % 60);

    let z = days + 719_468;
    let era = z.div_euclid(146_097);
    let doe = z.rem_euclid(146_097);
    let yoe = (doe - doe / 1460 + doe / 36524 - doe / 146_096) / 365;
    let doy = doe - (365 * yoe + yoe / 4 - yoe / 100);
    let mp = (5 * doy + 2) / 153;
    let d = doy - (153 * mp + 2) / 5 + 1;
    let m = if mp < 10 { mp + 3 } else { mp - 9 };
    let y = yoe + era * 400 + i64::from(m <= 2);

    format!("{y:04}{m:02}{d:02}_{h:02}{min:02}{s:02}")
}

/// Parses calibration.csv: 8 rows (pulser channels 0-7) of
/// `x_metres,tau_seconds`, as written by calibration.py.
fn load_calibration_csv(path: &str) -> Result<Calibration, String> {
    let path = path.trim();
    if path.is_empty() {
        return Err(String::from("no file path given"));
    }
    let content = std::fs::read_to_string(path).map_err(|e| format!("{path}: {e}"))?;

    let mut calib = Calibration {
        x_el: [0.0; 8],
        z_el: [0.0; 8],
        tau: [0.0; 8],
        sign: [1.0; 8],
        t0: 0.0,
    };
    let mut rows = 0;
    for (lineno, line) in content.lines().enumerate() {
        let line = line.trim();
        if line.is_empty() {
            continue;
        }
        let parse = |field: &str| {
            field
                .trim()
                .parse::<f32>()
                .map_err(|_| format!("line {}: bad value {field:?}", lineno + 1))
        };
        if let Some(comment) = line.strip_prefix('#') {
            // `# key=value` metadata; anything else is a comment
            if let Some((key, value)) = comment.split_once('=') {
                if key.trim() == "t0_s" {
                    calib.t0 = parse(value)?;
                }
            }
            continue;
        }
        let fields: Vec<&str> = line.split(',').map(str::trim).collect();
        if rows == 0 && fields[0].parse::<f32>().is_err() {
            continue; // header
        }
        if rows >= 8 {
            return Err(String::from("more than 8 channel rows"));
        }
        match fields.len() {
            2 => {
                calib.x_el[rows] = parse(fields[0])?;
                calib.tau[rows] = parse(fields[1])?;
            }
            4 => {
                calib.x_el[rows] = parse(fields[0])?;
                calib.z_el[rows] = parse(fields[1])?;
                calib.tau[rows] = parse(fields[2])?;
                let sign = parse(fields[3])?;
                if sign != 1.0 && sign != -1.0 {
                    return Err(format!("line {}: sign must be 1 or -1", lineno + 1));
                }
                calib.sign[rows] = sign;
            }
            n => {
                return Err(format!(
                    "line {}: expected x,z,tau,sign (or x,tau), got {n} fields",
                    lineno + 1
                ));
            }
        }
        rows += 1;
    }
    if rows != 8 {
        return Err(format!("expected 8 channel rows, got {rows}"));
    }
    Ok(calib)
}

/// Transmit delay (seconds, before any per-channel offset) for an
/// element at (`x`, `z`) relative to the scanline's beam origin, so the
/// aperture's wavefront is steered by `theta` (radians, about that
/// origin) and focused at `focus_m` from it — or a plane wave when the
/// focus is infinite. As beamforming_delays in delays.py: the element
/// fires (F - |focus - element|) / c after a hypothetical element at the
/// origin.
fn transmit_delay(x: f64, z: f64, theta: f64, focus_m: f64, c: f64) -> f64 {
    let (sin_t, cos_t) = theta.sin_cos();
    if focus_m.is_infinite() {
        (x * sin_t + z * cos_t) / c
    } else {
        let dx = focus_m * sin_t - x;
        let dz = focus_m * cos_t - z;
        (focus_m - (dx * dx + dz * dz).sqrt()) / c
    }
}

/// Parses a per-channel delay table CSV: one row per scanline, 8
/// comma-separated delay values (clock cycles, 0-65535) per row,
/// channels 0-7 left to right. A single header row is tolerated. Up to
/// 256 scanlines.
fn load_delay_csv(path: &str) -> Result<Vec<[u16; 8]>, String> {
    let path = path.trim();
    if path.is_empty() {
        return Err(String::from("no file path given"));
    }
    let content = std::fs::read_to_string(path).map_err(|e| format!("{path}: {e}"))?;

    let mut table: Vec<[u16; 8]> = Vec::new();
    for (lineno, line) in content.lines().enumerate() {
        let line = line.trim();
        if line.is_empty() {
            continue;
        }
        let fields: Vec<&str> = line.split(',').map(str::trim).collect();

        // tolerate a header row
        if table.is_empty() && lineno == 0 && fields[0].parse::<u16>().is_err() {
            continue;
        }

        if fields.len() < 8 {
            return Err(format!(
                "line {}: expected 8 delay values, got {}",
                lineno + 1,
                fields.len()
            ));
        }

        let mut row = [0u16; 8];
        for (ch, field) in fields[..8].iter().enumerate() {
            row[ch] = field
                .parse()
                .map_err(|_| format!("line {}: bad delay value {field:?}", lineno + 1))?;
        }
        table.push(row);

        if table.len() > pulser::MAX_SCANLINES {
            return Err(format!("more than {} scanlines", pulser::MAX_SCANLINES));
        }
    }

    if table.is_empty() {
        return Err(String::from("no scanline rows found"));
    }
    Ok(table)
}

fn fmt_voltage(v: Option<f32>) -> String {
    match v {
        Some(v) => format!("{v:.1} V"),
        None => String::from("—"),
    }
}

fn fmt_samples_as_time(samples: usize) -> String {
    let seconds = samples as f32 * SAMPLE_PERIOD_S;
    if seconds >= 1e-3 {
        format!("{:.2} ms", seconds * 1e3)
    } else if seconds >= 1e-6 {
        format!("{:.1} µs", seconds * 1e6)
    } else {
        format!("{:.0} ns", seconds * 1e9)
    }
}

/// B-mode depth-axis ticks: positions as a fraction of the displayed
/// span, with labels in the selected units (round-trip depth at the
/// speed of sound `c`). The step is the smallest of 1/2/2.5/4/5/8×10ⁿ
/// in the display unit that keeps the count at or under 15, which
/// lands at 10-15 ticks for most spans.
fn y_axis_ticks(span_samples: usize, units: YUnits, c: f32) -> Vec<(f32, String)> {
    let span_s = span_samples as f32 * SAMPLE_PERIOD_S;
    let (total, unit) = match units {
        YUnits::Time => {
            if span_s >= 1e-3 {
                (span_s * 1e3, "ms")
            } else if span_s >= 1e-6 {
                (span_s * 1e6, "µs")
            } else {
                (span_s * 1e9, "ns")
            }
        }
        YUnits::Depth => {
            let meters = span_s * c / 2.0;
            if meters >= 0.1 {
                (meters * 1e2, "cm")
            } else {
                (meters * 1e3, "mm")
            }
        }
    };
    if total <= 0.0 {
        return Vec::new();
    }

    const NICE_STEPS: [f32; 6] = [1.0, 2.0, 2.5, 4.0, 5.0, 8.0];
    let step = (-9..9)
        .flat_map(|exp| NICE_STEPS.iter().map(move |m| m * 10.0f32.powi(exp)))
        .find(|s| (total / s) as usize <= 14)
        .unwrap_or(total);

    // decimals needed to print multiples of the step exactly
    let decimals = (0..=3)
        .find(|d| {
            let scaled = step * 10.0f32.powi(*d);
            (scaled - scaled.round()).abs() < 1e-3 * scaled
        })
        .unwrap_or(3) as usize;

    (0..=(total / step) as usize)
        .map(|i| {
            let v = i as f32 * step;
            (v / total, format!("{v:.decimals$} {unit}"))
        })
        .collect()
}

struct Plot<'a> {
    traces: &'a [Vec<f32>; 8],
    enabled: [bool; 8],
    x_scale: usize,
    trigger_channel: usize,
    trigger_level: f32,
    trigger_index: usize,
    /// Samples filled so far in an in-progress capture (0 when idle).
    fill: usize,
    /// Manual Y range (min, max); None autoscales to the data.
    y_range: Option<(f32, f32)>,
    cache: &'a canvas::Cache,
}

const PLOT_MARGIN_LEFT: f32 = 60.0;
const PLOT_MARGIN_RIGHT: f32 = 15.0;
const PLOT_MARGIN_TOP: f32 = 15.0;
const PLOT_MARGIN_BOTTOM: f32 = 30.0;

const CHANNEL_NAMES: [&str; 8] = ["A", "B", "C", "D", "E", "F", "G", "H"];

/// Clickable legend entry bounds, relative to the canvas top-left.
fn legend_rect(ch: usize) -> Rectangle {
    Rectangle {
        x: PLOT_MARGIN_LEFT + 10.0 + ch as f32 * 40.0,
        y: PLOT_MARGIN_TOP + 2.0,
        width: 36.0,
        height: 18.0,
    }
}

impl canvas::Program<Message> for Plot<'_> {
    type State = ();

    fn update(
        &self,
        _state: &mut Self::State,
        event: &canvas::Event,
        bounds: Rectangle,
        cursor: mouse::Cursor,
    ) -> Option<canvas::Action<Message>> {
        if let canvas::Event::Mouse(mouse::Event::ButtonPressed(mouse::Button::Left)) = event {
            let position = cursor.position_in(bounds)?;
            for ch in 0..8 {
                if legend_rect(ch).contains(position) {
                    return Some(canvas::Action::publish(Message::ChannelToggled(ch)));
                }
            }
        }

        None
    }

    fn mouse_interaction(
        &self,
        _state: &Self::State,
        bounds: Rectangle,
        cursor: mouse::Cursor,
    ) -> mouse::Interaction {
        if let Some(position) = cursor.position_in(bounds) {
            if (0..8).any(|ch| legend_rect(ch).contains(position)) {
                return mouse::Interaction::Pointer;
            }
        }

        mouse::Interaction::default()
    }

    fn draw(
        &self,
        _state: &Self::State,
        renderer: &Renderer,
        theme: &Theme,
        bounds: Rectangle,
        _cursor: mouse::Cursor,
    ) -> Vec<canvas::Geometry> {
        let geometry = self.cache.draw(renderer, bounds.size(), |frame| {
            let palette = theme.extended_palette();

            let area = Rectangle {
                x: PLOT_MARGIN_LEFT,
                y: PLOT_MARGIN_TOP,
                width: (frame.width() - PLOT_MARGIN_LEFT - PLOT_MARGIN_RIGHT).max(1.0),
                height: (frame.height() - PLOT_MARGIN_TOP - PLOT_MARGIN_BOTTOM).max(1.0),
            };

            // plot background & border
            frame.fill_rectangle(
                area.position(),
                area.size(),
                palette.background.weakest.color,
            );
            frame.stroke(
                &canvas::Path::rectangle(area.position(), area.size()),
                canvas::Stroke::default()
                    .with_color(palette.background.strong.color)
                    .with_width(1.0),
            );

            if self.traces.iter().all(|t| t.is_empty()) {
                frame.fill_text(canvas::Text {
                    content: String::from("waiting for data..."),
                    position: Point::new(area.center_x(), area.center_y()),
                    color: palette.background.strong.color,
                    size: 20.0.into(),
                    align_x: text::Alignment::Center,
                    align_y: alignment::Vertical::Center,
                    ..canvas::Text::default()
                });
                return;
            }

            // fixed X span; Y is manual or autoscaled to the enabled channels
            let x_min = 0.0f32;
            let x_max = self.x_scale as f32;
            let (y_min, y_max) = match self.y_range {
                Some(range) => range,
                None => {
                    let (mut y_min, mut y_max) = (f32::INFINITY, f32::NEG_INFINITY);
                    for (trace, _) in self.traces.iter().zip(self.enabled).filter(|&(_, e)| e) {
                        for &y in trace {
                            y_min = y_min.min(y);
                            y_max = y_max.max(y);
                        }
                    }
                    // no enabled channels with data
                    if !y_min.is_finite() {
                        (y_min, y_max) = (-1.0, 1.0);
                    }
                    // avoid a degenerate scale when the data is flat
                    if y_max - y_min < f32::EPSILON {
                        y_min -= 1.0;
                        y_max += 1.0;
                    }
                    (y_min, y_max)
                }
            };

            let to_screen = |x: f32, y: f32| {
                Point::new(
                    area.x + (x - x_min) / (x_max - x_min) * area.width,
                    area.y + area.height - (y - y_min) / (y_max - y_min) * area.height,
                )
            };

            // zero line, if visible
            if y_min < 0.0 && y_max > 0.0 {
                let y0 = to_screen(x_min, 0.0).y;
                frame.stroke(
                    &canvas::Path::line(
                        Point::new(area.x, y0),
                        Point::new(area.x + area.width, y0),
                    ),
                    canvas::Stroke::default()
                        .with_color(palette.background.strong.color)
                        .with_width(1.0),
                );
            }

            let channel_colors = [
                palette.primary.base.color,
                palette.success.base.color,
                palette.warning.base.color,
                palette.danger.base.color,
                palette.secondary.base.color,
                Color::from_rgb(0.5, 0., 0.5),
                Color::from_rgb(0.5, 0.5, 0.),
                Color::from_rgb(0., 0.5, 0.5),
            ];

            // trigger level marker
            if self.trigger_level >= y_min && self.trigger_level <= y_max {
                let y = to_screen(x_min, self.trigger_level).y;
                frame.stroke(
                    &canvas::Path::line(Point::new(area.x, y), Point::new(area.x + area.width, y)),
                    canvas::Stroke {
                        line_dash: canvas::LineDash {
                            segments: &[4.0, 4.0],
                            offset: 0,
                        },
                        ..canvas::Stroke::default()
                            .with_color(channel_colors[self.trigger_channel])
                            .with_width(1.0)
                    },
                );
            }

            // trigger X position marker
            if self.trigger_index > 0 && self.traces.iter().any(|t| !t.is_empty()) {
                let x = to_screen(self.trigger_index as f32, 0.0).x;
                frame.stroke(
                    &canvas::Path::line(Point::new(x, area.y), Point::new(x, area.y + area.height)),
                    canvas::Stroke {
                        line_dash: canvas::LineDash {
                            segments: &[4.0, 4.0],
                            offset: 0,
                        },
                        ..canvas::Stroke::default()
                            .with_color(channel_colors[self.trigger_channel])
                            .with_width(1.0)
                    },
                );
            }

            // traces: time-ordered from the trigger point. Not clipped: a
            // manual Y range can draw slightly outside the plot area, but
            // with_clip doesn't render inside a cached canvas frame
            for (ch, (trace, color)) in self.traces.iter().zip(channel_colors).enumerate() {
                if !self.enabled[ch] || trace.len() < 2 {
                    continue;
                }

                let path = canvas::Path::new(|builder| {
                    builder.move_to(to_screen(0.0, trace[0]));
                    for (i, &y) in trace.iter().enumerate().skip(1) {
                        builder.line_to(to_screen(i as f32, y));
                    }
                });
                frame.stroke(
                    &path,
                    canvas::Stroke::default().with_color(color).with_width(1.0),
                );
            }

            // sweep position while a capture is filling
            if self.fill > 0 && self.fill < self.x_scale {
                let x = to_screen(self.fill as f32, 0.0).x;
                frame.stroke(
                    &canvas::Path::line(Point::new(x, area.y), Point::new(x, area.y + area.height)),
                    canvas::Stroke::default()
                        .with_color(palette.background.strong.color)
                        .with_width(1.0),
                );
            }

            // legend (ADC34J2x channel names); click to toggle a channel
            for (ch, color) in channel_colors.iter().enumerate() {
                let rect = legend_rect(ch);
                frame.fill_text(canvas::Text {
                    content: format!("ch{}", CHANNEL_NAMES[ch]),
                    position: Point::new(rect.x, rect.y + 3.0),
                    color: if self.enabled[ch] {
                        *color
                    } else {
                        palette.background.strong.color
                    },
                    size: 12.0.into(),
                    ..canvas::Text::default()
                });
            }

            // axis extent labels
            let label = |content: String,
                         position: Point,
                         align_x: text::Alignment,
                         align_y: alignment::Vertical| {
                canvas::Text {
                    content,
                    position,
                    color: palette.background.base.text,
                    size: 12.0.into(),
                    align_x,
                    align_y,
                    ..canvas::Text::default()
                }
            };

            frame.fill_text(label(
                format!("{y_max:.1}"),
                Point::new(area.x - 5.0, area.y),
                text::Alignment::Right,
                alignment::Vertical::Center,
            ));
            frame.fill_text(label(
                format!("{y_min:.1}"),
                Point::new(area.x - 5.0, area.y + area.height),
                text::Alignment::Right,
                alignment::Vertical::Center,
            ));
            frame.fill_text(label(
                String::from("0"),
                Point::new(area.x, area.y + area.height + 5.0),
                text::Alignment::Left,
                alignment::Vertical::Top,
            ));
            frame.fill_text(label(
                fmt_samples_as_time(self.x_scale / 2),
                Point::new(area.x + area.width / 2.0, area.y + area.height + 5.0),
                text::Alignment::Center,
                alignment::Vertical::Top,
            ));
            frame.fill_text(label(
                fmt_samples_as_time(self.x_scale),
                Point::new(area.x + area.width, area.y + area.height + 5.0),
                text::Alignment::Right,
                alignment::Vertical::Top,
            ));
        });

        vec![geometry]
    }
}

/// Traditional ultrasound view: amplitude as brightness vs depth (1D).
/// Top = trigger point, bottom = right edge of the scope's X scale.
struct BModePlot<'a> {
    traces: &'a [Vec<f32>; 8],
    enabled: [bool; 8],
    x_scale: usize,
    trigger_index: usize,
    contrast: f32,
    y_units: YUnits,
    speed_of_sound: f32,
    cache: &'a canvas::Cache,
}

impl canvas::Program<Message> for BModePlot<'_> {
    type State = ();

    fn draw(
        &self,
        _state: &Self::State,
        renderer: &Renderer,
        theme: &Theme,
        bounds: Rectangle,
        _cursor: mouse::Cursor,
    ) -> Vec<canvas::Geometry> {
        let geometry = self.cache.draw(renderer, bounds.size(), |frame| {
            let palette = theme.extended_palette();

            let area = Rectangle {
                x: PLOT_MARGIN_LEFT,
                y: PLOT_MARGIN_TOP,
                width: (frame.width() - PLOT_MARGIN_LEFT - PLOT_MARGIN_RIGHT).max(1.0),
                height: (frame.height() - PLOT_MARGIN_TOP - PLOT_MARGIN_BOTTOM).max(1.0),
            };

            // classic ultrasound look: black background regardless of theme
            frame.fill_rectangle(area.position(), area.size(), Color::BLACK);
            frame.stroke(
                &canvas::Path::rectangle(area.position(), area.size()),
                canvas::Stroke::default()
                    .with_color(palette.background.strong.color)
                    .with_width(1.0),
            );

            if self.traces.iter().all(|t| t.is_empty()) {
                frame.fill_text(canvas::Text {
                    content: String::from("waiting for data..."),
                    position: Point::new(area.center_x(), area.center_y()),
                    color: palette.background.strong.color,
                    size: 20.0.into(),
                    align_x: text::Alignment::Center,
                    align_y: alignment::Vertical::Center,
                    ..canvas::Text::default()
                });
                return;
            }

            let channel_colors: [Color; 8] = [
                palette.primary.base.color,
                palette.success.base.color,
                palette.warning.base.color,
                palette.danger.base.color,
                palette.secondary.base.color,
                Color::from_rgb(0.5, 0., 0.5),
                Color::from_rgb(0.5, 0.5, 0.),
                Color::from_rgb(0., 0.5, 0.5),
            ];

            // depth axis: trigger point at the top, X scale end at the bottom
            let start = self.trigger_index.min(self.x_scale.saturating_sub(1));
            let span = (self.x_scale - start).max(1);

            let channels: Vec<usize> = (0..8).filter(|&ch| self.enabled[ch]).collect();
            if channels.is_empty() {
                return;
            }

            let column_width = area.width / channels.len() as f32;
            let rows = area.height as usize;

            for (i, &ch) in channels.iter().enumerate() {
                let trace = &self.traces[ch];
                let column_x = area.x + i as f32 * column_width;

                for row in 0..rows {
                    // samples covered by this pixel row (peak-detect)
                    let s0 = start + (row as f32 / rows as f32 * span as f32) as usize;
                    let s1 = (start + ((row + 1) as f32 / rows as f32 * span as f32) as usize)
                        .max(s0 + 1);

                    if s0 >= trace.len() {
                        break;
                    }

                    let peak = trace[s0..s1.min(trace.len())]
                        .iter()
                        .fold(0.0f32, |max, &v| max.max(v.abs()));

                    let brightness = (peak / 2048.0 * self.contrast).clamp(0.0, 1.0);
                    if brightness < 1.0 / 512.0 {
                        continue;
                    }

                    frame.fill_rectangle(
                        Point::new(column_x, area.y + row as f32),
                        Size::new(column_width, 1.0),
                        Color::from_rgb(brightness, brightness, brightness),
                    );
                }

                // channel label, matching the scope's colors
                frame.fill_text(canvas::Text {
                    content: format!("ch{}", CHANNEL_NAMES[ch]),
                    position: Point::new(column_x + 5.0, area.y + 5.0),
                    color: channel_colors[ch],
                    size: 12.0.into(),
                    ..canvas::Text::default()
                });
            }

            // depth (time-from-trigger) labels
            let label = |content: String, y: f32| canvas::Text {
                content,
                position: Point::new(area.x - 5.0, y),
                color: palette.background.base.text,
                size: 12.0.into(),
                align_x: text::Alignment::Right,
                align_y: alignment::Vertical::Center,
                ..canvas::Text::default()
            };
            for (frac, content) in y_axis_ticks(span, self.y_units, self.speed_of_sound) {
                let y = area.y + frac * area.height;
                frame.fill_text(label(content, y));
                frame.stroke(
                    &canvas::Path::line(Point::new(area.x - 4.0, y), Point::new(area.x, y)),
                    canvas::Stroke::default()
                        .with_color(palette.background.strong.color)
                        .with_width(1.0),
                );
            }
        });

        vec![geometry]
    }
}

/// Traditional pulsed-array ultrasound view: one column per scanline,
/// beamformed amplitude as brightness vs depth (top = start of line).
/// Scan geometry for the sector display: the steering span, the
/// aperture the beam origins are spread across and the line count the
/// frame is meant to have (so a short frame does not stretch).
#[derive(Debug, Clone, Copy)]
struct SectorGeometry {
    width_deg: f32,
    x_min: f32,
    x_max: f32,
    num_scanlines: u32,
}

struct ArrayPlot<'a> {
    scanlines: &'a [Vec<f32>],
    /// Scan-convert into a sector; None draws one column per scanline.
    sector: Option<SectorGeometry>,
    /// Live frame rate, if frames are completing.
    fps: Option<f32>,
    contrast: f32,
    y_units: YUnits,
    speed_of_sound: f32,
    cache: &'a canvas::Cache,
}

impl canvas::Program<Message> for ArrayPlot<'_> {
    type State = ();

    fn draw(
        &self,
        _state: &Self::State,
        renderer: &Renderer,
        theme: &Theme,
        bounds: Rectangle,
        _cursor: mouse::Cursor,
    ) -> Vec<canvas::Geometry> {
        let geometry = self.cache.draw(renderer, bounds.size(), |frame| {
            let palette = theme.extended_palette();

            let area = Rectangle {
                x: PLOT_MARGIN_LEFT,
                y: PLOT_MARGIN_TOP,
                width: (frame.width() - PLOT_MARGIN_LEFT - PLOT_MARGIN_RIGHT).max(1.0),
                height: (frame.height() - PLOT_MARGIN_TOP - PLOT_MARGIN_BOTTOM).max(1.0),
            };

            // classic ultrasound look: black background regardless of theme
            frame.fill_rectangle(area.position(), area.size(), Color::BLACK);
            frame.stroke(
                &canvas::Path::rectangle(area.position(), area.size()),
                canvas::Stroke::default()
                    .with_color(palette.background.strong.color)
                    .with_width(1.0),
            );

            // depth axis spans the longest scanline
            let span = self.scanlines.iter().map(Vec::len).max().unwrap_or(0);
            if span == 0 {
                frame.fill_text(canvas::Text {
                    content: String::from("waiting for scanlines..."),
                    position: Point::new(area.center_x(), area.center_y()),
                    color: palette.background.strong.color,
                    size: 20.0.into(),
                    align_x: text::Alignment::Center,
                    align_y: alignment::Vertical::Center,
                    ..canvas::Text::default()
                });
                return;
            }

            let rows = area.height as usize;
            // pixel row -> peak-detected brightness of a scanline
            let brightness_rows = |line: &[f32], rows: usize| -> Vec<f32> {
                (0..rows)
                    .map(|row| {
                        let s0 = (row as f32 / rows as f32 * span as f32) as usize;
                        let s1 = ((row + 1) as f32 / rows as f32 * span as f32)
                            .max(s0 as f32 + 1.0) as usize;
                        let peak = line
                            .get(s0..s1.min(line.len()))
                            .unwrap_or(&[])
                            .iter()
                            .fold(0.0f32, |max, &v| max.max(v.abs()));
                        (peak / 2048.0 * self.contrast).clamp(0.0, 1.0)
                    })
                    .collect()
            };

            // depth-axis length in pixels: the full area height, or less
            // when the sector's arc would not fit the width
            let mut radius = area.height;
            // depth axis: along the sector's left boundary (start, end
            // points) or None for the plot's left edge
            let mut axis_line: Option<(Point, Point)> = None;

            if let Some(sec) = self.sector {
                // lines are placed by the frame's intended count so a
                // short frame does not stretch to fill the sector
                let n = (sec.num_scanlines as usize).max(self.scanlines.len()).max(1) as u32;
                let half = sec.width_deg.to_radians() / 2.0;
                let aperture = (sec.x_max - sec.x_min).max(0.0);
                let depth_m = span as f32 * SAMPLE_PERIOD_S * self.speed_of_sound / 2.0;
                // fit the sector's widest extent (aperture half-width plus
                // the swept arc) into the area
                let lateral = half.sin() + if depth_m > 0.0 { aperture / (2.0 * depth_m) } else { 0.0 };
                if lateral > 0.0 {
                    radius = radius.min(area.width / 2.0 / lateral);
                }
                let px_per_m = if depth_m > 0.0 { radius / depth_m } else { 0.0 };
                let centre_m = (sec.x_min + sec.x_max) / 2.0;
                let cx = area.center_x();
                // screen point at range r (pixels) along boundary j
                let boundary_point = |j: usize, r: f32| {
                    let ang = sector_boundary_angle(sec.width_deg, n, j);
                    let ox = cx - (sector_boundary_x(sec.x_min, sec.x_max, n, j) - centre_m) * px_per_m;
                    Point::new(ox - r * ang.sin(), area.y + r * ang.cos())
                };
                let grid_rows = radius.ceil().max(1.0) as usize;
                let row_px = radius / grid_rows as f32;
                axis_line = Some((boundary_point(0, 0.0), boundary_point(0, radius)));

                for (i, line) in self.scanlines.iter().enumerate().take(n as usize) {
                    let levels = brightness_rows(line, grid_rows);
                    // one wedge per run of equal brightness along the line
                    let mut run_start = 0usize;
                    let mut run_level = 0u32;
                    for row in 0..=grid_rows {
                        let level = if row < grid_rows {
                            (levels[row] * 255.0).round() as u32
                        } else {
                            u32::MAX
                        };
                        if level != run_level {
                            if run_level > 0 && row > run_start {
                                let (r0, r1) = (run_start as f32 * row_px, row as f32 * row_px);
                                let b = run_level as f32 / 255.0;
                                let wedge = canvas::Path::new(|p| {
                                    p.move_to(boundary_point(i, r0));
                                    p.line_to(boundary_point(i, r1));
                                    p.line_to(boundary_point(i + 1, r1));
                                    p.line_to(boundary_point(i + 1, r0));
                                    p.close();
                                });
                                frame.fill(&wedge, Color::from_rgb(b, b, b));
                            }
                            run_start = row;
                            run_level = level;
                        }
                    }
                }
            } else {
                let column_width = area.width / self.scanlines.len() as f32;
                for (i, line) in self.scanlines.iter().enumerate() {
                    let column_x = area.x + i as f32 * column_width;
                    let levels = brightness_rows(line, rows);

                    // merge consecutive rows of equal brightness into one
                    // rectangle to keep the geometry count down
                    let mut run_start = 0usize;
                    let mut run_level = 0u32; // quantized brightness, 0 = skip
                    for row in 0..=rows {
                        let level = if row < rows {
                            (levels[row] * 255.0).round() as u32
                        } else {
                            u32::MAX // flush the last run
                        };

                        if level != run_level {
                            if run_level > 0 && row > run_start {
                                let b = run_level as f32 / 255.0;
                                frame.fill_rectangle(
                                    Point::new(column_x, area.y + run_start as f32),
                                    Size::new(column_width, (row - run_start) as f32),
                                    Color::from_rgb(b, b, b),
                                );
                            }
                            run_start = row;
                            run_level = level;
                        }
                    }
                }
            }

            // live frame rate, top-left (scanline count lives in the
            // sidebar stats area)
            frame.fill_text(canvas::Text {
                content: match self.fps {
                    Some(fps) => format!("{fps:.1} fps"),
                    None => String::new(),
                },
                position: Point::new(area.x + 5.0, area.y + 5.0),
                color: palette.background.strong.color,
                size: 12.0.into(),
                ..canvas::Text::default()
            });

            // depth (time-from-line-start) labels, along the axis line:
            // ticks and labels stick out on its outward (left) side
            let (start, end) = axis_line.unwrap_or((
                Point::new(area.x, area.y),
                Point::new(area.x, area.y + radius),
            ));
            let (dx, dy) = (end.x - start.x, end.y - start.y);
            let len = (dx * dx + dy * dy).sqrt().max(1e-6);
            let outward = (-dy / len, dx / len); // left-hand normal of the downward axis
            // the sector axis lies on the black image, so it uses light
            // colours regardless of theme; the edge axis sits in the margin
            let (text_color, line_color) = if axis_line.is_some() {
                (Color::from_rgb(0.9, 0.9, 0.9), Color::from_rgb(0.6, 0.6, 0.6))
            } else {
                (palette.background.base.text, palette.background.strong.color)
            };
            let label = |content: String, p: Point| canvas::Text {
                content,
                position: Point::new(p.x + 6.0 * outward.0, p.y + 6.0 * outward.1),
                color: text_color,
                size: 12.0.into(),
                align_x: text::Alignment::Right,
                align_y: alignment::Vertical::Center,
                ..canvas::Text::default()
            };
            let stroke = canvas::Stroke::default()
                .with_color(line_color)
                .with_width(1.0);
            if axis_line.is_some() {
                frame.stroke(&canvas::Path::line(start, end), stroke);
            }
            for (frac, content) in y_axis_ticks(span, self.y_units, self.speed_of_sound) {
                let p = Point::new(start.x + frac * dx, start.y + frac * dy);
                frame.fill_text(label(content, p));
                frame.stroke(
                    &canvas::Path::line(p, Point::new(p.x + 4.0 * outward.0, p.y + 4.0 * outward.1)),
                    stroke,
                );
            }
        });

        vec![geometry]
    }
}

async fn setup_pulser(u: &mut Ultrasound, config: PulserConfig) -> Result<(), io::Error> {
    let frequency_mhz = 1000.0 / config.duration_ns;
    u.pulser
        .setup(
            &mut u.interface,
            frequency_mhz,
            config.recv_time_us as u32,
            config.ramp_delay_us as u32,
        )
        .await
}

fn hardware_ctrl_worker() -> impl Stream<Item = HwEvent> {
    iced::stream::channel(100, async move |mut output| {
        loop {
            let reason = match hardware_ctrl_session(&mut output).await {
                Ok(()) => String::from("command channel closed"),
                Err(e) => e.to_string(),
            };
            let _ = output.send(HwEvent::Disconnected(reason)).await;

            tokio::time::sleep(RECONNECT_DELAY).await;
        }
    })
}

fn hardware_data_worker() -> impl Stream<Item = ScopeEvent> {
    let (mut gui_tx, gui_rx) = mpsc::channel(256);
    // deep enough to ride out the scope thread's cold start and
    // scheduling hiccups (~128 ms of packets at full stream rate);
    // near-empty at steady state
    let (packet_tx, packet_rx) = std_mpsc::sync_channel(65536);
    let (command_tx, command_rx) = std_mpsc::channel();

    let _ = gui_tx.try_send(ScopeEvent::Ready(command_tx));

    let stats = Arc::new(IngestStats::default());
    let ingest_stats = Arc::clone(&stats);
    let _ = std::thread::Builder::new().name(String::from("ingest")).spawn(move || {
        if let Err(e) = hardware_data_session(packet_tx, ingest_stats) {
            println!("data session closed: {e}");
        }
    });
    let _ = std::thread::Builder::new()
        .name(String::from("scope"))
        .spawn(move || scope_session(packet_rx, command_rx, gui_tx, stats));

    gui_rx
}

/// Connects to the board and services GUI commands until an I/O error
/// occurs.
async fn hardware_ctrl_session(output: &mut mpsc::Sender<HwEvent>) -> Result<(), io::Error> {
    let _ = output
        .send(HwEvent::Status(String::from("connecting...")))
        .await;

    let mut u = Ultrasound::connect().await?;

    let (command_tx, mut command_rx) = mpsc::channel(32);
    let _ = output.send(HwEvent::Connected(command_tx)).await;

    // report the supply limits and the target currently set in hardware,
    // so the GUI setpoint controls start out matching reality
    let target = u.hvplus.get_target_voltage(&mut u.interface).await?;
    let _ = output
        .send(HwEvent::HvPlusInfo {
            min: u.hvplus.min_voltage(),
            max: u.hvplus.max_voltage(),
            target,
        })
        .await;
    let target = u.hvminus.get_target_voltage(&mut u.interface).await?;
    let _ = output
        .send(HwEvent::HvMinusInfo {
            min: u.hvminus.min_voltage(),
            max: u.hvminus.max_voltage(),
            target,
        })
        .await;
    let _ = output
        .send(HwEvent::RampRateInfo {
            // the fastest ramp rate is the shortest ramp time
            min_us: u.ramp.max_ramp_rate(),
            max_us: u.ramp.min_ramp_rate(),
        })
        .await;

    // seed the pulsing toggle with the hardware's actual state
    let pulsing = u.pulser.is_pulsing(&mut u.interface).await?;
    let _ = output.send(HwEvent::PulsingState(pulsing)).await;

    let mut poll = tokio::time::interval(HV_POLL_PERIOD);

    loop {
        tokio::select! {
            _ = poll.tick() => {
                let v = u.hvplus.get_voltage(&mut u.interface).await?;
                let _ = output.send(HwEvent::HvPlusVoltage(v)).await;

                let v = u.hvminus.get_voltage(&mut u.interface).await?;
                let _ = output.send(HwEvent::HvMinusVoltage(v)).await;
            }

            command = command_rx.next() => {
                let Some(command) = command else { return Ok(()) };
                let mut batch = vec![command];
                while let Ok(command) = command_rx.try_recv() {
                    batch.push(command);
                }
                for command in coalesce_commands(batch) {
                    let status = match command {
                        HwCommand::SetRampRate(time_us) => {
                            // stay strictly inside the limits: set_ramp_rate
                            // asserts 0 < r_pot < full scale
                            let time_us = time_us.clamp(
                                u.ramp.max_ramp_rate() + 0.1,
                                u.ramp.min_ramp_rate() - 0.1,
                            );
                            u.ramp.set_ramp_rate(&mut u.interface, time_us).await?;
                            format!("ramp rate set to {time_us:.1} µs")
                        }
                        HwCommand::SetHvPlus(v) => {
                            let _ = output
                                .send(HwEvent::Status(format!("ramping HV+ to {v:.1} V...")))
                                .await;
                            u.hvplus.set_target_voltage(&mut u.interface, v).await?;
                            format!("HV+ target set to {v:.1} V")
                        }
                        HwCommand::SetHvMinus(v) => {
                            let _ = output
                                .send(HwEvent::Status(format!("ramping HV− to −{v:.1} V...")))
                                .await;
                            u.hvminus.set_target_voltage(&mut u.interface, v).await?;
                            format!("HV− target set to {v:.1} V")
                        }
                        HwCommand::SetupPulser(config) => {
                            setup_pulser(&mut u, config).await?;
                            format!(
                                "pulser set: {:.0} ns, ramp delay {:.0} µs, recv {:.0} µs",
                                config.duration_ns, config.ramp_delay_us, config.recv_time_us
                            )
                        }
                        HwCommand::InitHw => {
                            let _ = output
                                .send(HwEvent::Status(String::from("initializing hardware...")))
                                .await;

                            u.init_hw().await?;

                            String::from("hardware initialized (clk + ADC + PHY reset)")
                        }
                        HwCommand::StartPulses(config) => {
                            setup_pulser(&mut u, config).await?;
                            u.pulser.arm(&mut u.interface).await?;
                            u.pulser.start(&mut u.interface).await?;
                            // the pulser restarts itself after the idle time
                            format!("pulsing started ({:.0} ns)", config.duration_ns)
                        }
                        HwCommand::StopPulses => {
                            u.pulser.disarm(&mut u.interface).await?;
                            String::from("pulsing stopped")
                        }
                        HwCommand::SetupArray {
                            idle_us,
                            num_scanlines,
                            restart,
                        } => {
                            u.pulser.set_idle_time(&mut u.interface, idle_us).await?;
                            u.pulser
                                .set_num_scanlines(&mut u.interface, num_scanlines)
                                .await?;
                            if restart {
                                // reset the FPGA line counter so SOF markers
                                // keep firing after the count is lowered
                                u.pulser.disarm(&mut u.interface).await?;
                                u.pulser.arm(&mut u.interface).await?;
                                u.pulser.start(&mut u.interface).await?;
                            }
                            format!("array set: idle {idle_us:.0} µs, {num_scanlines} scanlines")
                        }
                        HwCommand::LoadDelays(table) => {
                            u.pulser.write_delay_table(&mut u.interface, &table).await?;
                            format!("delay table written ({} scanlines)", table.len())
                        }
                    };
                    let _ = output.send(HwEvent::Status(status)).await;
                }
            }

        }
    }
}

/// Keeps only the newest command of each kind (so a dragged slider's
/// intermediate values are skipped), in the order the survivors were
/// sent.
fn coalesce_commands(batch: Vec<HwCommand>) -> Vec<HwCommand> {
    let mut kept: Vec<HwCommand> = Vec::new();
    for command in batch.into_iter().rev() {
        let kind = std::mem::discriminant(&command);
        if !kept.iter().any(|c| std::mem::discriminant(c) == kind) {
            kept.push(command);
        }
    }
    kept.reverse();
    kept
}

fn hardware_data_session(
    output: std_mpsc::SyncSender<DataPacket>,
    stats: Arc<IngestStats>,
) -> Result<(), io::Error> {
    let mut pb = ProactorBuilder::new();
    // each packet consumes one pool buffer regardless of its size, so
    // size the buffers to the packet (~1.3 KB) and provide ~60 ms worth
    // at the full ~500k packets/s stream rate
    pb.buffer_pool_buffer_len(2048);
    pb.buffer_pool_size(NonZero::new(32768).unwrap());

    let runtime = compio_runtime::Runtime::builder()
        .with_proactor(pb)
        .build()?;
    runtime.block_on(async {
        // allocate the buffer pool before binding: the stream floods the
        // socket the moment it exists, and lazy pool init would eat ~10 ms
        compio_runtime::Runtime::with_current(|rt| rt.buffer_pool().map(drop))?;
        println!("binding socket");
        let data_socket = Ultrasound::bind_data_socket_compio().await?;
        unsafe {
            data_socket
                .set_socket_option::<libc::c_int>(SOL_SOCKET, SO_RCVBUF, &(4 * 1024 * 1024))
                .unwrap();
        }
        let mut dropped = 0u64;
        let mut recv_errors = 0u64;
        let mut last_drop_report = Instant::now();
        loop {
            let mut packet_stream = data_socket.recv_multi(0);
            while let Some(result) = packet_stream.next().await {
                let result = match result {
                    Ok(result) => result,
                    Err(e) => {
                        recv_errors += 1;
                        stats.recv_stalls.fetch_add(1, Relaxed);
                        if last_drop_report.elapsed() >= Duration::from_secs(1) {
                            println!("Error receiving data ({recv_errors}x): {e}");
                            recv_errors = 0;
                            last_drop_report = Instant::now();
                        }
                        continue;
                    }
                };
                stats.packets.fetch_add(1, Relaxed);

                let (sof, sol, payload) = if result.len() > NUM_SAMPLES_PER_PACKET * 16 {
                    // 16-bit little-endian header, then the sample payload
                    let (header, payload) = result.split_at_checked(16).unwrap();
                    let header = u16::from_le_bytes([header[0], header[1]]);
                    let start_of_frame = header & 1 << 6 != 0;
                    let start_of_line = header & 1 << 7 != 0;
                    (start_of_frame, start_of_line, payload)
                } else {
                    (false, false, &result[..])
                };

                // each 16-byte chunk is two JESD204B frames (LMFS = 2441,
                // ADC34J2x datasheet fig. 158): lane DA's 4 octets then
                // lane DD's, one sample per channel. Each sample is two
                // octets, MSB first: ch[11:4] then ch[3:0] + 4 zero tail
                // bits; 12-bit two's complement. Parsed channel-major so
                // the scope thread gets a contiguous slice per channel.
                let n = payload.len() / 16;
                let mut samples = Vec::with_capacity(n * 8);
                for ch in 0..8 {
                    samples.extend(payload.chunks_exact(16).map(|chunk| {
                        let word = i16::from_be_bytes([chunk[2 * ch], chunk[2 * ch + 1]]);
                        (word >> 4) as f32 // arithmetic: drops tail bits, keeps sign
                    }));
                }
                match output.try_send(DataPacket {
                    start_of_frame: sof,
                    start_of_line: sol,
                    samples,
                }) {
                    Ok(()) => (),
                    Err(std_mpsc::TrySendError::Full(_)) => {
                        dropped += 1;
                        stats.channel_drops.fetch_add(1, Relaxed);
                    }
                    Err(std_mpsc::TrySendError::Disconnected(_)) => {
                        return Ok::<_, io::Error>(());
                    }
                }
                if dropped > 0 && last_drop_report.elapsed() >= Duration::from_secs(1) {
                    println!("ingest: dropped {dropped} packets (scope thread backlog)");
                    dropped = 0;
                    last_drop_report = Instant::now();
                }
            }
        }
    })?;

    Ok(())
}

/// The scope-processing thread: consumes every data packet, runs the
/// software-trigger state machine and pulsed-array assembly, and
/// publishes only display-rate results to the GUI.
fn scope_session(
    packets: std_mpsc::Receiver<DataPacket>,
    commands: std_mpsc::Receiver<ScopeCommand>,
    mut output: mpsc::Sender<ScopeEvent>,
    stats: Arc<IngestStats>,
) {
    let mut scope = ScopeState::default();
    let mut last_stats = Instant::now();
    let mut last_packets = 0u64;
    loop {
        // a timeout keeps stats and pending publishes flowing even when
        // the stream stalls
        match packets.recv_timeout(Duration::from_millis(250)) {
            Ok(first) => {
                for command in commands.try_iter() {
                    scope.apply(command);
                }
                scope.process(&first);
                // drain whatever else is already queued before publishing
                for packet in packets.try_iter().take(512) {
                    scope.process(&packet);
                }
            }
            Err(std_mpsc::RecvTimeoutError::Timeout) => {
                for command in commands.try_iter() {
                    scope.apply(command);
                }
            }
            Err(std_mpsc::RecvTimeoutError::Disconnected) => return,
        }
        if !scope.publish(&mut output) {
            return; // GUI is gone
        }

        let elapsed = last_stats.elapsed();
        if elapsed >= Duration::from_secs(1) {
            let packets_total = stats.packets.load(Relaxed);
            let snapshot = PipelineStatsSnapshot {
                packets_per_sec: ((packets_total - last_packets) as f32
                    / elapsed.as_secs_f32()) as u64,
                socket_drops: read_socket_drops().unwrap_or(0),
                recv_stalls: stats.recv_stalls.load(Relaxed),
                ingest_drops: stats.channel_drops.load(Relaxed),
                gui_busy: scope.gui_busy,
                line_overflow: scope.line_overflow,
                frame_overflow: scope.frame_overflow,
            };
            let _ = output.try_send(ScopeEvent::Stats(snapshot));
            last_packets = packets_total;
            last_stats = Instant::now();
        }
    }
}

/// Kernel drop counter for the data socket, from /proc/net/udp (the
/// last column of the row whose local address ends with our port).
fn read_socket_drops() -> Option<u64> {
    let table = std::fs::read_to_string("/proc/net/udp").ok()?;
    let port_suffix = format!(":{:04X}", ultrasound::ULTRASOUND_DATA_PORT);
    for line in table.lines().skip(1) {
        let mut fields = line.split_whitespace();
        if fields.nth(1).is_some_and(|local| local.ends_with(&port_suffix)) {
            return fields.next_back()?.parse().ok();
        }
    }
    None
}

struct ScopeState {
    settings: ScopeSettings,
    acquisition: Acquisition,
    /// Capture currently being filled; moved into `pending_capture` when
    /// complete.
    capture: [Vec<f32>; 8],
    /// Where the trigger landed in the capture being filled.
    trigger_index: usize,
    /// Completed capture awaiting a (throttled) publish; newer
    /// completions replace older unpublished ones.
    pending_capture: Option<([Vec<f32>; 8], usize, bool)>,
    /// Rolling pre-trigger history, capped at `x_scale` samples per
    /// channel. Maintained only while the trigger position is nonzero.
    history: [VecDeque<f32>; 8],
    /// Last sample of the trigger channel from the previous packet.
    prev_trigger_sample: Option<f32>,
    /// Global frame index of the first frame of the current packet.
    frame_count: u64,
    /// Global frame index of the last trigger, for holdoff.
    last_trigger: Option<u64>,
    /// Pulsed-array frame currently being assembled from the
    /// start-of-frame / start-of-line packet markers, all channels kept
    /// per line so complete frames can be exported.
    scanline_capture: Vec<[Vec<f32>; 8]>,
    /// Completed frame awaiting a (throttled) publish.
    pending_frame: Option<Vec<[Vec<f32>; 8]>>,
    scanline_dirty: bool,
    /// When the last start-of-frame marker arrived, for the FPS estimate.
    last_sof: Option<Instant>,
    /// Smoothed frame interval in seconds.
    frame_interval_ema: Option<f32>,
    /// Scope→GUI events deferred because the channel was full.
    gui_busy: u64,
    /// Samples discarded because a scanline hit MAX_SCANLINE_SAMPLES.
    line_overflow: u64,
    /// Frames force-split at MAX_SCANLINES (a missing start-of-frame).
    frame_overflow: u64,
    last_capture_publish: Option<Instant>,
    last_frame_publish: Option<Instant>,
    last_progress_publish: Option<Instant>,
}

impl Default for ScopeState {
    fn default() -> Self {
        Self {
            settings: ScopeSettings::default(),
            acquisition: Acquisition::Armed { continuous: true },
            capture: Default::default(),
            trigger_index: 0,
            pending_capture: None,
            history: Default::default(),
            prev_trigger_sample: None,
            frame_count: 0,
            last_trigger: None,
            scanline_capture: Vec::new(),
            pending_frame: None,
            scanline_dirty: false,
            last_sof: None,
            frame_interval_ema: None,
            gui_busy: 0,
            line_overflow: 0,
            frame_overflow: 0,
            last_capture_publish: None,
            last_frame_publish: None,
            last_progress_publish: None,
        }
    }
}

/// Builds the display trace for each scanline per the array source: one
/// channel, the average of the enabled channels, or the beamformed
/// envelope.
fn derive_display_lines(settings: &ScopeSettings, frame: &[[Vec<f32>; 8]]) -> Vec<Vec<f32>> {
    let mut planner = FftPlanner::<f32>::new();
    frame
        .iter()
        .enumerate()
        .map(|(i, line)| match (settings.array_source, settings.beamform) {
            (ArraySource::Channel(ch), _) => line[ch.min(7)].clone(),
            (ArraySource::Beamformed, Some(bf)) => {
                let theta = scanline_angle(bf.beam_width_deg, bf.num_scanlines, i);
                let origin = scanline_origin(bf.x_min, bf.x_max, bf.num_scanlines, i);
                beamform_scanline(line, &settings.channel_enabled, &bf, theta, origin, &mut planner)
            }
            (ArraySource::Average | ArraySource::Beamformed, _) => {
                let count = settings.channel_enabled.iter().filter(|&&e| e).count();
                let mut out = vec![0.0f32; line[0].len()];
                if count > 0 {
                    for ch in 0..8 {
                        if settings.channel_enabled[ch] {
                            for (acc, &s) in out.iter_mut().zip(&line[ch]) {
                                *acc += s;
                            }
                        }
                    }
                    let inv = 1.0 / count as f32;
                    for v in &mut out {
                        *v *= inv;
                    }
                }
                out
            }
        })
        .collect()
}

/// Delay-and-sum beamforms one scanline's RF data along the direction
/// `theta` from the beam origin (`origin_x`, 0) (averaging the enabled
/// channels, each with its calibrated receive polarity) and returns its
/// envelope. Output sample k is the point at range r_k = k · Δt · c / 2
/// along the beam (so the depth axis is the round-trip one the other
/// sources use); the transmit wave reaches it at t0 + r/c and the echo
/// reaches element j after a further |p - e_j| / c plus that channel's τ.
fn beamform_scanline(
    rf: &[Vec<f32>; 8],
    enabled: &[bool; 8],
    bf: &BeamformSettings,
    theta: f32,
    origin_x: f32,
    planner: &mut FftPlanner<f32>,
) -> Vec<f32> {
    let n = rf[0].len();
    let mut out = vec![0.0f32; n];
    if n < 2 {
        return out;
    }
    let (sin_t, cos_t) = theta.sin_cos();
    let fs = 1.0 / SAMPLE_PERIOD_S;
    let c = bf.c;
    let dr = SAMPLE_PERIOD_S * c / 2.0;
    let mut summed = 0usize;
    for j in 0..8 {
        if !enabled[j] || rf[j].len() < n {
            continue;
        }
        summed += 1;
        let ch = &rf[j];
        let sign = bf.sign[j];
        let fixed = (bf.t0_s + bf.tau[j]) * fs;
        for (k, acc) in out.iter_mut().enumerate() {
            let r = k as f32 * dr;
            let px = origin_x + r * sin_t - bf.x_el[j];
            let pz = r * cos_t - bf.z_el[j];
            let d_rx = (px * px + pz * pz).sqrt();
            let s = fixed + (r + d_rx) / c * fs;
            // linear interpolation, zero outside the record
            if s < 0.0 || s >= (n - 1) as f32 {
                continue;
            }
            let i = s as usize;
            let frac = s - i as f32;
            *acc += sign * (ch[i] + (ch[i + 1] - ch[i]) * frac);
        }
    }
    // scale like the average source so the b-mode brightness is comparable
    if summed > 1 {
        let inv = 1.0 / summed as f32;
        for v in &mut out {
            *v *= inv;
        }
    }
    envelope(&mut out, planner);
    out
}

/// Replaces `x` with the magnitude of its analytic signal (Hilbert
/// envelope), via the FFT.
fn envelope(x: &mut [f32], planner: &mut FftPlanner<f32>) {
    let n = x.len();
    if n < 2 {
        return;
    }
    let fft = planner.plan_fft_forward(n);
    let ifft = planner.plan_fft_inverse(n);
    let mut buf: Vec<Complex<f32>> = x.iter().map(|&v| Complex::new(v, 0.0)).collect();
    fft.process(&mut buf);
    // keep DC (and Nyquist for even n), double positive frequencies,
    // zero negative ones
    let half = n / 2;
    for (k, v) in buf.iter_mut().enumerate() {
        if k == 0 || (n % 2 == 0 && k == half) {
            continue;
        } else if k < half || (n % 2 == 1 && k == half) {
            *v *= 2.0;
        } else {
            *v = Complex::new(0.0, 0.0);
        }
    }
    ifft.process(&mut buf);
    let scale = 1.0 / n as f32;
    for (o, v) in x.iter_mut().zip(&buf) {
        *o = v.norm() * scale;
    }
}

impl ScopeState {
    fn apply(&mut self, command: ScopeCommand) {
        match command {
            ScopeCommand::Settings(settings) => {
                if settings.trigger_channel != self.settings.trigger_channel {
                    self.prev_trigger_sample = None;
                }
                if settings.x_scale != self.settings.x_scale {
                    for capture in &mut self.capture {
                        capture.truncate(settings.x_scale);
                    }
                    for history in &mut self.history {
                        let excess = history.len().saturating_sub(settings.x_scale);
                        history.drain(..excess);
                    }
                    self.settings.x_scale = settings.x_scale;
                    if let Acquisition::Capturing { continuous } = self.acquisition
                        && self.capture[0].len() >= settings.x_scale
                    {
                        self.complete_capture(continuous);
                    }
                }
                self.settings = settings;
            }
            ScopeCommand::Run(true) => self.acquisition = Acquisition::Armed { continuous: true },
            ScopeCommand::Run(false) => self.acquisition = Acquisition::Stopped,
            ScopeCommand::Single => self.acquisition = Acquisition::Armed { continuous: false },
        }
    }

    fn process(&mut self, packet: &DataPacket) {
        let n = packet.samples.len() / 8;
        if n == 0 {
            return;
        }
        let chan = |ch: usize| &packet.samples[ch * n..(ch + 1) * n];

        // pulsed-array assembly, driven by the packet markers and
        // independent of the scope's software trigger
        if packet.start_of_frame {
            let now = Instant::now();
            if let Some(prev) = self.last_sof.replace(now) {
                let dt = now.duration_since(prev).as_secs_f32();
                if dt > 2.0 {
                    // frames stalled; restart the estimate
                    self.frame_interval_ema = None;
                } else {
                    self.frame_interval_ema = Some(match self.frame_interval_ema {
                        Some(ema) => ema + (dt - ema) * 0.2,
                        None => dt,
                    });
                }
            }
            if !self.scanline_capture.is_empty() {
                self.pending_frame = Some(std::mem::take(&mut self.scanline_capture));
                self.scanline_dirty = false;
            }
        }
        if packet.start_of_frame || packet.start_of_line {
            if self.scanline_capture.len() >= pulser::MAX_SCANLINES {
                // a start-of-frame marker must have gone missing: split
                // here so the frame stays usable instead of the excess
                // piling into (and overflowing) the last line
                self.pending_frame = Some(std::mem::take(&mut self.scanline_capture));
                self.frame_overflow += 1;
            }
            self.scanline_capture.push(Default::default());
        }
        // samples arriving before the first start-of-line (a mid-line
        // join) are dropped
        if let Some(line) = self.scanline_capture.last_mut() {
            let take = n.min(MAX_SCANLINE_SAMPLES - line[0].len());
            self.line_overflow += (n - take) as u64;
            if take > 0 {
                for ch in 0..8 {
                    line[ch].extend_from_slice(&chan(ch)[..take]);
                }
                self.scanline_dirty = true;
            }
        }

        // software-trigger capture, in bulk segments instead of
        // per-sample: Armed scans for a trigger index, Capturing copies
        // slices until full (possibly re-arming within the same packet)
        let trigger_channel = self.settings.trigger_channel.min(7);
        let mut cursor = 0;
        while cursor < n {
            match self.acquisition {
                Acquisition::Stopped => break,
                Acquisition::Armed { continuous } => {
                    match self.find_trigger(chan(trigger_channel), cursor, packet.start_of_line) {
                        Some(t) => {
                            self.begin_capture(&packet.samples, n, t);
                            self.acquisition = Acquisition::Capturing { continuous };
                            self.last_trigger = Some(self.frame_count + t as u64);
                            cursor = t;
                        }
                        None => break,
                    }
                }
                Acquisition::Capturing { continuous } => {
                    let need = self.settings.x_scale.saturating_sub(self.capture[0].len());
                    let take = need.min(n - cursor);
                    for ch in 0..8 {
                        self.capture[ch].extend_from_slice(&chan(ch)[cursor..cursor + take]);
                    }
                    cursor += take;
                    if self.capture[0].len() >= self.settings.x_scale {
                        self.complete_capture(continuous);
                    }
                }
            }
        }

        // rolling pre-trigger history, only maintained while a trigger
        // position is set (it is only read at trigger time)
        if self.settings.trigger_position_pct > 0.0 {
            let cap = self.settings.x_scale;
            for ch in 0..8 {
                let history = &mut self.history[ch];
                history.extend(chan(ch));
                let excess = history.len().saturating_sub(cap);
                history.drain(..excess);
            }
        } else if !self.history[0].is_empty() {
            for history in &mut self.history {
                history.clear();
            }
        }

        self.prev_trigger_sample = Some(chan(trigger_channel)[n - 1]);
        self.frame_count += n as u64;
    }

    /// First frame index >= `cursor` where the trigger condition and
    /// holdoff are both met, tracking `prev_trigger_sample` semantics of
    /// the original per-sample loop.
    fn find_trigger(&self, trig: &[f32], cursor: usize, start_of_line: bool) -> Option<usize> {
        // holdoff: frames since the last trigger must reach the setting
        let earliest = match self.last_trigger {
            None => 0,
            Some(last) => {
                let ready_at = last + self.settings.holdoff_samples as u64;
                usize::try_from(ready_at.saturating_sub(self.frame_count)).ok()?
            }
        };
        match self.settings.trigger_mode {
            TriggerMode::Auto => {
                let t = cursor.max(earliest);
                (t < trig.len()).then_some(t)
            }
            // the marker applies to the packet's first sample
            TriggerMode::Line => (start_of_line && cursor == 0 && earliest == 0).then_some(0),
            TriggerMode::Normal => {
                let level = self.settings.trigger_level;
                let mut prev = if cursor == 0 {
                    self.prev_trigger_sample
                } else {
                    Some(trig[cursor - 1])
                };
                for (i, &sample) in trig.iter().enumerate().skip(cursor) {
                    if i >= earliest && prev.is_some_and(|p| p < level) && sample >= level {
                        return Some(i);
                    }
                    prev = Some(sample);
                }
                None
            }
        }
    }

    /// Starts a capture triggered at frame `t` of the current packet:
    /// clears the capture buffers and prepends pre-trigger samples (as
    /// many as are available) per the X trigger position, drawn from the
    /// packet's own prefix and then the history.
    fn begin_capture(&mut self, samples: &[f32], n: usize, t: usize) {
        let pre_target =
            (self.settings.trigger_position_pct / 100.0 * self.settings.x_scale as f32) as usize;
        let from_packet = t.min(pre_target);
        let from_history = pre_target - from_packet;
        for ch in 0..8 {
            let capture = &mut self.capture[ch];
            capture.clear();
            let history = &self.history[ch];
            let start = history.len().saturating_sub(from_history);
            capture.extend(history.range(start..));
            let channel = &samples[ch * n..(ch + 1) * n];
            capture.extend_from_slice(&channel[t - from_packet..t]);
        }
        self.trigger_index = self.capture[0].len();
    }

    /// Publishes the filled capture to the pending slot (recycling the
    /// previous unpublished buffers, if any) and re-arms or stops.
    fn complete_capture(&mut self, continuous: bool) {
        let mut traces = match self.pending_capture.take() {
            Some((mut old, _, _)) => {
                for trace in &mut old {
                    trace.clear();
                }
                old
            }
            None => Default::default(),
        };
        std::mem::swap(&mut traces, &mut self.capture);
        self.pending_capture = Some((traces, self.trigger_index, !continuous));
        self.acquisition = if continuous {
            Acquisition::Armed { continuous: true }
        } else {
            Acquisition::Stopped
        };
    }

    /// Sends pending results to the GUI, rate-limited so the GUI sees at
    /// most a few tens of events per second. Returns false when the GUI
    /// side has disconnected.
    fn publish(&mut self, output: &mut mpsc::Sender<ScopeEvent>) -> bool {
        fn due(last: Option<Instant>, period: Duration) -> bool {
            last.is_none_or(|t| t.elapsed() >= period)
        }

        if let Some((_, _, stopped)) = self.pending_capture
            && (stopped || due(self.last_capture_publish, CAPTURE_PUBLISH_PERIOD))
        {
            let (traces, trigger_index, stopped) = self.pending_capture.take().unwrap();
            match output.try_send(ScopeEvent::Capture {
                traces,
                trigger_index,
                stopped,
            }) {
                Ok(()) => self.last_capture_publish = Some(Instant::now()),
                Err(e) => {
                    if e.is_disconnected() {
                        return false;
                    }
                    // channel full: retry next round
                    self.gui_busy += 1;
                    if let ScopeEvent::Capture {
                        traces,
                        trigger_index,
                        stopped,
                    } = e.into_inner()
                    {
                        self.pending_capture = Some((traces, trigger_index, stopped));
                    }
                }
            }
        }

        if self.pending_frame.is_some() && due(self.last_frame_publish, FRAME_PUBLISH_PERIOD) {
            let channels = self.pending_frame.take().unwrap();
            match output.try_send(ScopeEvent::Scanlines {
                lines: derive_display_lines(&self.settings, &channels),
                channels: Some(channels),
                complete: true,
                fps: self.frame_interval_ema.map(|interval| 1.0 / interval),
            }) {
                Ok(()) => self.last_frame_publish = Some(Instant::now()),
                Err(e) => {
                    if e.is_disconnected() {
                        return false;
                    }
                    self.gui_busy += 1;
                    if let ScopeEvent::Scanlines {
                        channels: Some(channels),
                        ..
                    } = e.into_inner()
                    {
                        self.pending_frame = Some(channels);
                    }
                }
            }
        }

        // snapshot the frame being assembled so the GUI has something to
        // show before the first frame completes (or if markers stop)
        if self.scanline_dirty
            && self.pending_frame.is_none()
            && due(self.last_frame_publish, Duration::from_secs(2))
            && due(self.last_progress_publish, PROGRESS_PUBLISH_PERIOD)
        {
            // progress snapshots only fire when no frame has completed
            // for 2 s, so the frame rate is stale by definition
            let event = ScopeEvent::Scanlines {
                lines: derive_display_lines(&self.settings, &self.scanline_capture),
                channels: None,
                complete: false,
                fps: None,
            };
            match output.try_send(event) {
                Ok(()) => {
                    self.last_progress_publish = Some(Instant::now());
                    self.scanline_dirty = false;
                }
                Err(e) if e.is_disconnected() => return false,
                Err(_) => self.gui_busy += 1,
            }
        }

        true
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn delay_table_matches_delays_py() {
        // a plain 500 µm pitch line array, no offsets
        let mut calib = Calibration {
            x_el: [0.0; 8],
            z_el: [0.0; 8],
            tau: [0.0; 8],
            sign: [1.0; 8],
            t0: 0.0,
        };
        for (i, x) in calib.x_el.iter_mut().enumerate() {
            *x = i as f32 * 500e-6;
        }
        let app = App {
            calibration: Some(calib),
            beam_width_deg: 40.0,
            gen_scanlines: 64,
            focal_distance_mm: 30.0,
            speed_of_sound: 1540.0,
            ..App::default()
        };
        let (table, bf) = app.generate_delays().unwrap();
        assert_eq!(table.len(), 64);
        // from delays.py with 64 lines, 20 → -20°, 30 mm focus, c = 1540,
        // beam origins spread from 3.5 mm (line 0) to 0 (line 63)
        assert_eq!(table[0], [0, 22, 43, 64, 84, 103, 121, 139]);
        assert_eq!(table[31], [133, 136, 138, 139, 139, 139, 137, 135]);
        assert_eq!(table[63], [139, 121, 103, 84, 64, 43, 22, 0]);
        assert!((bf.t0_s - 139.0 / PULSER_CLK_HZ).abs() < 1e-8);
        assert!((scanline_angle(40.0, 64, 0) - 20f32.to_radians()).abs() < 1e-6);
        assert!((scanline_angle(40.0, 64, 63) + 20f32.to_radians()).abs() < 1e-6);
    }

    #[test]
    fn tau_fires_early_and_t0_includes_hardware_latency() {
        let mut calib = Calibration {
            x_el: [0.0; 8],
            z_el: [0.0; 8],
            tau: [0.0; 8],
            sign: [1.0; 8],
            t0: 1.5e-6,
        };
        // channel 3 is 320 ns (50 cycles) late: it must fire 50 cycles
        // before the others
        calib.tau[3] = 50.0 / PULSER_CLK_HZ;
        let app = App {
            calibration: Some(calib),
            beam_width_deg: 0.0,
            gen_scanlines: 1,
            focal_distance_mm: 30.0,
            use_tau: true,
            ..App::default()
        };
        let (table, bf) = app.generate_delays().unwrap();
        assert_eq!(table[0], [50, 50, 50, 0, 50, 50, 50, 50]);
        // the frame shifted by -50 cycles, so the on-time channels fire
        // at t0 + 50 cycles after the marker
        assert!((bf.t0_s - (1.5e-6 + 50.0 / PULSER_CLK_HZ)).abs() < 1e-9);
    }

    #[test]
    fn calibration_csv_round_trip() {
        let dir = std::env::temp_dir().join(format!("ultrasound-calib-{}", std::process::id()));
        std::fs::create_dir_all(&dir).unwrap();
        let path = dir.join("c.csv");
        let mut csv = String::from("# element calibration\n# t0_s=1.250000e-06\n# c_m_s=1482.0\n# x_m,z_m,tau_s,sign\n");
        for i in 0..8 {
            csv.push_str(&format!("{:e},{:e},{:e},{}\n", i as f32 * 1e-3, i as f32 * 1e-4, i as f32 * 1e-8, if i % 2 == 1 { -1 } else { 1 }));
        }
        std::fs::write(&path, csv).unwrap();
        let calib = load_calibration_csv(path.to_str().unwrap()).unwrap();
        assert!((calib.t0 - 1.25e-6).abs() < 1e-12);
        assert!((calib.x_el[7] - 7e-3).abs() < 1e-9);
        assert!((calib.z_el[7] - 7e-4).abs() < 1e-9);
        assert!((calib.tau[7] - 7e-8).abs() < 1e-14);
        assert_eq!(calib.sign, [1.0, -1.0, 1.0, -1.0, 1.0, -1.0, 1.0, -1.0]);
        std::fs::remove_dir_all(&dir).unwrap();
    }

    #[test]
    fn beamformer_aligns_point_echo() {
        // two elements 4 mm apart, one inverted and 200 ns late; a point
        // echo on the beam axis at 30 mm must sum coherently after
        // polarity/τ correction, and land at the 30 mm depth sample
        let c = 1482.0f32;
        let fs = 1.0 / SAMPLE_PERIOD_S;
        let bf = BeamformSettings {
            x_el: [0.0, 4e-3, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
            z_el: [0.0; 8],
            tau: [0.0, 200e-9, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
            sign: [1.0, -1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0],
            c,
            x_min: 0.0,
            x_max: 0.0,
            beam_width_deg: 0.0,
            num_scanlines: 1,
            t0_s: 2e-6,
        };
        let r = 30e-3f32;
        let n = 4096;
        let pulse = |t: f32| {
            let w = (t / 0.4e-6).powi(2);
            (-w).exp() * (2.0 * std::f32::consts::PI * 2e6 * t).cos()
        };
        let mut rf: [Vec<f32>; 8] = Default::default();
        for j in 0..2 {
            let d_rx = ((r - 0.0) * (r - 0.0) + bf.x_el[j] * bf.x_el[j]).sqrt();
            let arrival = bf.t0_s + bf.tau[j] + (r + d_rx) / c;
            rf[j] = (0..n)
                .map(|k| bf.sign[j] * pulse(k as f32 / fs - arrival))
                .collect();
        }
        for j in 2..8 {
            rf[j] = vec![0.0; n];
        }
        let enabled = [true, true, false, false, false, false, false, false];
        let mut planner = FftPlanner::<f32>::new();
        let out = beamform_scanline(&rf, &enabled, &bf, 0.0, 0.0, &mut planner);
        let peak = out
            .iter()
            .enumerate()
            .max_by(|a, b| a.1.total_cmp(b.1))
            .map(|(k, _)| k)
            .unwrap();
        let expected = (r / (SAMPLE_PERIOD_S * c / 2.0)).round() as usize;
        assert!((peak as i64 - expected as i64).abs() <= 2, "peak {peak} expected {expected}");
        // coherent: the two unit-amplitude echoes average to ~1
        assert!(out[peak] > 0.9, "peak amplitude {}", out[peak]);
    }

    #[test]
    fn sector_geometry_spreads_origins_across_aperture() {
        // 5 lines over an aperture 0..4 mm: origins at 4, 3, 2, 1, 0 mm
        // (line 0 is the +θ end), boundaries half a step beyond
        for i in 0..5 {
            let o = scanline_origin(0.0, 4e-3, 5, i);
            assert!((o - (4.0 - i as f32) * 1e-3).abs() < 1e-9, "{i}: {o}");
        }
        assert!((sector_boundary_x(0.0, 4e-3, 5, 0) - 4.5e-3).abs() < 1e-9);
        assert!((sector_boundary_x(0.0, 4e-3, 5, 5) + 0.5e-3).abs() < 1e-9);
        // boundary angles straddle the line angles
        for i in 0..5 {
            let mid = (sector_boundary_angle(40.0, 5, i) + sector_boundary_angle(40.0, 5, i + 1)) / 2.0;
            assert!((mid - scanline_angle(40.0, 5, i)).abs() < 1e-6);
        }
        // a single line starts at the aperture centre, bounded by its ends
        assert!((scanline_origin(0.0, 4e-3, 1, 0) - 2e-3).abs() < 1e-9);
        assert!((sector_boundary_x(0.0, 4e-3, 1, 0) - 4e-3).abs() < 1e-9);
        assert!((sector_boundary_x(0.0, 4e-3, 1, 1) - 0.0).abs() < 1e-9);
        assert!((sector_boundary_angle(40.0, 1, 0) - 20f32.to_radians()).abs() < 1e-6);
        assert!((sector_boundary_angle(40.0, 1, 1) + 20f32.to_radians()).abs() < 1e-6);
    }

    #[test]
    fn envelope_of_tone_is_flat() {
        let mut planner = FftPlanner::<f32>::new();
        let n = 1024;
        let mut x: Vec<f32> = (0..n)
            .map(|i| (2.0 * std::f32::consts::PI * 64.0 * i as f32 / n as f32).cos())
            .collect();
        envelope(&mut x, &mut planner);
        for v in &x {
            assert!((v - 1.0).abs() < 1e-3, "{v}");
        }
    }
}
