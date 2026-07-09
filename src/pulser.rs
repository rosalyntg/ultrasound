use std::io;

use crate::xfcp;

const CLK_RATE: u32 = 156_250_000; // Hz

const REG_STATE: u32 = 0x0;
const REG_PULSE_WIDTH_POS: u32 = 0x4;
const REG_PULSE_WIDTH_RTZ: u32 = 0x8;
const REG_PULSE_WIDTH_NEG: u32 = 0xC;
const REG_PULSE_WIDTH_DELAYRAMP: u32 = 0x10;
const REG_PULSE_WIDTH_RECV: u32 = 0x14;

pub struct Pulser {
    pub mem: xfcp::MemoryNode,
    pub offset: u32,
}

impl Pulser {
    pub async fn setup(
        &self,
        interface: &mut xfcp::Interface,
        frequency_mhz: f32,
        recv_time_us: u32,
        delay_ramp_us: u32,
    ) -> Result<(), io::Error> {
        let period_s = 1. / frequency_mhz / 1e6;
        let half_per_cycles = period_s * CLK_RATE as f32 / 2.;
        let time_per = (half_per_cycles / 2.) as u32;

        let recv_time_cycles = (recv_time_us as f32 * CLK_RATE as f32 / 1e6) as u16;
        let delay_ramp_cycles = (delay_ramp_us as f32 * CLK_RATE as f32 / 1e6) as u16;

        self.mem
            .write(
                interface,
                self.offset + REG_PULSE_WIDTH_POS,
                &time_per.to_le_bytes(),
            )
            .await?;
        self.mem
            .write(
                interface,
                self.offset + REG_PULSE_WIDTH_RTZ,
                &time_per.to_le_bytes(),
            )
            .await?;
        self.mem
            .write(
                interface,
                self.offset + REG_PULSE_WIDTH_NEG,
                &time_per.to_le_bytes(),
            )
            .await?;
        self.mem
            .write(
                interface,
                self.offset + REG_PULSE_WIDTH_DELAYRAMP,
                &delay_ramp_cycles.to_le_bytes(),
            )
            .await?;
        self.mem
            .write(
                interface,
                self.offset + REG_PULSE_WIDTH_RECV,
                &recv_time_cycles.to_le_bytes(),
            )
            .await?;
        Ok(())
    }

    pub async fn get_state(&self, interface: &mut xfcp::Interface) -> Result<u32, io::Error> {
        let buf = self.mem.read(interface, self.offset + REG_STATE, 4).await?;
        Ok(u32::from_le_bytes(buf.try_into().unwrap()))
    }

    pub async fn arm(&self, interface: &mut xfcp::Interface) -> Result<(), io::Error> {
        self.mem
            .write(interface, self.offset + REG_STATE, &1u32.to_le_bytes())
            .await?;
        Ok(())
    }
    pub async fn disarm(&self, interface: &mut xfcp::Interface) -> Result<(), io::Error> {
        self.mem
            .write(interface, self.offset + REG_STATE, &0u32.to_le_bytes())
            .await?;
        Ok(())
    }

    pub async fn start(&self, interface: &mut xfcp::Interface) -> Result<(), io::Error> {
        self.mem
            .write(interface, self.offset + REG_STATE, &2u32.to_le_bytes())
            .await?;
        Ok(())
    }
}
