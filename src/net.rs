use std::{
    net::{Ipv4Addr, SocketAddr},
    time::Duration,
};

use futures_util::{SinkExt, StreamExt, future::ready};
use tokio::time::sleep;
use tokio_util::{codec::BytesCodec, udp::UdpFramed};

use crate::{mcp401x, xfcp::Node, xgpio};

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
    dbg!(&root);

    let Node::SwitchNode(switch) = &root else {
        panic!("Root node is not a switch node");
    };

    let nodes = switch.enumerate(&mut interface).await.unwrap();
    dbg!(&nodes);

    let Node::MemoryNode(mem) = &nodes[5] else {
        panic!("Expected memory node at index 5");
    };

    let Node::I2CNode(i2c) = &nodes[4] else {
        panic!("Expected I2C node at index 4");
    };

    let Node::I2CNode(ramp_i2c) = nodes.iter().find(|&n| n.name() == "ramp").unwrap() else {
        panic!("Expected I2C node named 'ramp'");
    };

    let mcp4017 = mcp401x::Mcp401x {
        i2c_node: ramp_i2c.clone(),
        address: 0b0101111,
        resistance: 10_000,
    };

    let led_gpio = xgpio::XGpio {
        node: mem.clone(),
        offset: 0x0,
        width: 2,
    };

    // loop {
    //     led_gpio.set_pin(&mut interface, 1).await.unwrap();
    //     sleep(Duration::from_millis(500)).await;
    //     led_gpio.clear_pin(&mut interface, 1).await.unwrap();
    //     sleep(Duration::from_millis(500)).await;
    // }

    let ramp = crate::ramp::RampGenerator {
        pot: mcp4017,
    };

    let pulser = crate::pulser::Pulser {
        mem: mem.clone(),
        offset: 0x2_0000,
    };

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
