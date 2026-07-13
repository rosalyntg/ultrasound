use crate::xfcp::MemoryNode;

const CHAN_OFFSET: u32 = 8;

#[derive(Clone)]
pub struct XGpio {
    pub node: MemoryNode,
    pub offset: u32,
    pub width: [u32; 2],
}

#[derive(Clone)]
pub struct GpioPin {
    pub gpio: XGpio,
    pub ch: u8,
    pub pin: u32,
}

impl XGpio {
    pub async fn set_pin(
        &self,
        interface: &mut crate::xfcp::Interface,
        ch: u8,
        pin: u32,
    ) -> Result<(), std::io::Error> {
        assert!(pin < self.width[usize::from(ch)], "Pin index out of range for channel {} ({} pins, wnated {})", ch, self.width[usize::from(ch)], pin);
        let mut data = self
            .node
            .read(interface, self.offset + u32::from(ch) * CHAN_OFFSET, 4)
            .await?;
        let mut val = u32::from_le_bytes(data.try_into().unwrap());
        val |= 1 << pin;
        data = val.to_le_bytes().to_vec();
        self.node
            .write(interface, self.offset + u32::from(ch) * CHAN_OFFSET, &data)
            .await?;
        Ok(())
    }

    pub async fn clear_pin(
        &self,
        interface: &mut crate::xfcp::Interface,
        ch: u8,
        pin: u32,
    ) -> Result<(), std::io::Error> {
        assert!(pin < self.width[usize::from(ch)]);
        let mut data = self
            .node
            .read(interface, self.offset + u32::from(ch) * CHAN_OFFSET, 4)
            .await?;
        let mut val = u32::from_le_bytes(data.try_into().unwrap());
        val &= !(1 << pin);
        data = val.to_le_bytes().to_vec();
        self.node
            .write(interface, self.offset + u32::from(ch) * CHAN_OFFSET, &data)
            .await?;
        Ok(())
    }
}

impl GpioPin {
    pub async fn set(&self, interface: &mut crate::xfcp::Interface) -> Result<(), std::io::Error> {
        self.gpio.set_pin(interface, self.ch, self.pin).await
    }

    pub async fn clear(
        &self,
        interface: &mut crate::xfcp::Interface,
    ) -> Result<(), std::io::Error> {
        self.gpio.clear_pin(interface, self.ch, self.pin).await
    }
}
