use crate::{mcp401x, mcp3021};

const VFB: f32 = 1.6;
const R_UPPER: f32 = 680e3;
const R_FIXED: f32 = 15e3;


pub struct HVSupply {
    pub pot: mcp401x::Mcp401x,
    pub adc: mcp3021::Mcp3021,
}


impl HVSupply {
    pub async fn get_voltage(&self, interface: &mut crate::xfcp::Interface) -> Result<f32, std::io::Error> {
        self.adc.read_voltage(interface).await
    }

    pub async fn get_target_voltage(&self, interface: &mut crate::xfcp::Interface) -> Result<f32, std::io::Error> {
        let r_pot = self.pot.get_resistance(interface).await?;

        let i_fb = VFB / (r_pot + R_FIXED);
        let vout = i_fb * (R_UPPER + R_FIXED + r_pot);
        Ok(vout)
    }
}
