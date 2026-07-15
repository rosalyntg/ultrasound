use std::{
    net::{Ipv4Addr, SocketAddr},
    time::Duration,
};

use futures_util::{SinkExt, StreamExt, future::ready};
use tokio::time::sleep;
use tokio_util::{codec::BytesCodec, udp::UdpFramed};

use crate::{
    hvsupply,
    i2c::FlippedI2c,
    jesd204bphy, mcp401x, mcp3021,
    xfcp::Node,
    xgpio::{self, GpioPin},
    xspi,
};

const ULTRASOUND_IP: Ipv4Addr = Ipv4Addr::new(10, 80, 4, 1);
const ULTRASOUND_HOST_IP: Ipv4Addr = Ipv4Addr::new(10, 80, 4, 2);

const ULTRASOUND_CTRL_PORT: u16 = 8001;
const ULTRASOUND_DATA_PORT: u16 = 8002;

#[tokio::main(flavor = "current_thread")]
pub async fn main() {
    let socket = tokio::net::UdpSocket::bind((ULTRASOUND_HOST_IP, ULTRASOUND_CTRL_PORT))
        .await
        .expect("Failed to bind UDP socket");

    let dst = SocketAddr::new(std::net::IpAddr::V4(ULTRASOUND_IP), ULTRASOUND_CTRL_PORT);

    let mut buf = [0u8; 2048];
    while let Ok(_) = socket.try_recv(&mut buf) {
        println!("Drained pending packet: {:?}", &buf);
    }

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
    let root = interface.enumerate().await.unwrap();

    let Node::SwitchNode(switch) = &root else {
        panic!("Root node is not a switch node");
    };

    let nodes = switch.enumerate(&mut interface).await.unwrap();

    let Node::MemoryNode(mem) = &nodes[5] else {
        panic!("Expected memory node at index 5");
    };

    let Node::I2CNode(ramp_i2c) = nodes.iter().find(|&n| n.name() == "ramp").unwrap() else {
        panic!("Expected I2C node named 'ramp'");
    };
    let Node::I2CNode(clk_i2c) = nodes.iter().find(|&n| n.name() == "clk").unwrap() else {
        panic!("Expected I2C node named 'clk'");
    };
    let Node::I2CNode(hvplus_i2c) = nodes.iter().find(|&n| n.name() == "hvplus").unwrap() else {
        panic!("Expected I2C node named 'hvplus'");
    };

    let ramp_mcp4017 = mcp401x::Mcp401x {
        i2c: Box::new(ramp_i2c.clone()),
        address: 0b0101111,
        resistance: 10_000,
    };

    let led_gpio = xgpio::XGpio {
        node: mem.clone(),
        offset: 0x0,
        width: [2, 0],
    };
    let pinswap_gpio = xgpio::XGpio {
        node: mem.clone(),
        offset: 0x6_0000,
        width: [1, 1],
    };

    let rst_gpio = xgpio::XGpio {
        node: mem.clone(),
        offset: 0x1_0000,
        width: [3, 0],
    };

    let spi_adc0 = xspi::XSpi {
        node: mem.clone(),
        offset: 0x4_0000,
        cpol: false,
        cpha: false,
    };

    let jesd204b_rst = GpioPin {
        gpio: rst_gpio.clone(),
        ch: 0,
        pin: 2,
    };

    let (hvplus_i2c_nonflip, hvplus_i2c_flip) = FlippedI2c::new(
        hvplus_i2c.clone(),
        GpioPin {
            gpio: pinswap_gpio.clone(),
            ch: 0,
            pin: 0,
        },
    );
    let hvplus = hvsupply::HVSupply {
        pot: mcp401x::Mcp401x {
            i2c: Box::new(hvplus_i2c_nonflip),
            address: 0b0101111,
            resistance: 10_000,
        },
        adc: mcp3021::Mcp3021 {
            i2c: Box::new(hvplus_i2c_flip),
            address: 0b1001000,
            mult: 1.0 / 0.026,
            vdd: 3.3,
        },
    };

    // loop {

    // hvplus.get_voltage(&mut interface).await.unwrap();
    // }

    // spi_adc0.init(&mut interface).await.unwrap();
    // for addr in 1..100 {
    //     dbg!(spi_adc0.transfer(&mut interface, 0, &[0b1100_0000 | addr, 0x00, 0x00]).await.unwrap());
    // }

    // loop {
    //     led_gpio.set_pin(&mut interface, 1).await.unwrap();
    //     sleep(Duration::from_millis(500)).await;
    //     led_gpio.clear_pin(&mut interface, 1).await.unwrap();
    //     sleep(Duration::from_millis(500)).await;
    // }

    let ramp = crate::ramp::RampGenerator { pot: ramp_mcp4017 };

    let pulser = crate::pulser::Pulser {
        mem: mem.clone(),
        offset: 0x2_0000,
    };

    let clk = crate::si5338::Si5338 {
        i2c: clk_i2c.clone(),
        address: 0x70,
    };

    let ad34jx = crate::ad34jx::Ad34jx {
        spi: spi_adc0,
        cs: 0,
        reset: GpioPin {
            gpio: rst_gpio.clone(),
            ch: 0,
            pin: 0,
        },
    };

    let jesd = jesd204bphy::Jesd204bPhy {
        mem: mem.clone(),
        offset: 0x3_0000,
    };

    // // sleep(Duration::from_millis(500)).await;
    // jesd.setup(&mut interface).await.unwrap();

    clk.init(&mut interface).await.unwrap();

    sleep(Duration::from_millis(500)).await;


    ad34jx
        .init(&mut interface, crate::ad34jx::Mode::Lmfs2441)
        .await
        .unwrap();

    dbg!(ad34jx.write_reg(&mut interface, 0x34, 0).await); // subclass 0

    // ad34jx.write_reg(&mut interface, 0x2a, 0b0100_0000).await.unwrap();

    // reset PHY after clk bringup
    sleep(Duration::from_millis(500)).await;
    jesd204b_rst.set(&mut interface).await.unwrap();
    sleep(Duration::from_millis(50)).await;
    jesd204b_rst.clear(&mut interface).await.unwrap();

    // dbg!(ad34jx.read_reg(&mut interface, 0x34).await);

    // dbg!(ad34jx.read_reg(&mut interface, 0x2f).await);

    // ad34jx.test_pattern(&mut interface, true).await.unwrap();
    // ad34jx.link_test(&mut interface).await.unwrap();
    // ad34jx.sw_sync(&mut interface).await.unwrap();

    // jesd.status(&mut interface).await.unwrap();

    // dbg!(ad34jx.write_reg(&mut interface, 0x15, 0b1111_0100).await); // power down all channels

    return;

    pulser.setup(&mut interface, 2., 200, 35).await.unwrap();
    dbg!(pulser.get_state(&mut interface).await.unwrap());
    pulser.arm(&mut interface).await.unwrap();
    dbg!(pulser.get_state(&mut interface).await.unwrap());

    ramp.set_ramp_rate(&mut interface, 46.).await.unwrap();

    loop {
        // ramp.rst.set_pin(&mut interface, 0).await.unwrap();
        pulser.start(&mut interface).await.unwrap();

        sleep(Duration::from_millis(200)).await;
    }

    // loop {
    //     sleep(Duration::from_millis(500)).await;
    //     ramp.rst.set_pin(&mut interface, 0).await.unwrap();
    //     sleep(Duration::from_millis(500)).await;
    // }

    // ramp.stop(&mut interface).await.unwrap();
    // sleep(Duration::from_secs(1)).await;
    // ramp.start(&mut interface).await.unwrap();
    // sleep(Duration::from_millis(1)).await;
    // ramp.stop(&mut interface).await.unwrap();
    // println!("done");

    // dbg!(String::from_utf8_lossy(&i2c.read_at_offset_1b(&mut interface, 0x50, 0x14, 16).await.unwrap()));

    // dbg!(mem.read(&mut interface, 0x0, 4).await.unwrap());

    // dbg!(
    //     mem.write(&mut interface, 0x0, &[0xff, 0xff, 0xff, 0xff])
    //         .await
    //         .unwrap()
    // );
    // dbg!(mem.read(&mut interface, 0x0, 4).await.unwrap());
}
