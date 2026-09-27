use crate::{mcp401x::Mcp401x, xgpio::XGpio};

const VREF_V: f32 = 1.263;
const R_FIXED_OHM: f32 = 10e3; // 10kOhm
const C_FIXED_F: f32 = 3e-9 + 1.8e-9; // 3nF + 1.8nF

pub struct RampGenerator {
    pub pot: Mcp401x,
}

impl RampGenerator {
    pub async fn set_ramp_rate(
        &self,
        interface: &mut crate::xfcp::Interface,
        time_us: f32,
    ) -> Result<(), std::io::Error> {
        let r_tot = time_us / 1e6 * VREF_V / C_FIXED_F;
        let r_pot = r_tot - R_FIXED_OHM;
        assert!(r_pot > 0.0);
        assert!(r_pot < self.pot.resistance as f32);
        self.pot.set_resistance(interface, r_pot).await?;
        Ok(())
    }

    fn ramp_rate_for_pot(&self, r_pot: f32) -> f32 {
        let r_tot = r_pot + R_FIXED_OHM;
        let time_s = r_tot * C_FIXED_F / VREF_V;
        time_s * 1e6
    }

    pub fn max_ramp_rate(&self) -> f32 {
        self.ramp_rate_for_pot(0.)
    }
    pub fn min_ramp_rate(&self) -> f32 {
        self.ramp_rate_for_pot(self.pot.resistance)
    }
}
