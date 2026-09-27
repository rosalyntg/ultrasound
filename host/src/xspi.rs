// Driver for the Xilinx AXI Quad SPI core in standard SPI master mode (PG153).
// The interrupt line is not wired up, so transfer completion is detected by
// polling the status register.

use crate::xfcp::{Interface, MemoryNode};
use std::io;

// register offsets (PG153 table 4)
const SRR: u32 = 0x40; // software reset register
const SPICR: u32 = 0x60; // control register
const SPISR: u32 = 0x64; // status register
const SPIDTR: u32 = 0x68; // data transmit register / FIFO
const SPIDRR: u32 = 0x6C; // data receive register / FIFO
const SPISSR: u32 = 0x70; // slave select register

// writing any other value to SRR gives undefined results
const SRR_RESET: u32 = 0x0000_000A;

// SPICR bits
const CR_LOOP: u32 = 1 << 0;
const CR_SPE: u32 = 1 << 1;
const CR_MASTER: u32 = 1 << 2;
const CR_CPOL: u32 = 1 << 3;
const CR_CPHA: u32 = 1 << 4;
const CR_TX_FIFO_RESET: u32 = 1 << 5;
const CR_RX_FIFO_RESET: u32 = 1 << 6;
const CR_MANUAL_SS: u32 = 1 << 7;
const CR_TRANS_INHIBIT: u32 = 1 << 8;

// SPISR bits
const SR_RX_EMPTY: u32 = 1 << 0;
const SR_TX_EMPTY: u32 = 1 << 2;

// max bytes queued per burst; set to 1 if the core is built without FIFOs
const FIFO_DEPTH: usize = 16;

// each poll is a full xfcp round trip, so this is generous
const POLL_LIMIT: u32 = 100;

pub struct XSpi {
    pub node: MemoryNode,
    pub offset: u32,
    pub cpol: bool,
    pub cpha: bool,
}

impl XSpi {
    async fn read_reg(&self, interface: &mut Interface, reg: u32) -> Result<u32, io::Error> {
        let data = self.node.read(interface, self.offset + reg, 4).await?;
        Ok(u32::from_le_bytes(data.try_into().unwrap()))
    }

    async fn write_reg(
        &self,
        interface: &mut Interface,
        reg: u32,
        val: u32,
    ) -> Result<(), io::Error> {
        self.node.write(interface, self.offset + reg, &val.to_le_bytes()).await
    }

    fn cr_base(&self) -> u32 {
        CR_MASTER
            | CR_MANUAL_SS
            | if self.cpol { CR_CPOL } else { 0 }
            | if self.cpha { CR_CPHA } else { 0 }
    }

    pub async fn init(&self, interface: &mut Interface) -> Result<(), io::Error> {
        self.write_reg(interface, SRR, SRR_RESET).await?;
        self.write_reg(interface, SPISSR, 0xFFFF_FFFF).await?;
        self.write_reg(interface, SPICR, self.cr_base() | CR_TRANS_INHIBIT).await?;
        Ok(())
    }

    /// Full-duplex transfer: shifts out `mosi` with slave select `slave`
    /// (index, active-low one-hot in SPISSR) asserted for the whole transfer,
    /// and returns the bytes shifted in on MISO.
    pub async fn transfer(
        &self,
        interface: &mut Interface,
        slave: u32,
        mosi: &[u8],
    ) -> Result<Vec<u8>, io::Error> {
        let mut miso = Vec::with_capacity(mosi.len());

        // enable the core with transactions inhibited and both FIFOs cleared
        self.write_reg(
            interface,
            SPICR,
            self.cr_base() | CR_SPE | CR_TRANS_INHIBIT | CR_TX_FIFO_RESET | CR_RX_FIFO_RESET,
        )
        .await?;
        // manual slave select mode: SS output follows SPISSR while enabled
        self.write_reg(interface, SPISSR, !(1u32 << slave)).await?;

        for chunk in mosi.chunks(FIFO_DEPTH) {
            for &b in chunk {
                self.write_reg(interface, SPIDTR, b as u32).await?;
            }
            // release the inhibit to start shifting the burst out
            self.write_reg(interface, SPICR, self.cr_base() | CR_SPE).await?;

            // no interrupt available: poll until one rx byte has arrived for
            // every tx byte, which also means the shift is fully complete
            // (TX_EMPTY alone still has the last byte in the pipeline)
            let mut got = 0;
            let mut polls = 0;
            while got < chunk.len() {
                if self.read_reg(interface, SPISR).await? & SR_RX_EMPTY == 0 {
                    miso.push(self.read_reg(interface, SPIDRR).await? as u8);
                    got += 1;
                } else {
                    polls += 1;
                    if polls > POLL_LIMIT {
                        return Err(io::Error::new(
                            io::ErrorKind::TimedOut,
                            "SPI transfer did not complete",
                        ));
                    }
                }
            }

            // burst done; inhibit again so the next chunk can be queued
            self.write_reg(interface, SPICR, self.cr_base() | CR_SPE | CR_TRANS_INHIBIT)
                .await?;
        }

        // deassert slave select, then disable the core
        self.write_reg(interface, SPISSR, 0xFFFF_FFFF).await?;
        self.write_reg(interface, SPICR, self.cr_base() | CR_TRANS_INHIBIT).await?;

        Ok(miso)
    }

    /// Write-only transfer; received bytes are discarded.
    pub async fn write(
        &self,
        interface: &mut Interface,
        slave: u32,
        data: &[u8],
    ) -> Result<(), io::Error> {
        self.transfer(interface, slave, data).await?;
        Ok(())
    }
}
