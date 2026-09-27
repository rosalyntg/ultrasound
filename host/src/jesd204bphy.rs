// register map from PG198 (v4.1) "JESD204 PHY LogiCORE IP Product Guide", chapter 2

use std::{io, time::Duration};

use tokio::time::sleep;

use crate::xfcp;

const REG_VERSION: u32 = 0x000;
const REG_IP_CONFIG: u32 = 0x004;
const REG_NUM_COMMON: u32 = 0x008;
const REG_NUM_TRANSCEIVER: u32 = 0x00C;
const REG_TIMEOUT_ENABLE: u32 = 0x014;
const REG_TIMEOUT_VALUE: u32 = 0x01C;
const REG_COMMON_SEL: u32 = 0x020;
const REG_GT_SEL: u32 = 0x024;
const REG_RX_MASTER_CHAN: u32 = 0x030;
const REG_RX_LINE_CODING: u32 = 0x038;
const REG_PLL_STATUS: u32 = 0x080;
const REG_RX_LINE_RATE: u32 = 0x090; // kHz
const REG_RX_REFCLK: u32 = 0x098; // kHz
const REG_RX_XMULT: u32 = 0x09C; // linerate/refclk * 1000
const REG_RX_PLL: u32 = 0x0A0;
const REG_SW_CAPABLE: u32 = 0x0D0;
const REG_INS_LOSS: u32 = 0x0D4; // dB * 1000
const REG_EQUALISATION: u32 = 0x0D8;
const REG_MIN_RATE: u32 = 0x0E0; // kHz
const REG_MAX_RATE: u32 = 0x0E4; // kHz
const REG_DRPCLK: u32 = 0x0E8; // kHz

// common QPLL control, indexed by REG_COMMON_SEL
const REG_QPLL0_PD: u32 = 0x304;
const REG_QPLL1_PD: u32 = 0x308;

// transceiver control banks, indexed by REG_GT_SEL
const REG_RXPD: u32 = 0x404;
const REG_CPLLPD: u32 = 0x408;
const REG_RX_PLL_CLK_SEL: u32 = 0x410;
const REG_LOOPBACK: u32 = 0x41C;
const REG_RX_SYS_RESET: u32 = 0x424; // single register, any index
const REG_RXPOLARITY: u32 = 0x604;
const REG_RXLPMEN: u32 = 0x608;
const REG_RX_INVALID_SH_MAX: u32 = 0x610; // 64b66b RX only

pub struct Jesd204bPhy {
    pub mem: xfcp::MemoryNode,
    pub offset: u32,
    pub rst: crate::xgpio::GpioPin,
}

fn yes_no(b: bool) -> &'static str {
    if b { "yes" } else { "no" }
}

fn gt_type(t: u32) -> &'static str {
    match t {
        5 => "GTHE3",
        6 => "GTYE3",
        7 => "GTHE4",
        8 => "GTYE4",
        _ => "unknown",
    }
}

fn fpga_type(t: u32) -> &'static str {
    match t {
        1 => "UltraScale",
        2 => "UltraScale+",
        _ => "unknown",
    }
}

fn line_coding(c: u32) -> &'static str {
    if c & 1 != 0 { "64b66b" } else { "8b10b" }
}

fn pll_name(p: u32) -> &'static str {
    // generation-default PLL registers: 0=CPLL, 1=QPLL0, 2=QPLL1
    match p & 0x3 {
        0 => "CPLL",
        1 => "QPLL0",
        2 => "QPLL1",
        _ => "unknown",
    }
}

fn pll_clk_sel(s: u32) -> &'static str {
    // runtime PLL clock select registers: 00=CPLL, 10=QPLL1, 11=QPLL0
    match s & 0x3 {
        0b00 => "CPLL",
        0b10 => "QPLL1",
        0b11 => "QPLL0",
        _ => "reserved",
    }
}

fn loopback_mode(m: u32) -> &'static str {
    match m & 0x7 {
        0b000 => "normal operation",
        0b001 => "near-end PCS",
        0b010 => "near-end PMA",
        0b100 => "far-end PMA",
        0b110 => "far-end PCS",
        _ => "reserved",
    }
}

impl Jesd204bPhy {
    async fn read_reg(&self, interface: &mut xfcp::Interface, addr: u32) -> io::Result<u32> {
        let buf = self.mem.read(interface, self.offset + addr, 4).await?;
        Ok(u32::from_le_bytes(buf.try_into().unwrap()))
    }

    async fn write_reg(
        &self,
        interface: &mut xfcp::Interface,
        addr: u32,
        val: u32,
    ) -> io::Result<()> {
        self.mem
            .write(interface, self.offset + addr, &val.to_le_bytes())
            .await
    }

    pub async fn setup(&self, interface: &mut xfcp::Interface) -> io::Result<()> {
        for gt in 0..self.num_gt(interface).await? {
            self.write_reg(interface, REG_GT_SEL, gt).await?;
            self.write_reg(interface, REG_RXPOLARITY, 1).await?;
        }


        // reset PHY after clk bringup
        self.rst.set(interface).await?;
        sleep(Duration::from_millis(50)).await;
        self.rst.clear(interface).await?;

        Ok(())
    }

