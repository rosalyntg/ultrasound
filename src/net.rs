use std::time::Duration;

use tokio::time::sleep;

use crate::ultrasound::Ultrasound;

#[tokio::main(flavor = "current_thread")]
pub async fn main() {
    let data_socket = Ultrasound::bind_data_socket()
        .await
        .expect("Failed to bind UDP socket");

    tokio::spawn(async move {
        while let Ok((d, _)) = data_socket.recv_from(&mut [0u8; 2048]).await {
            println!("Received data packet: {:?}", &d);
        }
    });

    let mut u = Ultrasound::connect().await.unwrap();

    u.init_hw().await.unwrap();

    // dbg!(u.adc.read_reg(&mut u.interface, 0x34).await);
    // dbg!(u.adc.read_reg(&mut u.interface, 0x2f).await);

    // u.adc.test_pattern(&mut u.interface, true).await.unwrap();
    // u.adc.link_test(&mut u.interface).await.unwrap();
    // u.adc.sw_sync(&mut u.interface).await.unwrap();

    // u.jesd.status(&mut u.interface).await.unwrap();

    // dbg!(u.adc.write_reg(&mut u.interface, 0x15, 0b1111_0100).await); // power down all channels

    // loop {
    //     u.hvplus.get_voltage(&mut u.interface).await.unwrap();
    // }

    // loop {
    //     u.led_gpio.set_pin(&mut u.interface, 1).await.unwrap();
    //     sleep(Duration::from_millis(500)).await;
    //     u.led_gpio.clear_pin(&mut u.interface, 1).await.unwrap();
    //     sleep(Duration::from_millis(500)).await;
    // }

    return;

    u.pulser.setup(&mut u.interface, 2., 200, 35).await.unwrap();
    dbg!(u.pulser.get_state(&mut u.interface).await.unwrap());
    u.pulser.arm(&mut u.interface).await.unwrap();
    dbg!(u.pulser.get_state(&mut u.interface).await.unwrap());

    u.ramp.set_ramp_rate(&mut u.interface, 46.).await.unwrap();

    loop {
        u.pulser.start(&mut u.interface).await.unwrap();

        sleep(Duration::from_millis(200)).await;
    }
}
