use std::io;

use crate::{i2c::I2c, xfcp};

pub struct Mcp401x {
    pub i2c: Box<dyn I2c>,
    pub address: u8,
    pub resistance: u16,
}

impl Mcp401x {
    pub async fn set_resistance(
        &self,
        interface: &mut xfcp::Interface,
        resistance: f32,
    ) -> Result<(), io::Error> {
        assert!(resistance <= self.resistance as f32);

        let data = (resistance * 127. / (self.resistance as f32)) as u8; // 7 bit pot
        self.i2c
            .write(interface, self.address, &[data])
            .await?;
        Ok(())
    }

    pub async fn get_resistance(&self, interface: &mut xfcp::Interface) -> Result<f32, io::Error> {
        let data = self.i2c.read(interface, self.address, 1).await?;
        let resistance = f32::from(data[0]) * self.resistance as f32 / 127.;
        Ok(resistance)
    }
}
