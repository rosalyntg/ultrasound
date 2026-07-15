use std::io;
use std::net::{IpAddr, Ipv4Addr, SocketAddr};
use std::ops::RangeInclusive;
use std::time::Duration;

use iced::alignment;
use iced::futures::channel::mpsc;
use iced::futures::{SinkExt, Stream, StreamExt, future::ready};
use iced::mouse;
use iced::widget::{canvas, column, container, row, scrollable, slider, text};
use iced::{Element, Fill, Point, Rectangle, Renderer, Subscription, Theme};
use tokio_util::codec::BytesCodec;
use tokio_util::udp::UdpFramed;

use crate::hvsupply::HVSupply;
use crate::i2c::FlippedI2c;
use crate::mcp401x::Mcp401x;
use crate::mcp3021::Mcp3021;
use crate::pulser::Pulser;
use crate::ramp::RampGenerator;
use crate::xfcp::Node;
use crate::xgpio::{GpioPin, XGpio};

#[allow(dead_code)]
mod net;
mod xfcp;
mod mcp401x;
mod ramp;
mod xgpio;
mod hvsupply;
mod mcp3021;
mod pulser;
mod si5338;
mod xspi;
mod ad34jx;
mod jesd204bphy;
mod i2c;

// keep in sync with net.rs
const ULTRASOUND_IP: Ipv4Addr = Ipv4Addr::new(10, 80, 4, 1);
const ULTRASOUND_HOST_IP: Ipv4Addr = Ipv4Addr::new(10, 80, 4, 2);

const ULTRASOUND_CTRL_PORT: u16 = 8001;
const ULTRASOUND_DATA_PORT: u16 = 8002;

// usable ramp times for the RC ramp: 10k fixed + 10k pot, see ramp.rs
const RAMP_RATE_RANGE: RangeInclusive<f32> = 24.0..=47.0; // µs
const HV_RANGE: RangeInclusive<f32> = 0.0..=100.0; // V
const PULSE_DURATION_RANGE: RangeInclusive<f32> = 100.0..=2000.0; // ns (full period)

const PULSER_RECV_TIME_US: u32 = 200;
const PULSER_DELAY_RAMP_US: u32 = 35;

const HV_POLL_PERIOD: Duration = Duration::from_secs(1);
const RECONNECT_DELAY: Duration = Duration::from_secs(3);

// pub fn main() -> iced::Result {
//     tracing_subscriber::fmt::init();

//     iced::application(App::default, App::update, App::view)
//         .subscription(App::subscription)
//         .title("Ultrasound Client")
//         .centered()
//         .run()
// }
use net::main;

struct App {
    ramp_rate_us: f32,
    hv_plus_setpoint: f32,
    hv_minus_setpoint: f32, // magnitude, displayed negative
    pulse_duration_ns: f32,

    hv_plus_reading: Option<f32>,
    hv_minus_reading: Option<f32>,

    status: String,
    hw: Option<mpsc::Sender<HwCommand>>,

    points: Vec<(f32, f32)>,
    plot_cache: canvas::Cache,
}

impl Default for App {
    fn default() -> Self {
        Self {
            ramp_rate_us: 46.0,
            hv_plus_setpoint: 0.0,
            hv_minus_setpoint: 0.0,
            pulse_duration_ns: 500.0, // 2 MHz
            hv_plus_reading: None,
            hv_minus_reading: None,
            status: String::from("starting..."),
            hw: None,
            points: Vec::new(),
            plot_cache: canvas::Cache::new(),
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
    /// X/Y points to plot
    Points(Vec<(f32, f32)>),
}

/// Commands flowing from the GUI to the hardware task.
#[derive(Debug, Clone)]
enum HwCommand {
    SetRampRate(f32),   // µs
    SetHvPlus(f32),     // V
    SetHvMinus(f32),    // V (magnitude)
    SetPulseDuration(f32), // ns
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
                self.send(HwCommand::SetPulseDuration(self.pulse_duration_ns));
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
                    self.status = format!("disconnected: {reason}");
                }
                HwEvent::Status(status) => self.status = status,
                HwEvent::HvPlusVoltage(v) => self.hv_plus_reading = Some(v),
                HwEvent::HvMinusVoltage(v) => self.hv_minus_reading = Some(v),
                HwEvent::Points(points) => {
                    self.points = points;
                    self.plot_cache.clear();
                }
            },
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
            text(if connected { "● connected" } else { "○ disconnected" }).size(14),
            text(&self.status).size(13),
        ]
        .spacing(5);

        let ramp_section = column![
            text("Ramp rate").size(16),
            text(format!("{:.1} µs", self.ramp_rate_us)).size(14),
            slider(RAMP_RATE_RANGE, self.ramp_rate_us, Message::RampRateChanged)
                .step(0.5)
                .on_release(Message::ApplyRampRate),
        ]
        .spacing(5);

        let hv_plus_section = column![
            text("HV+").size(16),
            text(format!("measured: {}", fmt_voltage(self.hv_plus_reading))).size(14),
            text(format!("setpoint: {:.0} V", self.hv_plus_setpoint)).size(14),
            slider(
                HV_RANGE,
                self.hv_plus_setpoint,
                Message::HvPlusSetpointChanged
            )
            .step(1.0)
            .on_release(Message::ApplyHvPlus),
        ]
        .spacing(5);

        let hv_minus_section = column![
            text("HV−").size(16),
            text(format!("measured: {}", fmt_voltage(self.hv_minus_reading))).size(14),
            text(format!("setpoint: −{:.0} V", self.hv_minus_setpoint)).size(14),
            slider(
                HV_RANGE,
                self.hv_minus_setpoint,
                Message::HvMinusSetpointChanged
            )
            .step(1.0)
            .on_release(Message::ApplyHvMinus),
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
            ]
            .spacing(20)
            .padding(15),
        ))
        .style(container::bordered_box)
        .width(280)
        .height(Fill);

        let plot = container(
            canvas(Plot {
                points: &self.points,
                cache: &self.plot_cache,
            })
            .width(Fill)
            .height(Fill),
        )
        .width(Fill)
        .height(Fill)
        .padding(10);

        row![sidebar, plot].into()
    }
}

