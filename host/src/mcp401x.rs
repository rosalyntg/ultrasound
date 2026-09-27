use std::io;

use crate::{i2c::I2c, xfcp};

pub struct Mcp401x {
    pub i2c: Box<dyn I2c>,
    pub address: u8,
    pub resistance: f32,
}

impl Mcp401x {
    pub async fn set_resistance(
        &self,
        interface: &mut xfcp::Interface,
        resistance: f32,
    ) -> Result<(), io::Error> {
        assert!(resistance <= self.resistance);

        let count = (resistance * 127. / (self.resistance)) as u8; // 7 bit pot
        self.set_count(interface, count).await
    }

    pub async fn get_resistance(&self, interface: &mut xfcp::Interface) -> Result<f32, io::Error> {
        let data = self.get_count(interface).await?;
        let resistance = f32::from(data) * self.resistance / 127.;
        Ok(resistance)
    }

    pub async fn get_count(&self, interface: &mut xfcp::Interface) -> Result<u8, io::Error> {
        let data = self.i2c.read(interface, self.address, 1).await?;
        Ok(data[0])
    }

    pub async fn set_count(&self, interface: &mut xfcp::Interface, count: u8) -> Result<(), io::Error> {
        assert!(count <= 127);
        self.i2c.write(interface, self.address, &[count]).await?;
        Ok(())
    }

    pub fn count_for_resistance(&self, resistance: f32) -> u8 {
        assert!(resistance <= self.resistance, "resistance {} exceeds pot resistance {}", resistance, self.resistance);
        assert!(resistance >= 0.0);
        (resistance * 127. / (self.resistance)).round() as u8
    }
}
