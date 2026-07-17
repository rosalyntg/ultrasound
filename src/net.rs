use std::time::Duration;

use tokio::time::sleep;

use crate::ultrasound::Ultrasound;

#[tokio::main(flavor = "current_thread")]
pub async fn main() {
    let mut u = Ultrasound::connect().await.unwrap();

    // u.init_hw().await.unwrap();

    dbg!(u.hvplus.get_target_voltage(&mut u.interface).await);

    
    // let mut v = vec![];
    // for _ in 0..1000 {
    // loop{
    //     // v.push(u.hvplus.get_voltage(&mut u.interface).await.unwrap());
    //     // v.push(dbg!(u.hvplus.adc.read_raw(&mut u.interface).await.unwrap()) as f32 / 1024. * 3.3);
    //     dbg!(u.hvplus.adc.read_raw(&mut u.interface).await.unwrap()) as f32 / 1024. * 3.3;
    // }
    // println!("{}", v.iter().sum::<f32>() / v.len() as f32);
        dbg!(u.hvplus.get_voltage(&mut u.interface).await.unwrap());


    dbg!(u.hvplus.adc.read_raw(&mut u.interface).await.unwrap() as f32 / 1024. * 3.3);

    // u.hvplus.set_target_voltage(&mut u.interface, dbg!(u.hvplus.max_voltage())).await;
    // u.hvplus.set_target_voltage(&mut u.interface, 35.).await;
    u.hvminus.set_target_voltage(&mut u.interface, -20.).await;

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
