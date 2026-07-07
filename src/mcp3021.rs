use crate::xfcp;


struct Mcp3021 {
    i2c: xfcp::I2CNode,
    address: u8,
    mult: f32,
    vdd: f32,
}

impl Mcp3021 {
    pub async fn read_voltage(&self, interface: &mut xfcp::Interface) -> Result<f32, std::io::Error> {
        let raw = self.read_raw(interface).await?;
        let voltage = (raw as f32 / (1 << 16) as f32) * self.vdd * self.mult;
        Ok(voltage)
    }

    pub async fn read_raw(&self, interface: &mut xfcp::Interface) -> Result<u16, std::io::Error> {
        let data = self.i2c.read(interface, self.address, 2).await?;
        let raw = u16::from_be_bytes(data.try_into().unwrap());
        Ok(raw)
    }
}

