use crate::{mcp401x::Mcp401x, xgpio::XGpio};


const VREF_V: f32 = 1.263;
const R_FIXED_OHM: f32 = 10e3; // 10kOhm
const C_FIXED_F: f32 = 3e-9; // 3nF

pub struct RampGenerator {
    pub pot: Mcp401x,
    pub rst: XGpio,
}

impl RampGenerator {
    pub async fn set_ramp_rate(&self, interface: &mut crate::xfcp::Interface, time_us: f32) -> Result<(), std::io::Error> {
        let r_tot = time_us / 1e6 * VREF_V / C_FIXED_F;
        let r_pot = r_tot - R_FIXED_OHM;
        assert!(r_pot > 0.0);
        assert!(r_pot < self.pot.resistance as f32);
        self.pot.set_resistance(interface, r_pot).await?;
        Ok(())
    }

    pub async fn stop(&self, interface: &mut crate::xfcp::Interface) -> Result<(), std::io::Error> {
        self.rst.set_pin(interface, 0).await?;
        Ok(())
    }

    pub async fn start(&self, interface: &mut crate::xfcp::Interface) -> Result<(), std::io::Error> {
        self.rst.clear_pin(interface, 0).await?;
        Ok(())
    }
}