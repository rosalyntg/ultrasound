use crate::{mcp401x, mcp3021};



pub struct HVSupply {
    pub pot: mcp401x::Mcp401x,
    pub adc: mcp3021::Mcp3021,
}


impl HVSupply {
    pub async fn get_voltage(&self, interface: &mut crate::xfcp::Interface) -> Result<f32, std::io::Error> {
        self.adc.read_voltage(interface).await
    }
}