    pub async fn status(&self, interface: &mut xfcp::Interface) -> io::Result<()> {
        let version = self.read_reg(interface, REG_VERSION).await?;
        let config = self.read_reg(interface, REG_IP_CONFIG).await?;
        let num_common = self.read_reg(interface, REG_NUM_COMMON).await?;
        let num_gt = self.num_gt(interface).await?;

        println!("JESD204 PHY @ 0x{:x}", self.offset);
        println!(
            "  ip version:         {}.{}.{}",
            version >> 24,
            (version >> 16) & 0xff,
            (version >> 8) & 0xff,
        );
        println!(
            "  fpga:               {} speed grade code {}, {} transceivers",
            fpga_type(config >> 24),
            (config >> 16) & 0xff,
            gt_type(config & 0xff),
        );
        println!("  common blocks:      {num_common}");
        println!("  transceivers:       {num_gt}");

        let timeout_ena = self.read_reg(interface, REG_TIMEOUT_ENABLE).await?;
        let timeout_val = self.read_reg(interface, REG_TIMEOUT_VALUE).await?;
        println!(
            "  axi timeout:        enabled: {}, value: {}",
            yes_no(timeout_ena & 1 != 0),
            timeout_val & 0xfff,
        );

        let rx_master = self.read_reg(interface, REG_RX_MASTER_CHAN).await?;
        println!("  rx master channel:  {}", rx_master & 0xf);

        let rx_coding = self.read_reg(interface, REG_RX_LINE_CODING).await?;
        println!("  rx line coding:     {}", line_coding(rx_coding));

        // note: PLL lock bits are inverted (0 = locked)
        let pll_status = self.read_reg(interface, REG_PLL_STATUS).await?;
        println!(
            "  pll status:         cpll locked: {}, qpll0 locked: {}, qpll1 locked: {}, rx reset in progress: {}",
            yes_no(pll_status & (1 << 2) == 0),
            yes_no(pll_status & (1 << 1) == 0),
            yes_no(pll_status & (1 << 0) == 0),
            yes_no(pll_status & (1 << 3) != 0),
        );

        // generation-time defaults
        let rx_line_rate = self.read_reg(interface, REG_RX_LINE_RATE).await?;
        let rx_refclk = self.read_reg(interface, REG_RX_REFCLK).await?;
        let rx_xmult = self.read_reg(interface, REG_RX_XMULT).await?;
        let rx_pll = self.read_reg(interface, REG_RX_PLL).await?;
        println!(
            "  rx line rate:       {:.3} Gb/s ({:.3} MHz refclk x {:.3}, {})",
            rx_line_rate as f64 / 1e6,
            rx_refclk as f64 / 1e3,
            rx_xmult as f64 / 1e3,
            pll_name(rx_pll),
        );

        let min_rate = self.read_reg(interface, REG_MIN_RATE).await?;
        let max_rate = self.read_reg(interface, REG_MAX_RATE).await?;
        let sw_capable = self.read_reg(interface, REG_SW_CAPABLE).await?;
        println!(
            "  rate range:         {:.3} to {:.3} Gb/s, rate switching capable: {}",
            min_rate as f64 / 1e6,
            max_rate as f64 / 1e6,
            yes_no(sw_capable & 1 != 0),
        );

        let ins_loss = self.read_reg(interface, REG_INS_LOSS).await?;
        let equalisation = self.read_reg(interface, REG_EQUALISATION).await?;
        println!(
            "  rx equalization:    {}, insertion loss: {:.3} dB",
            match equalisation & 0x3 {
                0 => "auto",
                1 => "low loss (LPM)",
                2 => "high loss (DFE)",
                _ => "unknown",
            },
            ins_loss as f64 / 1e3,
        );

        let drpclk = self.read_reg(interface, REG_DRPCLK).await?;
        println!("  drp clock:          {:.3} MHz", drpclk as f64 / 1e3);

        for common in 0..num_common {
            self.write_reg(interface, REG_COMMON_SEL, common).await?;
            let qpll0_pd = self.read_reg(interface, REG_QPLL0_PD).await?;
            let qpll1_pd = self.read_reg(interface, REG_QPLL1_PD).await?;
            println!(
                "  common {common}:           qpll0 powered down: {}, qpll1 powered down: {}",
                yes_no(qpll0_pd & 1 != 0),
                yes_no(qpll1_pd & 1 != 0),
            );
        }

        for gt in 0..num_gt {
            self.write_reg(interface, REG_GT_SEL, gt).await?;

            let rxpd = self.read_reg(interface, REG_RXPD).await?;
            let cpllpd = self.read_reg(interface, REG_CPLLPD).await?;
            let rx_pll_sel = self.read_reg(interface, REG_RX_PLL_CLK_SEL).await?;
            let loopback = self.read_reg(interface, REG_LOOPBACK).await?;
            let rxpolarity = self.read_reg(interface, REG_RXPOLARITY).await?;
            let rxlpmen = self.read_reg(interface, REG_RXLPMEN).await?;

            println!("  transceiver {gt}:");
            println!(
                "    rx powered down: {}, cpll powered down: {}",
                yes_no(rxpd & 0x3 != 0),
                yes_no(cpllpd & 1 != 0),
            );
            println!("    rx pll:          {}", pll_clk_sel(rx_pll_sel));
            println!("    loopback:        {}", loopback_mode(loopback));
            println!(
                "    rx polarity inverted: {}, rx lpm equalizer: {}",
                yes_no(rxpolarity & 1 != 0),
                yes_no(rxlpmen & 1 != 0),
            );
            if rx_coding & 1 != 0 {
                let sh_max = self.read_reg(interface, REG_RX_INVALID_SH_MAX).await?;
                println!("    rx invalid sync header max: {sh_max}");
            }
        }

        // single register shared by all transceivers, readable at any index
        let rx_sys_reset = self.read_reg(interface, REG_RX_SYS_RESET).await?;
        println!(
            "  rx system reset:    asserted: {}",
            yes_no(rx_sys_reset & 1 != 0),
        );

        Ok(())
    }

    async fn num_gt(&self, interface: &mut xfcp::Interface) -> Result<u32, io::Error> {
        Ok(self.read_reg(interface, REG_NUM_TRANSCEIVER).await?)
    }
}
