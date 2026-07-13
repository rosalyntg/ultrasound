use std::{io, time::Duration};

use tokio::time::sleep;

use crate::{xfcp, xspi};

pub struct Ad34jx {
    pub spi: xspi::XSpi,
    pub cs: u32,
}

pub enum Mode {
    Lmfs2441, // 20x mode
    Lmfs4421, // 10x mode
}

impl Ad34jx {
    pub async fn write_reg(
        &self,
        interface: &mut xfcp::Interface,
        reg: u16,
        data: u8,
    ) -> Result<(), io::Error> {
        assert!(reg <= 0x3fff);

        let [reg_hi, reg_lo] = reg.to_be_bytes();
        let data = [reg_hi | 0b0100_0000, reg_lo, data];
        self.spi.write(interface, self.cs, &data).await
    }
    pub async fn read_reg(&self, interface: &mut xfcp::Interface, reg: u16) -> Result<u8, io::Error> {
        assert!(reg <= 0x3fff);

        let [reg_hi, reg_lo] = reg.to_be_bytes();
        let data = [reg_hi | 0b1100_0000, reg_lo, 0x00];
        let response = self.spi.transfer(interface, self.cs, &data).await?;
        Ok(response[2])
    }

    pub async fn init(
        &self,
        interface: &mut xfcp::Interface,
        mode: Mode,
    ) -> Result<(), std::io::Error> {
        self.write_reg(interface, 0x40, 0xa).await?; // reset
        sleep(Duration::from_millis(100)).await;

        if let Mode::Lmfs2441 = mode {
            self.write_reg(interface, 0x2b, 0x01).await?;
            self.write_reg(interface, 0x30, 0x11).await?;
        }

        Ok(())
    }
    
    pub async fn sw_sync(&self, interface: &mut xfcp::Interface) -> Result<(), io::Error> {
        self.write_reg(interface, 0x3a, 1 << 6).await?; // SYNC REQ EN
        self.write_reg(interface, 0x3a, 1 << 7).await?; // SYNC REQ
        Ok(())
    }

    pub async fn test_pattern(&self, interface: &mut xfcp::Interface, enable: bool) -> Result<(), io::Error> {
        if enable {
            // self.write_reg(interface, 0x2a, 0b0110_00000).await?;
            self.write_reg(interface, 0x0a, 0b00110011).await?;
            self.write_reg(interface, 0x0b, 0b00110011).await?;
            self.write_reg(interface, 0x06, 0b10).await?;

        } else {
            todo!();
        }
        Ok(())
    }

    pub async fn link_test(&self, interface: &mut xfcp::Interface) -> Result<(), io::Error> {
        self.write_reg(interface, 0x2f, 0b0010_0000).await?; // LINK TEST
        Ok(())
    }
}
