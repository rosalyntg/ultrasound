use crate::{i2c::I2c, xfcp};


pub struct Mcp3021 {
    pub i2c: Box<dyn I2c>,
    pub address: u8,
    pub mult: f32,
    pub vdd: f32,
}

impl Mcp3021 {
    pub async fn read_voltage(&self, interface: &mut xfcp::Interface) -> Result<f32, std::io::Error> {
        let raw = self.read_raw(interface).await?;
        let voltage_raw = (raw as f32 / (1 << 10) as f32) * self.vdd;
        let voltage_scaled = voltage_raw * self.mult;
        Ok(voltage_scaled)
    }

    pub async fn read_raw(&self, interface: &mut xfcp::Interface) -> Result<u16, std::io::Error> {
        let data = self.i2c.read(interface, self.address, 2).await?;
        let raw = u16::from_be_bytes(data.try_into().unwrap());
        Ok(raw >> 2) // discard bottom 2 bits, they are garbage
    }
}

