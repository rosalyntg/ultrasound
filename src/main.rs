use std::collections::VecDeque;
use std::env;
use std::fmt::Write as _;
use std::io;
use std::ops::RangeInclusive;
use std::time::{Duration, SystemTime, UNIX_EPOCH};

use rustfft::FftPlanner;
use rustfft::num_complex::Complex;

use iced::alignment;
use iced::futures::channel::mpsc;
use iced::futures::{SinkExt, Stream, StreamExt};
use iced::mouse;
use iced::widget::{
    button, canvas, column, container, radio, row, scrollable, slider, text, text_input, toggler,
};
use iced::{Center, Color, Element, Fill, Point, Rectangle, Renderer, Size, Subscription, Theme};

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
const PULSE_RATE_RANGE: RangeInclusive<f32> = 1.0..=50.0; // Hz
const RAMP_DELAY_RANGE: RangeInclusive<f32> = 0.0..=200.0; // µs
const HOLDOFF_RANGE: RangeInclusive<f32> = 0.0..=131_072.0; // samples
const TRIGGER_POSITION_RANGE: RangeInclusive<f32> = 0.0..=90.0; // % of window before the trigger
const X_SCALE_EXP_RANGE: RangeInclusive<f32> = 8.0..=16.0; // samples across = 2^exp
const Y_SCALE_RANGE: RangeInclusive<f32> = 16.0..=2048.0; // ± ADC codes
const Y_OFFSET_RANGE: RangeInclusive<f32> = -2048.0..=2047.0; // ADC codes
const CONTRAST_RANGE: RangeInclusive<f32> = 0.1..=10.0; // brightness gain
const DEPTH_GAIN_RANGE: RangeInclusive<f32> = 0.0..=60.0; // dB at the far edge
const NOTCH_FREQ_RANGE: RangeInclusive<f32> = 0.0..=25.0; // MHz, up to Nyquist

const PULSER_RECV_TIME_US: u32 = 1000;

const ADC_SAMPLE_RATE_HZ: f32 = 50e6;
const UDP_DECIMATION: f32 = 1.0;
const SAMPLE_PERIOD_S: f32 = UDP_DECIMATION / ADC_SAMPLE_RATE_HZ;

const HV_POLL_PERIOD: Duration = Duration::from_secs(1);
const RECONNECT_DELAY: Duration = Duration::from_secs(3);

