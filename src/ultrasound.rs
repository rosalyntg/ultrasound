use std::io;
use std::net::{IpAddr, Ipv4Addr, SocketAddr};
use std::time::Duration;

use futures_util::{SinkExt, StreamExt, future::ready};
use tokio::time::sleep;
use tokio_util::{codec::BytesCodec, udp::UdpFramed};

use crate::ad34jx::Ad34jx;
use crate::hvsupply::HVSupply;
use crate::i2c::FlippedI2c;
use crate::jesd204bphy::Jesd204bPhy;
use crate::mcp401x::Mcp401x;
use crate::mcp3021::Mcp3021;
use crate::pulser::Pulser;
use crate::ramp::RampGenerator;
use crate::si5338::Si5338;
use crate::xfcp::{self, Node};
use crate::xgpio::{GpioPin, XGpio};
use crate::xspi::XSpi;

pub const ULTRASOUND_IP: Ipv4Addr = Ipv4Addr::new(10, 80, 4, 1);
pub const ULTRASOUND_HOST_IP: Ipv4Addr = Ipv4Addr::new(10, 80, 4, 2);

pub const ULTRASOUND_CTRL_PORT: u16 = 8001;
pub const ULTRASOUND_DATA_PORT: u16 = 8002;

/// The ultrasound board: the XFCP interface plus all peripherals hanging
/// off of it.
pub struct Ultrasound {
    pub interface: xfcp::Interface,
    pub mem: xfcp::MemoryNode,

    pub led_gpio: XGpio,
    pub adc_reset: GpioPin,
    pub jesd204b_rst: GpioPin,

    pub ramp: RampGenerator,
    pub hvplus: HVSupply,
    /// HV- doesn't exist in the enumeration yet; wired up provisionally,
    /// mirroring hvplus, for when it does.
    pub hvminus: Option<HVSupply>,
    pub pulser: Pulser,
    pub clk: Si5338,
    pub adc: Ad34jx,
    pub jesd: Jesd204bPhy,
}

impl Ultrasound {
    pub async fn bind_data_socket() -> Result<tokio::net::UdpSocket, io::Error> {
        tokio::net::UdpSocket::bind((ULTRASOUND_HOST_IP, ULTRASOUND_DATA_PORT)).await
    }

    /// Binds the control socket, enumerates the XFCP bus, and constructs
    /// all peripherals.
    pub async fn connect() -> Result<Self, io::Error> {
        let socket =
            tokio::net::UdpSocket::bind((ULTRASOUND_HOST_IP, ULTRASOUND_CTRL_PORT)).await?;

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

        let mut interface = xfcp::Interface::new(rx, tx);
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
        let clk_i2c =
            find_i2c("clk").ok_or_else(|| io::Error::other("no I2C node named 'clk'"))?;
        let hvplus_i2c =
            find_i2c("hvplus").ok_or_else(|| io::Error::other("no I2C node named 'hvplus'"))?;

        let led_gpio = XGpio {
            node: mem.clone(),
            offset: 0x0,
            width: [2, 0],
        };
        let pinswap_gpio = XGpio {
            node: mem.clone(),
            offset: 0x6_0000,
            width: [1, 1],
        };
        let rst_gpio = XGpio {
            node: mem.clone(),
            offset: 0x1_0000,
            width: [3, 0],
        };

        let adc_reset = GpioPin {
            gpio: rst_gpio.clone(),
            ch: 0,
            pin: 0,
        };
        let jesd204b_rst = GpioPin {
            gpio: rst_gpio,
            ch: 0,
            pin: 2,
        };

        let ramp = RampGenerator {
            pot: Mcp401x {
                i2c: Box::new(ramp_i2c),
                address: 0b0101111,
                resistance: 10e3,
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
                resistance: 100e3,
            },
            adc: Mcp3021 {
                i2c: Box::new(hvplus_i2c_flip),
                address: 0b1001000,
                mult: 1.0 / 0.0329,
                vdd: 3.3,
            },
        };

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
                    resistance: 100e3,
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

        let clk = Si5338 {
            i2c: clk_i2c,
            address: 0x70,
        };

        let adc = Ad34jx {
            spi: XSpi {
                node: mem.clone(),
                offset: 0x4_0000,
                cpol: false,
                cpha: false,
            },
            cs: 0,
            reset: adc_reset.clone(),
        };

        let jesd = Jesd204bPhy {
            mem: mem.clone(),
            offset: 0x3_0000,
        };

        Ok(Self {
            interface,
            mem,
            led_gpio,
            adc_reset,
            jesd204b_rst,
            ramp,
            hvplus,
            hvminus,
            pulser,
            clk,
            adc,
            jesd,
        })
    }

    /// clk + ADC bringup, then JESD204B PHY reset.
    pub async fn init_hw(&mut self) -> Result<(), io::Error> {
        self.clk.init(&mut self.interface).await?;

        sleep(Duration::from_millis(500)).await;

        self.adc
            .init(&mut self.interface, crate::ad34jx::Mode::Lmfs2441)
            .await?;
        self.adc.write_reg(&mut self.interface, 0x34, 0).await?; // subclass 0

        // reset PHY after clk bringup
        sleep(Duration::from_millis(500)).await;
        self.jesd204b_rst.set(&mut self.interface).await?;
        sleep(Duration::from_millis(50)).await;
        self.jesd204b_rst.clear(&mut self.interface).await?;

        Ok(())
    }
}