fn fmt_voltage(v: Option<f32>) -> String {
    match v {
        Some(v) => format!("{v:.1} V"),
        None => String::from("—"),
    }
}

struct Plot<'a> {
    points: &'a [(f32, f32)],
    cache: &'a canvas::Cache,
}

impl canvas::Program<Message> for Plot<'_> {
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

            let margin_left = 60.0;
            let margin_right = 15.0;
            let margin_top = 15.0;
            let margin_bottom = 30.0;

            let area = Rectangle {
                x: margin_left,
                y: margin_top,
                width: (frame.width() - margin_left - margin_right).max(1.0),
                height: (frame.height() - margin_top - margin_bottom).max(1.0),
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

            if self.points.is_empty() {
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

            let (mut x_min, mut x_max) = (f32::INFINITY, f32::NEG_INFINITY);
            let (mut y_min, mut y_max) = (f32::INFINITY, f32::NEG_INFINITY);
            for &(x, y) in self.points {
                x_min = x_min.min(x);
                x_max = x_max.max(x);
                y_min = y_min.min(y);
                y_max = y_max.max(y);
            }
            // avoid a degenerate scale when the data is flat
            if x_max - x_min < f32::EPSILON {
                x_min -= 1.0;
                x_max += 1.0;
            }
            if y_max - y_min < f32::EPSILON {
                y_min -= 1.0;
                y_max += 1.0;
            }

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

            // trace
            let trace = canvas::Path::new(|builder| {
                let mut points = self.points.iter();
                let &(x, y) = points.next().unwrap();
                builder.move_to(to_screen(x, y));
                for &(x, y) in points {
                    builder.line_to(to_screen(x, y));
                }
            });
            frame.stroke(
                &trace,
                canvas::Stroke::default()
                    .with_color(palette.primary.base.color)
                    .with_width(1.5),
            );

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
                format!("{x_min:.0}"),
                Point::new(area.x, area.y + area.height + 5.0),
                text::Alignment::Left,
                alignment::Vertical::Top,
            ));
            frame.fill_text(label(
                format!("{x_max:.0}"),
                Point::new(area.x + area.width, area.y + area.height + 5.0),
                text::Alignment::Right,
                alignment::Vertical::Top,
            ));
        });

        vec![geometry]
    }
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