pub fn main() -> iced::Result {
    tracing_subscriber::fmt::init();

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
    pulse_rate_hz: f32,
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

    /// Last completed capture — what the plot shows.
    traces: [Vec<f32>; 4],
    /// Notch-filtered copy of `traces`, shown instead when the notch
    /// filter is enabled. Display-only: the trigger sees raw data.
    filtered: [Vec<f32>; 4],
    notch_enabled: bool,
    notch_low_mhz: f32,
    notch_high_mhz: f32,
    /// Capture currently being filled; swapped into `traces` when complete.
    capture: [Vec<f32>; 4],
    channel_enabled: [bool; 4],
    acquisition: Acquisition,
    trigger_mode: TriggerMode,
    trigger_channel: usize,
    trigger_level: f32, // ADC codes
    trigger_level_text: String,
    holdoff_samples: usize,
    samples_since_trigger: usize,
    prev_trigger_sample: Option<f32>,
    trigger_position_pct: f32, // portion of the window shown before the trigger
    /// Rolling pre-trigger history, capped at `x_scale` samples.
    history: [VecDeque<f32>; 4],
    /// Where the trigger landed in the capture being filled.
    trigger_index: usize,
    /// Where the trigger landed in the displayed capture.
    display_trigger_index: usize,
    x_scale: usize, // samples across the plot, power of two
    y_auto: bool,
    y_scale: f32,  // ± ADC codes around the offset
    y_offset: f32, // center, ADC codes
    view_tab: ViewTab,
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

/// How an armed acquisition starts a capture.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum TriggerMode {
    /// Capture immediately — continuously scrolling data.
    Auto,
    /// Wait for the trigger channel to cross the trigger level upward.
    Normal,
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

impl Default for App {
    fn default() -> Self {
        Self {
            ramp_rate_us: 46.0,
            hv_plus_setpoint: 0.0,
            hv_minus_setpoint: 0.0,
            pulse_duration_ns: 500.0, // 2 MHz
            pulse_rate_hz: 5.0,
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
            traces: Default::default(),
            filtered: Default::default(),
            notch_enabled: false,
            notch_low_mhz: 1.0,
            notch_high_mhz: 3.0,
            capture: Default::default(),
            channel_enabled: [true; 4],
            acquisition: Acquisition::Armed { continuous: true },
            trigger_mode: TriggerMode::Auto,
            trigger_channel: 0,
            trigger_level: 0.0,
            trigger_level_text: String::from("0"),
            holdoff_samples: 0,
            // don't block the very first trigger
            samples_since_trigger: usize::MAX / 2,
            prev_trigger_sample: None,
            trigger_position_pct: 0.0,
            history: Default::default(),
            trigger_index: 0,
            display_trigger_index: 0,
            x_scale: 4096,
            y_auto: true,
            y_scale: 2048.0,
            y_offset: 0.0,
            view_tab: ViewTab::Scope,
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
    SendPulse,
    PulseRateChanged(f32),
    ApplyPulseRate,
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
    ContrastChanged(f32),
    DepthGainChanged(f32),
    ChannelToggled(usize),
    NotchToggled(bool),
    NotchLowChanged(f32),
    NotchHighChanged(f32),
    SaveCsv,
    Hardware(HwEvent),
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
    RampRateInfo { min_us: f32, max_us: f32 },
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
    /// ADC frames, one sample per channel
    Frames(Vec<[f32; 4]>),
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
    SendPulse(PulserConfig),
    StartPulses { config: PulserConfig, rate_hz: f32 },
    StopPulses,
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
            Message::SendPulse => {
                self.send(HwCommand::SendPulse(self.pulser_config()));
            }
            Message::PulseRateChanged(rate) => self.pulse_rate_hz = rate,
            Message::ApplyPulseRate => {
                if self.pulsing {
                    self.send(HwCommand::StartPulses {
                        config: self.pulser_config(),
                        rate_hz: self.pulse_rate_hz,
                    });
                }
            }
            Message::PulsingToggled => {
                self.pulsing = !self.pulsing;
                if self.pulsing {
                    self.send(HwCommand::StartPulses {
                        config: self.pulser_config(),
                        rate_hz: self.pulse_rate_hz,
                    });
                } else {
                    self.send(HwCommand::StopPulses);
                }
            }
            Message::RunToggled => {
                self.acquisition = match self.acquisition {
                    Acquisition::Stopped => Acquisition::Armed { continuous: true },
                    _ => Acquisition::Stopped,
                };
            }
            Message::SingleShot => {
                self.acquisition = Acquisition::Armed { continuous: false };
            }
            Message::TriggerModeSelected(mode) => {
                self.trigger_mode = mode;
            }
            Message::TriggerChannelSelected(ch) => {
                self.trigger_channel = ch;
                self.prev_trigger_sample = None;
                self.plot_cache.clear();
                self.bmode_cache.clear();
            }
            Message::TriggerLevelChanged(level) => {
                self.trigger_level = level;
                self.trigger_level_text = format!("{level:.0}");
                self.plot_cache.clear();
                self.bmode_cache.clear();
            }
            Message::TriggerLevelInputChanged(input) => {
                if let Ok(level) = input.trim().parse::<f32>() {
                    self.trigger_level = level.clamp(-2048.0, 2047.0);
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
            }
            Message::TriggerPositionChanged(pct) => {
                self.trigger_position_pct = pct;
            }
            Message::XScaleChanged(exp) => {
                self.x_scale = 1 << exp as u32;
                for trace in &mut self.traces {
                    trace.truncate(self.x_scale);
                }
                for capture in &mut self.capture {
                    capture.truncate(self.x_scale);
                }
                for history in &mut self.history {
                    while history.len() > self.x_scale {
                        history.pop_front();
                    }
                }
                if let Acquisition::Capturing { continuous } = self.acquisition {
                    if self.capture[0].len() >= self.x_scale {
                        std::mem::swap(&mut self.traces, &mut self.capture);
                        self.display_trigger_index = self.trigger_index;

                        self.acquisition = if continuous {
                            Acquisition::Armed { continuous: true }
                        } else {
                            Acquisition::Stopped
                        };
                    }
                }
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
                HwEvent::Frames(frames) => {
                    let mut changed = false;
                    let mut completed = false;

                    for frame in frames {
                        let sample = frame[self.trigger_channel];

                        match self.acquisition {
                            Acquisition::Stopped => {}
                            Acquisition::Armed { continuous } => {
                                let triggered = (self.trigger_mode == TriggerMode::Auto
                                    || self.prev_trigger_sample.is_some_and(|prev| {
                                        prev < self.trigger_level && sample >= self.trigger_level
                                    }))
                                    && self.samples_since_trigger >= self.holdoff_samples;

                                if triggered {
                                    // prepend pre-trigger history (as much as
                                    // is available) per the X trigger position
                                    let pre_target = (self.trigger_position_pct / 100.0
                                        * self.x_scale as f32)
                                        as usize;

                                    for (capture, (history, sample)) in
                                        self.capture.iter_mut().zip(self.history.iter().zip(frame))
                                    {
                                        capture.clear();
                                        let start = history.len().saturating_sub(pre_target);
                                        capture.extend(history.iter().skip(start));
                                        capture.push(sample);
                                    }
                                    self.trigger_index = self.capture[0].len() - 1;

                                    self.acquisition = Acquisition::Capturing { continuous };
                                    self.samples_since_trigger = 0;
                                    changed = true;
                                }
                            }
                            Acquisition::Capturing { continuous } => {
                                for (capture, sample) in self.capture.iter_mut().zip(frame) {
                                    capture.push(sample);
                                }
                                changed = true;

                                if self.capture[0].len() >= self.x_scale {
                                    // completed: publish to the display buffer
                                    // (swap keeps the allocations around)
                                    std::mem::swap(&mut self.traces, &mut self.capture);
                                    self.display_trigger_index = self.trigger_index;
                                    completed = true;

                                    self.acquisition = if continuous {
                                        Acquisition::Armed { continuous: true }
                                    } else {
                                        Acquisition::Stopped
                                    };
                                }
                            }
                        }

                        // rolling pre-trigger history, updated after the
                        // state machine so it never contains the current frame
                        // at trigger time
                        for (history, sample) in self.history.iter_mut().zip(frame) {
                            history.push_back(sample);
                            while history.len() > self.x_scale {
                                history.pop_front();
                            }
                        }

                        self.prev_trigger_sample = Some(sample);
                        self.samples_since_trigger = self.samples_since_trigger.saturating_add(1);
                    }

                    if completed {
                        self.apply_notch();
                    }
                    if changed {
                        self.plot_cache.clear();
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

            let mut buf: Vec<Complex<f32>> =
                trace.iter().map(|&y| Complex::new(y, 0.0)).collect();
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

    /// The traces currently on screen and their trigger index.
    fn shown(&self) -> (&[Vec<f32>; 4], usize) {
        if self.traces.iter().any(|t| !t.is_empty()) {
            let traces = if self.notch_enabled {
                &self.filtered
            } else {
                &self.traces
            };
            (traces, self.display_trigger_index)
        } else {
            // before the first capture completes, show the one in progress
            (&self.capture, self.trigger_index)
        }
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

    fn subscription(&self) -> Subscription<Message> {
        Subscription::run(hardware_worker).map(Message::Hardware)
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
            text(format!("rate: {:.0} Hz", self.pulse_rate_hz)).size(14),
            slider(
                PULSE_RATE_RANGE,
                self.pulse_rate_hz,
                Message::PulseRateChanged
            )
            .step(1.0)
            .on_release(Message::ApplyPulseRate),
            row![
                button("send pulse").on_press_maybe(connected.then_some(Message::SendPulse)),
                button(if self.pulsing {
                    "stop pulsing"
                } else {
                    "start pulsing"
                })
                .on_press_maybe(connected.then_some(Message::PulsingToggled)),
            ]
            .spacing(10),
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
            ]
            .spacing(10),
            text("trigger channel").size(14),
            row((0..4).map(|ch| {
                radio(
                    CHANNEL_NAMES[ch],
                    ch,
                    Some(self.trigger_channel),
                    Message::TriggerChannelSelected,
                )
                .size(16)
                .into()
            }))
            .spacing(10),
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

        let bmode_section = column![
            text("B-mode").size(16),
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
        let fill = if matches!(self.acquisition, Acquisition::Capturing { .. }) {
            self.capture[0].len()
        } else {
            0
        };

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
            ViewTab::BMode => canvas(BModePlot {
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
    traces: &'a [Vec<f32>; 4],
    enabled: [bool; 4],
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

const CHANNEL_NAMES: [&str; 4] = ["A", "B", "C", "D"];

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
            for ch in 0..4 {
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
            if (0..4).any(|ch| legend_rect(ch).contains(position)) {
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
    traces: &'a [Vec<f32>; 4],
    enabled: [bool; 4],
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

            let channel_colors = [
                palette.primary.base.color,
                palette.success.base.color,
                palette.warning.base.color,
                palette.danger.base.color,
            ];

            // depth axis: trigger point at the top, X scale end at the bottom
            let start = self.trigger_index.min(self.x_scale.saturating_sub(1));
            let span = (self.x_scale - start).max(1);

            let channels: Vec<usize> = (0..4).filter(|&ch| self.enabled[ch]).collect();
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

                    let brightness =
                        (peak / 2048.0 * self.contrast * depth_gain).clamp(0.0, 1.0);
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

fn hardware_worker() -> impl Stream<Item = HwEvent> {
    iced::stream::channel(100, async move |mut output| {
        loop {
            let reason = match hardware_session(&mut output).await {
                Ok(()) => String::from("command channel closed"),
                Err(e) => e.to_string(),
            };
            let _ = output.send(HwEvent::Disconnected(reason)).await;

            tokio::time::sleep(RECONNECT_DELAY).await;
        }
    })
}

/// Connects to the board and services GUI commands until an I/O error
/// occurs.
async fn hardware_session(output: &mut mpsc::Sender<HwEvent>) -> Result<(), io::Error> {
    let _ = output
        .send(HwEvent::Status(String::from("connecting...")))
        .await;

    let data_socket = Ultrasound::bind_data_socket().await?;
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
    let mut data_buf = [0u8; 2048];

    let mut pulsing = false;
    let mut pulse_timer = tokio::time::interval(Duration::from_secs(1));

    loop {
        tokio::select! {
            _ = pulse_timer.tick(), if pulsing => {
                u.pulser.start(&mut u.interface).await?;
            }

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
                        if enabled {
                            u.adc_reset.clear(&mut u.interface).await?;
                            String::from("ADCs enabled (reset released, may need re-init)")
                        } else {
                            u.adc_reset.set(&mut u.interface).await?;
                            String::from("ADCs held in reset")
                        }
                    }
                    HwCommand::InitHw => {
                        let _ = output
                            .send(HwEvent::Status(String::from("initializing hardware...")))
                            .await;

                        u.init_hw().await?;

                        String::from("hardware initialized (clk + ADC + PHY reset)")
                    }
                    HwCommand::SendPulse(config) => {
                        setup_pulser(&mut u, config).await?;
                        u.pulser.arm(&mut u.interface).await?;
                        u.pulser.start(&mut u.interface).await?;
                        format!("pulse sent ({:.0} ns)", config.duration_ns)
                    }
                    HwCommand::StartPulses { config, rate_hz } => {
                        setup_pulser(&mut u, config).await?;
                        u.pulser.arm(&mut u.interface).await?;

                        let rate_hz = rate_hz.max(0.1);
                        pulse_timer = tokio::time::interval(Duration::from_secs_f32(1.0 / rate_hz));
                        pulsing = true;

                        format!("pulsing at {rate_hz:.0} Hz ({:.0} ns)", config.duration_ns)
                    }
                    HwCommand::StopPulses => {
                        pulsing = false;
                        String::from("pulsing stopped")
                    }
                };
                let _ = output.send(HwEvent::Status(status)).await;
            }

            received = data_socket.recv_from(&mut data_buf) => {
                let (n, _from) = received?;
                // each 8-byte chunk is one JESD204B frame (LMFS = 2441,
                // ADC34J2x datasheet fig. 158): lane DA's 4 octets then
                // lane DD's, carrying channels A, B, C, D. Each sample is
                // two octets, MSB first: ch[11:4] then ch[3:0] + 4 zero
                // tail bits; 12-bit two's complement
                let frames = data_buf[..n]
                    .chunks_exact(8)
                    .map(|chunk| {
                        std::array::from_fn(|ch| {
                            let word = i16::from_be_bytes([chunk[2 * ch], chunk[2 * ch + 1]]);
                            (word >> 4) as f32 // arithmetic: drops tail bits, keeps sign
                        })
                    })
                    .collect();
                let _ = output.send(HwEvent::Frames(frames)).await;
            }
        }
    }
}
