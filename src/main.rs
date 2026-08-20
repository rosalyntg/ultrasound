use std::collections::VecDeque;
use std::fmt::Write as _;
use std::io;
use std::num::NonZero;
use std::ops::RangeInclusive;
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
const HOLDOFF_RANGE: RangeInclusive<f32> = 0.0..=131_072.0; // samples
const TRIGGER_POSITION_RANGE: RangeInclusive<f32> = 0.0..=90.0; // % of window before the trigger
const X_SCALE_EXP_RANGE: RangeInclusive<f32> = 8.0..=16.0; // samples across = 2^exp
const Y_SCALE_RANGE: RangeInclusive<f32> = 16.0..=2048.0; // ± ADC codes
const Y_OFFSET_RANGE: RangeInclusive<f32> = -2048.0..=2047.0; // ADC codes
const CONTRAST_RANGE: RangeInclusive<f32> = 0.1..=10.0; // brightness gain
const DEPTH_GAIN_RANGE: RangeInclusive<f32> = 0.0..=60.0; // dB at the far edge
const NOTCH_FREQ_RANGE: RangeInclusive<f32> = 0.0..=25.0; // MHz, up to Nyquist
const IDLE_TIME_RANGE: RangeInclusive<f32> = 0.0..=5000.0; // µs after recv before the next scanline
const NUM_SCANLINES_RANGE: RangeInclusive<f32> = 1.0..=256.0;

const NUM_SAMPLES_PER_PACKET: usize = 80;

const PULSER_RECV_TIME_US: u32 = 1000;

/// Safety cap on samples accumulated per scanline if start-of-line
/// markers stop arriving.
const MAX_SCANLINE_SAMPLES: usize = 1 << 16;

const ADC_SAMPLE_RATE_HZ: f32 = 50e6;
const UDP_DECIMATION: f32 = 1.0;
const SAMPLE_PERIOD_S: f32 = UDP_DECIMATION / ADC_SAMPLE_RATE_HZ;

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
    pulsing: bool,
    adcs_enabled: bool,

    hv_plus_reading: Option<f32>,
    hv_minus_reading: Option<f32>,
    /// Setpoint limits, reported by the hardware task at connect;
    /// the setpoint controls are greyed out until then.
    hv_plus_range: Option<RangeInclusive<f32>>,
    hv_minus_range: Option<RangeInclusive<f32>>,
    ramp_rate_range: Option<RangeInclusive<f32>>, // µs

    status: String,
    hw: Option<mpsc::Sender<HwCommand>>,
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
    array_source: ArraySource,
    array_source_cb: combo_box::State<ArraySource>,
    idle_time_us: f32,  // wait after recv before the next scanline
    num_scanlines: u32, // scanlines per frame
    delay_csv_path: String,
    contrast: f32, // b-mode brightness gain
    /// Extra b-mode gain at the far edge (dB), ramping exponentially
    /// from 0 dB at the trigger point. Compensates depth attenuation.
    depth_gain_db: f32,
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
}

impl fmt::Display for ArraySource {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            ArraySource::Average => write!(f, "average"),
            ArraySource::Channel(ch) => write!(f, "ch{}", CHANNEL_NAMES[*ch]),
        }
    }
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
            pulsing: false,
            adcs_enabled: true,
            hv_plus_reading: None,
            hv_minus_reading: None,
            hv_plus_range: None,
            hv_minus_range: None,
            ramp_rate_range: None,
            status: String::from("starting..."),
            hw: None,
            scope: None,
            traces: Default::default(),
            filtered: Default::default(),
            notch_enabled: false,
            notch_low_mhz: 1.0,
            notch_high_mhz: 3.0,
            channel_enabled: [true; 8],
            acquisition: Acquisition::Armed { continuous: true },
            trigger_mode: TriggerMode::Auto,
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
            array_source: ArraySource::Average,
            array_source_cb: combo_box::State::new(
                std::iter::once(ArraySource::Average)
                    .chain((0..8).map(ArraySource::Channel))
                    .collect(),
            ),
            idle_time_us: 100.0,
            num_scanlines: 16,
            delay_csv_path: String::new(),
            contrast: 1.0,
            depth_gain_db: 0.0,
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
    AdcsEnabledToggled(bool),
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
    NumScanlinesChanged(f32),
    ApplyArrayConfig,
    DelayCsvPathChanged(String),
    LoadDelayCsv,
    ContrastChanged(f32),
    DepthGainChanged(f32),
    ChannelToggled(usize),
    NotchToggled(bool),
    NotchLowChanged(f32),
    NotchHighChanged(f32),
    SaveCsv,
    Hardware(HwEvent),
    Scope(ScopeEvent),
}

