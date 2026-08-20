use std::io;

use crate::xfcp;

const CLK_RATE: u32 = 156_250_000; // Hz

const REG_STATE: u32 = 0x0;
const REG_PULSE_WIDTH_POS: u32 = 0x4;
const REG_PULSE_WIDTH_RTZ: u32 = 0x8;
const REG_PULSE_WIDTH_NEG: u32 = 0xC;
const REG_PULSE_WIDTH_DELAYRAMP: u32 = 0x10;
const REG_PULSE_WIDTH_RECV: u32 = 0x14;
const REG_PULSE_WIDTH_IDLE: u32 = 0x18;
const REG_NUM_SCANLINES: u32 = 0x1C;

/// Per-channel per-scanline delay table: one 0x400 block per channel,
/// 16-bit registers on a 4-byte stride within it. Entry address:
/// 0x400 + channel*0x400 + scanline*4
/// (0x400 = ch0/sl0, 0x808 = ch1/sl2), up to 256 scanlines.
const DELAY_TABLE_BASE: u32 = 0x400;
const DELAY_TABLE_CHANNEL_STRIDE: u32 = 0x400;
const DELAY_TABLE_SCANLINE_STRIDE: u32 = 4;

pub const MAX_SCANLINES: usize = 256;

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

    /// How long after recv to wait before the next scanline.
    pub async fn set_idle_time(
        &self,
        interface: &mut xfcp::Interface,
        idle_us: f32,
    ) -> Result<(), io::Error> {
        let idle_cycles = (idle_us * CLK_RATE as f32 / 1e6) as u32;
        self.mem
            .write(
                interface,
                self.offset + REG_PULSE_WIDTH_IDLE,
                &idle_cycles.to_le_bytes(),
            )
            .await
    }

    /// How many scanlines make up a frame.
    pub async fn set_num_scanlines(
        &self,
        interface: &mut xfcp::Interface,
        num_scanlines: u32,
    ) -> Result<(), io::Error> {
        self.mem
            .write(
                interface,
                self.offset + REG_NUM_SCANLINES,
                &num_scanlines.to_le_bytes(),
            )
            .await
    }

    /// Writes the per-channel delay table: one row of 8 channel delays
    /// (in clock cycles) per scanline.
    pub async fn write_delay_table(
        &self,
        interface: &mut xfcp::Interface,
        delays: &[[u16; 8]],
    ) -> Result<(), io::Error> {
        if delays.len() > MAX_SCANLINES {
            return Err(io::Error::other(format!(
                "delay table has {} scanlines, max is {MAX_SCANLINES}",
                delays.len()
            )));
        }
        for (scanline, channel_delays) in delays.iter().enumerate() {
            for (channel, delay) in channel_delays.iter().enumerate() {
                // one 16-bit write per entry: the upper 2 bytes of each
                // 4-byte slot aren't backed by a register
                let addr = self.offset
                    + DELAY_TABLE_BASE
                    + channel as u32 * DELAY_TABLE_CHANNEL_STRIDE
                    + scanline as u32 * DELAY_TABLE_SCANLINE_STRIDE;
                self.mem.write(interface, addr, &delay.to_le_bytes()).await?;
            }
        }
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