/// Connects to the board, brings up the control devices, and services
/// GUI commands until an I/O error occurs. Modeled on net.rs.
async fn hardware_session(output: &mut mpsc::Sender<HwEvent>) -> Result<(), io::Error> {
    let _ = output
        .send(HwEvent::Status(String::from("connecting...")))
        .await;

    let socket = tokio::net::UdpSocket::bind((ULTRASOUND_HOST_IP, ULTRASOUND_CTRL_PORT)).await?;
    let data_socket =
        tokio::net::UdpSocket::bind((ULTRASOUND_HOST_IP, ULTRASOUND_DATA_PORT)).await?;

    let dst = SocketAddr::new(IpAddr::V4(ULTRASOUND_IP), ULTRASOUND_CTRL_PORT);

    // drain stale packets
    let mut buf = [0u8; 2048];
    while socket.try_recv(&mut buf).is_ok() {}

    let frame = UdpFramed::new(socket, BytesCodec::new())
        .with(move |f| ready(Ok((f, dst))))
        .filter_map(move |r| match r {
            Ok((b, from)) => {
                if from != dst {
                    println!("Received packet from unexpected source: {}, dropping", from);
                    ready(None)
                } else {
                    ready(Some(b.freeze()))
                }
            }
            Err(e) => {
                println!("Error receiving packet: {}", e);
                ready(None)
            }
        });

    let (tx, rx) = frame.split();

    let mut interface = crate::xfcp::Interface::new(rx, tx);
    let root = interface.enumerate().await?;

    let Node::SwitchNode(switch) = &root else {
        return Err(io::Error::other("root node is not a switch node"));
    };

    let nodes = switch.enumerate(&mut interface).await?;

    let mem = nodes
        .iter()
        .find_map(|n| match n {
            Node::MemoryNode(m) => Some(m.clone()),
            _ => None,
        })
        .ok_or_else(|| io::Error::other("no memory node found"))?;

    let find_i2c = |name: &str| {
        nodes.iter().find_map(|n| match n {
            Node::I2CNode(i2c) if n.name() == name => Some(i2c.clone()),
            _ => None,
        })
    };

    let ramp_i2c =
        find_i2c("ramp").ok_or_else(|| io::Error::other("no I2C node named 'ramp'"))?;
    let hvplus_i2c =
        find_i2c("hvplus").ok_or_else(|| io::Error::other("no I2C node named 'hvplus'"))?;

    let pinswap_gpio = XGpio {
        node: mem.clone(),
        offset: 0x6_0000,
        width: [1, 1],
    };

    let ramp = RampGenerator {
        pot: Mcp401x {
            i2c: Box::new(ramp_i2c),
            address: 0b0101111,
            resistance: 10_000,
        },
    };

    let (hvplus_i2c_nonflip, hvplus_i2c_flip) = FlippedI2c::new(
        hvplus_i2c,
        GpioPin {
            gpio: pinswap_gpio.clone(),
            ch: 0,
            pin: 0,
        },
    );
    let hvplus = HVSupply {
        pot: Mcp401x {
            i2c: Box::new(hvplus_i2c_nonflip),
            address: 0b0101111,
            resistance: 10_000,
        },
        adc: Mcp3021 {
            i2c: Box::new(hvplus_i2c_flip),
            address: 0b1001000,
            mult: 1.0 / 0.026,
            vdd: 3.3,
        },
    };

    // HV- doesn't exist in the enumeration yet; wired up provisionally,
    // mirroring hvplus, for when it does.
    let hvminus = find_i2c("hvminus").map(|i2c| {
        let (nonflip, flip) = FlippedI2c::new(
            i2c,
            GpioPin {
                gpio: pinswap_gpio.clone(),
                ch: 1,
                pin: 0,
            },
        );
        HVSupply {
            pot: Mcp401x {
                i2c: Box::new(nonflip),
                address: 0b0101111,
                resistance: 10_000,
            },
            adc: Mcp3021 {
                i2c: Box::new(flip),
                address: 0b1001000,
                mult: 1.0 / 0.026,
                vdd: 3.3,
            },
        }
    });

    let pulser = Pulser {
        mem: mem.clone(),
        offset: 0x2_0000,
    };

    let (command_tx, mut command_rx) = mpsc::channel(32);
    let _ = output.send(HwEvent::Connected(command_tx)).await;

    let mut poll = tokio::time::interval(HV_POLL_PERIOD);
    let mut data_buf = [0u8; 2048];

    loop {
        tokio::select! {
            _ = poll.tick() => {
                let v = hvplus.get_voltage(&mut interface).await?;
                let _ = output.send(HwEvent::HvPlusVoltage(v)).await;

                if let Some(hvminus) = &hvminus {
                    let v = hvminus.get_voltage(&mut interface).await?;
                    let _ = output.send(HwEvent::HvMinusVoltage(v)).await;
                }
            }

            command = command_rx.next() => {
                let Some(command) = command else { return Ok(()) };

                let status = match command {
                    HwCommand::SetRampRate(time_us) => {
                        let time_us = time_us.clamp(*RAMP_RATE_RANGE.start(), *RAMP_RATE_RANGE.end());
                        ramp.set_ramp_rate(&mut interface, time_us).await?;
                        format!("ramp rate set to {time_us:.1} µs")
                    }
                    // TODO: setting the HV supplies is not implemented yet
                    HwCommand::SetHvPlus(v) => {
                        format!("HV+ setpoint {v:.0} V ignored: HV control not implemented yet")
                    }
                    HwCommand::SetHvMinus(v) => {
                        format!("HV− setpoint −{v:.0} V ignored: HV control not implemented yet")
                    }
                    HwCommand::SetPulseDuration(duration_ns) => {
                        let frequency_mhz = 1000.0 / duration_ns;
                        pulser
                            .setup(&mut interface, frequency_mhz, PULSER_RECV_TIME_US, PULSER_DELAY_RAMP_US)
                            .await?;
                        format!("pulse duration set to {duration_ns:.0} ns")
                    }
                };
                let _ = output.send(HwEvent::Status(status)).await;
            }

            received = data_socket.recv_from(&mut data_buf) => {
                let (n, _from) = received?;
                // provisional: interpret data packets as consecutive LE i16
                // samples, plotted against sample index
                let points = data_buf[..n]
                    .chunks_exact(2)
                    .enumerate()
                    .map(|(i, c)| (i as f32, i16::from_le_bytes([c[0], c[1]]) as f32))
                    .collect();
                let _ = output.send(HwEvent::Points(points)).await;
            }
        }
    }
}