/// Events flowing from the hardware task to the GUI.
#[derive(Debug, Clone)]
enum HwEvent {
    Connected(mpsc::Sender<HwCommand>),
    Disconnected(String),
    Status(String),
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
}

impl Default for ScopeSettings {
    fn default() -> Self {
        // must match App::default so the thread behaves before the GUI's
        // first sync
        Self {
            trigger_mode: TriggerMode::Auto,
            trigger_channel: 0,
            trigger_level: 0.0,
            holdoff_samples: 0,
            trigger_position_pct: 0.0,
            x_scale: 4096,
            array_source: ArraySource::Average,
            channel_enabled: [true; 8],
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
    /// snapshot of the one being assembled.
    Scanlines {
        lines: Vec<Vec<f32>>,
        complete: bool,
    },
}

/// Pulser settings applied together via Pulser::setup.
#[derive(Debug, Clone, Copy)]
struct PulserConfig {
    duration_ns: f32,
    ramp_delay_us: f32,
}

/// Commands flowing from the GUI to the hardware task.
#[derive(Debug, Clone)]
enum HwCommand {
    SetRampRate(f32), // µs
    SetHvPlus(f32),   // V
    SetHvMinus(f32),  // V (magnitude)
    SetupPulser(PulserConfig),
    SetAdcsEnabled(bool), // false holds the ADC in reset
    InitHw,
    /// Arm and start; the pulser auto-restarts itself after the idle
    /// time until stopped.
    StartPulses(PulserConfig),
    StopPulses,
    SetupArray {
        idle_us: f32,
        num_scanlines: u32,
    },
    /// Per-channel delays (clock cycles), one row per scanline.
    LoadDelays(Vec<[u16; 8]>),
}

impl App {
    fn update(&mut self, message: Message) {
        match message {
            Message::RampRateChanged(v) => self.ramp_rate_us = v,
            Message::ApplyRampRate => {
                self.send(HwCommand::SetRampRate(self.ramp_rate_us));
            }
            Message::HvPlusSetpointChanged(v) => self.hv_plus_setpoint = v,
            Message::ApplyHvPlus => {
                self.send(HwCommand::SetHvPlus(self.hv_plus_setpoint));
            }
            Message::HvMinusSetpointChanged(v) => self.hv_minus_setpoint = v,
            Message::ApplyHvMinus => {
                self.send(HwCommand::SetHvMinus(self.hv_minus_setpoint));
            }
            Message::PulseDurationChanged(v) => self.pulse_duration_ns = v,
            Message::ApplyPulseDuration => {
                self.send(HwCommand::SetupPulser(self.pulser_config()));
            }
            Message::RampDelayChanged(v) => self.ramp_delay_us = v,
            Message::ApplyRampDelay => {
                self.send(HwCommand::SetupPulser(self.pulser_config()));
            }
            Message::AdcsEnabledToggled(enabled) => {
                self.adcs_enabled = enabled;
                self.send(HwCommand::SetAdcsEnabled(enabled));
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
            Message::IdleTimeChanged(v) => self.idle_time_us = v,
            Message::NumScanlinesChanged(v) => self.num_scanlines = v as u32,
            Message::ApplyArrayConfig => {
                self.send(HwCommand::SetupArray {
                    idle_us: self.idle_time_us,
                    num_scanlines: self.num_scanlines,
                });
            }
            Message::DelayCsvPathChanged(path) => self.delay_csv_path = path,
            Message::LoadDelayCsv => match load_delay_csv(&self.delay_csv_path) {
                Ok(table) => {
                    let n = table.len();
                    self.send(HwCommand::LoadDelays(table));
                    self.status = format!("loaded delay table: {n} scanlines");
                }
                Err(e) => self.status = format!("delay csv: {e}"),
            },
            Message::ContrastChanged(contrast) => {
                self.contrast = contrast;
                self.bmode_cache.clear();
            }
            Message::DepthGainChanged(gain_db) => {
                self.depth_gain_db = gain_db;
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
            Message::Hardware(event) => match event {
                HwEvent::Connected(commands) => {
                    self.hw = Some(commands);
                    self.status = String::from("connected");
                }
                HwEvent::Disconnected(reason) => {
                    self.hw = None;
                    self.hv_plus_reading = None;
                    self.hv_minus_reading = None;
                    self.hv_plus_range = None;
                    self.hv_minus_range = None;
                    self.ramp_rate_range = None;
                    self.pulsing = false;
                    self.status = format!("disconnected: {reason}");
                }
                HwEvent::Status(status) => self.status = status,
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
                ScopeEvent::Scanlines { lines, complete } => {
                    if complete {
                        self.scanlines = lines;
                        self.scanline_capture.clear();
                    } else {
                        self.scanline_capture = lines;
                    }
                    if self.bmode_mode == BModeMode::PulsedArray {
                        self.bmode_cache.clear();
                    }
                }
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

    /// The traces currently on screen and their trigger index.
    fn shown(&self) -> (&[Vec<f32>; 8], usize) {
        let traces = if self.notch_enabled {
            &self.filtered
        } else {
            &self.traces
        };
        (traces, self.display_trigger_index)
    }

    /// Writes the traces currently on screen (filtered, if the notch is
    /// enabled) to a timestamped CSV in the working directory.
    fn save_csv(&self) -> Result<String, io::Error> {
        let (shown, trigger_index) = self.shown();
        let rows = shown.iter().map(Vec::len).max().unwrap_or(0);
        if rows == 0 {
            return Err(io::Error::other("no data on screen"));
        }

        let mut csv = String::from("time_us,chA,chB,chC,chD\n");
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

    fn pulser_config(&self) -> PulserConfig {
        PulserConfig {
            duration_ns: self.pulse_duration_ns,
            ramp_delay_us: self.ramp_delay_us,
        }
    }

    fn send(&mut self, command: HwCommand) {
        match &mut self.hw {
            Some(tx) => {
                if tx.try_send(command).is_err() {
                    self.status = String::from("hardware task busy, command dropped");
                }
            }
            None => self.status = String::from("not connected, command ignored"),
        }
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
                text(format!("{:.1} µs", self.ramp_rate_us)).size(14),
                slider(range.clone(), self.ramp_rate_us, Message::RampRateChanged)
                    .step(0.5)
                    .on_release(Message::ApplyRampRate),
            ]
            .spacing(5)
            .into(),
            None => Element::from(text("waiting for hardware...").size(13)),
        };
        let ramp_section = column![text("Ramp rate").size(16), ramp_control].spacing(5);

        // setpoint controls are greyed out until the hardware task reports
        // the supply's range and current target
        let hv_setpoint = |range: &Option<RangeInclusive<f32>>,
                           setpoint: f32,
                           on_change: fn(f32) -> Message,
                           on_apply: Message| {
            match range {
                Some(range) => column![
                    text(format!("setpoint: {setpoint:.1} V",)).size(14),
                    slider(range.clone(), setpoint, on_change)
                        .step(1.0)
                        .on_release(on_apply),
                ]
                .spacing(5)
                .into(),
                None => Element::from(text("setpoint: waiting for hardware...").size(13)),
            }
        };

        let hv_plus_section = column![
            text("HV+").size(16),
            text(format!("measured: {}", fmt_voltage(self.hv_plus_reading))).size(14),
            hv_setpoint(
                &self.hv_plus_range,
                self.hv_plus_setpoint,
                Message::HvPlusSetpointChanged,
                Message::ApplyHvPlus,
            ),
        ]
        .spacing(5);

        let hv_minus_section = column![
            text("HV−").size(16),
            text(format!("measured: {}", fmt_voltage(self.hv_minus_reading))).size(14),
            hv_setpoint(
                &self.hv_minus_range,
                self.hv_minus_setpoint,
                Message::HvMinusSetpointChanged,
                Message::ApplyHvMinus,
            ),
        ]
        .spacing(5);

        let pulse_section = column![
            text("Pulse duration").size(16),
            text(format!(
                "{:.0} ns ({:.2} MHz)",
                self.pulse_duration_ns,
                1000.0 / self.pulse_duration_ns
            ))
            .size(14),
            slider(
                PULSE_DURATION_RANGE,
                self.pulse_duration_ns,
                Message::PulseDurationChanged
            )
            .step(25.0)
            .on_release(Message::ApplyPulseDuration),
            text(format!("ramp delay: {:.0} µs", self.ramp_delay_us)).size(14),
            slider(
                RAMP_DELAY_RANGE,
                self.ramp_delay_us,
                Message::RampDelayChanged
            )
            .step(1.0)
            .on_release(Message::ApplyRampDelay),
            button(if self.pulsing {
                "stop pulsing"
            } else {
                "start pulsing"
            })
            .on_press_maybe(connected.then_some(Message::PulsingToggled)),
        ]
        .spacing(5);

        let running = !matches!(self.acquisition, Acquisition::Stopped);
        let scope_section = column![
            text("Scope").size(16),
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
        ]
        .spacing(5);

        let adc_section = column![
            text("ADCs").size(16),
            toggler(self.adcs_enabled)
                .label(if self.adcs_enabled {
                    "enabled"
                } else {
                    "disabled (in reset)"
                })
                .on_toggle(Message::AdcsEnabledToggled),
        ]
        .spacing(5);

        let x_scale_section = column![
            text("X scale").size(16),
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
        ]
        .spacing(5);

        let y_axis_section = column![
            text("Y axis").size(16),
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

        let notch_section = column![
            text("Notch filter").size(16),
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

        let array_section = column![
            text("Pulsed array").size(16),
            text(format!("idle time: {:.0} µs", self.idle_time_us)).size(14),
            slider(IDLE_TIME_RANGE, self.idle_time_us, Message::IdleTimeChanged)
                .step(10.0)
                .on_release(Message::ApplyArrayConfig),
            text(format!("scanlines per frame: {}", self.num_scanlines)).size(14),
            slider(
                NUM_SCANLINES_RANGE,
                self.num_scanlines as f32,
                Message::NumScanlinesChanged
            )
            .step(1.0)
            .on_release(Message::ApplyArrayConfig),
            text("delay table csv").size(14),
            text_input("path/to/delays.csv", &self.delay_csv_path)
                .on_input(Message::DelayCsvPathChanged)
                .on_submit(Message::LoadDelayCsv)
                .size(13),
            button("load delays").on_press_maybe(connected.then_some(Message::LoadDelayCsv)),
        ]
        .spacing(5);

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
            text(format!("depth gain: {:.0} dB", self.depth_gain_db)).size(14),
            slider(
                DEPTH_GAIN_RANGE,
                self.depth_gain_db,
                Message::DepthGainChanged
            )
            .step(1.0),
        ]
        .spacing(5);

        let sidebar = container(scrollable(
            column![
                text("Ultrasound").size(24),
                status_section,
                ramp_section,
                hv_plus_section,
                hv_minus_section,
                pulse_section,
                array_section,
                scope_section,
                adc_section,
                x_scale_section,
                y_axis_section,
                notch_section,
                bmode_section,
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
                    contrast: self.contrast,
                    depth_gain_db: self.depth_gain_db,
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
                    depth_gain_db: self.depth_gain_db,
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
    /// Extra gain at the bottom edge (dB), exponential ramp from the top.
    depth_gain_db: f32,
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

                    // time-gain compensation: exponential gain ramp with
                    // depth, 0 dB at the trigger up to depth_gain_db at
                    // the bottom edge
                    let depth = row as f32 / rows as f32;
                    let depth_gain = 10.0f32.powf(self.depth_gain_db * depth / 20.0);

                    let brightness = (peak / 2048.0 * self.contrast * depth_gain).clamp(0.0, 1.0);
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
            frame.fill_text(label(String::from("0"), area.y));
            frame.fill_text(label(
                fmt_samples_as_time(span / 2),
                area.y + area.height / 2.0,
            ));
            frame.fill_text(label(fmt_samples_as_time(span), area.y + area.height));
        });

        vec![geometry]
    }
}

/// Traditional pulsed-array ultrasound view: one column per scanline,
/// beamformed amplitude as brightness vs depth (top = start of line).
struct ArrayPlot<'a> {
    scanlines: &'a [Vec<f32>],
    contrast: f32,
    /// Extra gain at the bottom edge (dB), exponential ramp from the top.
    depth_gain_db: f32,
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

            let column_width = area.width / self.scanlines.len() as f32;
            let rows = area.height as usize;

            for (i, line) in self.scanlines.iter().enumerate() {
                let column_x = area.x + i as f32 * column_width;

                // merge consecutive rows of equal brightness into one
                // rectangle to keep the geometry count down
                let mut run_start = 0usize;
                let mut run_level = 0u32; // quantized brightness, 0 = skip
                for row in 0..=rows {
                    let level = if row < rows {
                        // samples covered by this pixel row (peak-detect)
                        let s0 = (row as f32 / rows as f32 * span as f32) as usize;
                        let s1 = ((row + 1) as f32 / rows as f32 * span as f32).max(s0 as f32 + 1.0)
                            as usize;

                        let peak = line
                            .get(s0..s1.min(line.len()))
                            .unwrap_or(&[])
                            .iter()
                            .fold(0.0f32, |max, &v| max.max(v.abs()));

                        // time-gain compensation, as in the raw view
                        let depth = row as f32 / rows as f32;
                        let depth_gain = 10.0f32.powf(self.depth_gain_db * depth / 20.0);

                        let brightness =
                            (peak / 2048.0 * self.contrast * depth_gain).clamp(0.0, 1.0);
                        (brightness * 255.0).round() as u32
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

            // scanline count, top-left
            frame.fill_text(canvas::Text {
                content: format!("{} scanlines", self.scanlines.len()),
                position: Point::new(area.x + 5.0, area.y + 5.0),
                color: palette.background.strong.color,
                size: 12.0.into(),
                ..canvas::Text::default()
            });

            // depth (time-from-line-start) labels
            let label = |content: String, y: f32| canvas::Text {
                content,
                position: Point::new(area.x - 5.0, y),
                color: palette.background.base.text,
                size: 12.0.into(),
                align_x: text::Alignment::Right,
                align_y: alignment::Vertical::Center,
                ..canvas::Text::default()
            };
            frame.fill_text(label(String::from("0"), area.y));
            frame.fill_text(label(
                fmt_samples_as_time(span / 2),
                area.y + area.height / 2.0,
            ));
            frame.fill_text(label(fmt_samples_as_time(span), area.y + area.height));
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
            PULSER_RECV_TIME_US,
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
    // deep enough to ride out scheduling hiccups on the scope thread
    // (~30 ms of packets at full stream rate)
    let (packet_tx, packet_rx) = std_mpsc::sync_channel(16384);
    let (command_tx, command_rx) = std_mpsc::channel();

    let _ = gui_tx.try_send(ScopeEvent::Ready(command_tx));

    let _ = std::thread::Builder::new().name(String::from("ingest")).spawn(move || {
        if let Err(e) = hardware_data_session(packet_tx) {
            println!("data session closed: {e}");
        }
    });
    let _ = std::thread::Builder::new()
        .name(String::from("scope"))
        .spawn(move || scope_session(packet_rx, command_rx, gui_tx));

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
                            "pulser set: {:.0} ns, ramp delay {:.0} µs",
                            config.duration_ns, config.ramp_delay_us
                        )
                    }
                    HwCommand::SetAdcsEnabled(enabled) => {
                        // if enabled {
                        //     u.adc_reset.clear(&mut u.interface).await?;
                        //     String::from("ADCs enabled (reset released, may need re-init)")
                        // } else {
                        //     u.adc_reset.set(&mut u.interface).await?;
                        //     String::from("ADCs held in reset")
                        // }
                        "ADCs enabled/disabled not implemented".to_string()
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
                    HwCommand::SetupArray { idle_us, num_scanlines } => {
                        u.pulser.set_idle_time(&mut u.interface, idle_us).await?;
                        u.pulser
                            .set_num_scanlines(&mut u.interface, num_scanlines)
                            .await?;
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

fn hardware_data_session(output: std_mpsc::SyncSender<DataPacket>) -> Result<(), io::Error> {
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
                        if last_drop_report.elapsed() >= Duration::from_secs(1) {
                            println!("Error receiving data ({recv_errors}x): {e}");
                            recv_errors = 0;
                            last_drop_report = Instant::now();
                        }
                        continue;
                    }
                };

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
                    Err(std_mpsc::TrySendError::Full(_)) => dropped += 1,
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
) {
    let mut scope = ScopeState::default();
    while let Ok(first) = packets.recv() {
        for command in commands.try_iter() {
            scope.apply(command);
        }
        scope.process(&first);
        // drain whatever else is already queued before publishing
        for packet in packets.try_iter().take(512) {
            scope.process(&packet);
        }
        if !scope.publish(&mut output) {
            return; // GUI is gone
        }
    }
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
    /// start-of-frame / start-of-line packet markers.
    scanline_capture: Vec<Vec<f32>>,
    /// Completed frame awaiting a (throttled) publish.
    pending_frame: Option<Vec<Vec<f32>>>,
    scanline_dirty: bool,
    avg_scratch: Vec<f32>,
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
            avg_scratch: Vec::new(),
            last_capture_publish: None,
            last_frame_publish: None,
            last_progress_publish: None,
        }
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
        if packet.start_of_frame && !self.scanline_capture.is_empty() {
            self.pending_frame = Some(std::mem::take(&mut self.scanline_capture));
            self.scanline_dirty = false;
        }
        if (packet.start_of_frame || packet.start_of_line)
            && self.scanline_capture.len() < pulser::MAX_SCANLINES
        {
            self.scanline_capture.push(Vec::new());
        }
        // samples arriving before the first start-of-line (a mid-line
        // join) are dropped
        if let Some(line) = self.scanline_capture.last_mut() {
            let take = n.min(MAX_SCANLINE_SAMPLES - line.len());
            if take > 0 {
                match self.settings.array_source {
                    ArraySource::Channel(ch) => line.extend_from_slice(&chan(ch)[..take]),
                    ArraySource::Average => {
                        let enabled = self.settings.channel_enabled;
                        let count = enabled.iter().filter(|&&e| e).count();
                        if count > 0 {
                            self.avg_scratch.clear();
                            self.avg_scratch.resize(take, 0.0);
                            for ch in 0..8 {
                                if enabled[ch] {
                                    for (acc, &s) in self.avg_scratch.iter_mut().zip(chan(ch)) {
                                        *acc += s;
                                    }
                                }
                            }
                            let inv = 1.0 / count as f32;
                            line.extend(self.avg_scratch.iter().map(|&s| s * inv));
                        }
                    }
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
            let lines = self.pending_frame.take().unwrap();
            match output.try_send(ScopeEvent::Scanlines {
                lines,
                complete: true,
            }) {
                Ok(()) => self.last_frame_publish = Some(Instant::now()),
                Err(e) => {
                    if e.is_disconnected() {
                        return false;
                    }
                    if let ScopeEvent::Scanlines { lines, .. } = e.into_inner() {
                        self.pending_frame = Some(lines);
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
            let event = ScopeEvent::Scanlines {
                lines: self.scanline_capture.clone(),
                complete: false,
            };
            match output.try_send(event) {
                Ok(()) => {
                    self.last_progress_publish = Some(Instant::now());
                    self.scanline_dirty = false;
                }
                Err(e) if e.is_disconnected() => return false,
                Err(_) => (),
            }
        }

        true
    }
}
