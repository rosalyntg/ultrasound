use std::time::Duration;

use tokio::time::sleep;

use crate::{mcp401x, mcp3021};


pub struct HVSupply {
    pub pot: mcp401x::Mcp401x,
    pub adc: mcp3021::Mcp3021,
    pub vfb: f32,
    pub r_upper: f32,
    pub r_fixed: f32,
    pub pot_va: f32, // voltage of `A` pin of the pot
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
        let i_fb = (voltage - self.vfb) / self.r_upper;
        let r_pot = (self.vfb - self.pot_va) / i_fb - self.r_fixed;

        let target_counts = self.pot.count_for_resistance(r_pot);
        let cur_counts = self.pot.get_count(interface).await?;

        dbg!(target_counts, cur_counts);

        // swing slowly, they are gentle beasts``
        if target_counts < cur_counts {
            for count in (target_counts..=cur_counts).rev() {
                self.pot
                    .i2c
                    .write(interface, self.pot.address, &[dbg!(count)])
                    .await?;
                sleep(Duration::from_millis(50)).await;
            }
        } else {
            for count in cur_counts..=target_counts {
                self.pot
                    .i2c
                    .write(interface, self.pot.address, &[dbg!(count)])
                    .await?;
                sleep(Duration::from_millis(50)).await;
            }
        }

        Ok(())
    }

    fn voltage_for_pot(&self, r_pot: f32) -> f32 {
        let i_fb = (self.vfb - self.pot_va) / (r_pot + self.r_fixed);
        let vout = i_fb * (self.r_upper + self.r_fixed + r_pot) - self.pot_va;

        vout
    }

    pub fn max_voltage(&self) -> f32 {
        if self.vfb < 0. {
            self.voltage_for_pot(self.pot.resistance)
        } else {
            self.voltage_for_pot(0.)
        }
    }
    pub fn min_voltage(&self) -> f32 {
        if self.vfb < 0. {
            -50. // artificial cap at -50V, i'm scared to break it
        } else {
            self.voltage_for_pot(self.pot.resistance) + 0.1 // float rounding
        }
    }
}
