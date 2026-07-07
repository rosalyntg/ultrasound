use std::{
    net::{Ipv4Addr, SocketAddr},
    time::Duration,
};

use futures_util::{SinkExt, StreamExt, future::ready};
use tokio::time::sleep;
use tokio_util::{codec::BytesCodec, udp::UdpFramed};

use crate::xfcp::Node;

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
        .with(|f| ready(Ok((f, dst))))
        .filter_map(|r| match r {
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

    let mut interface = crate::xfcp::Interface::new(frame);
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

    dbg!(String::from_utf8_lossy(&i2c.read_at(&mut interface, 0x50, 0x14, 16).await.unwrap()));

    dbg!(mem.read(&mut interface, 0x0, 4).await.unwrap());

    dbg!(
        mem.write(&mut interface, 0x0, &[0xff, 0xff, 0xff, 0xff])
            .await
            .unwrap()
    );
    dbg!(mem.read(&mut interface, 0x0, 4).await.unwrap());
    loop {
        dbg!(
            mem.write(&mut interface, 0x0, &[0xff, 0xff, 0xff, 0xff])
                .await
                .unwrap()
        );

        sleep(Duration::from_millis(500)).await;
        dbg!(
            mem.write(&mut interface, 0x0, &[0x00, 0x00, 0x00, 0x00])
                .await
                .unwrap()
        );
        sleep(Duration::from_millis(500)).await;
    }
}
