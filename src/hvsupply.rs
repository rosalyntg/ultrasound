use std::time::Duration;

use tokio::time::sleep;

use crate::{mcp401x, mcp3021};

const VFB: f32 = 1.6;
const R_UPPER: f32 = 680e3;
const R_FIXED: f32 = 15e3;

pub struct HVSupply {
    pub pot: mcp401x::Mcp401x,
    pub adc: mcp3021::Mcp3021,
}

impl HVSupply {
    pub async fn get_voltage(
        &self,
        interface: &mut crate::xfcp::Interface,
    ) -> Result<f32, std::io::Error> {
        self.adc.read_voltage(interface).await
    }

    pub async fn get_target_voltage(
        &self,
        interface: &mut crate::xfcp::Interface,
    ) -> Result<f32, std::io::Error> {
        let r_pot = self.pot.get_resistance(interface).await?;

        Ok(self.voltage_for_pot(r_pot))
    }

    pub async fn set_target_voltage(
        &self,
        interface: &mut crate::xfcp::Interface,
        voltage: f32,
    ) -> Result<(), std::io::Error> {
        let i_fb = (voltage - VFB) / R_UPPER;
        let r_pot = VFB / i_fb - R_FIXED;

        let target_counts = self.pot.count_for_resistance(r_pot);
        let cur_counts = self.pot.get_count(interface).await?;

        // swing slowly, they are gentle beasts``
        if target_counts < cur_counts {
            for count in (target_counts..=cur_counts).rev() {
                self.pot
                    .i2c
                    .write(interface, self.pot.address, &[count])
                    .await?;
                sleep(Duration::from_millis(50)).await;
            }
        } else {
            for count in cur_counts..=target_counts {
                self.pot
                    .i2c
                    .write(interface, self.pot.address, &[count])
                    .await?;
                sleep(Duration::from_millis(50)).await;
            }
        }

        Ok(())
    }

    fn voltage_for_pot(&self, r_pot: f32) -> f32 {
        let i_fb = VFB / (r_pot + R_FIXED);
        let vout = i_fb * (R_UPPER + R_FIXED + r_pot);

        vout
    }

    pub fn max_voltage(&self) -> f32 {
        self.voltage_for_pot(0.)
    }
    pub fn min_voltage(&self) -> f32 {
        self.voltage_for_pot(self.pot.resistance) + 0.1 // for float rounding
    }
}
