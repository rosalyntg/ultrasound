use crate::xfcp::MemoryNode;

pub struct XGpio {
    pub node: MemoryNode,
    pub offset: u32,
    pub width: u32,
}

impl XGpio {
    pub async fn set_pin(&self, interface: &mut crate::xfcp::Interface, pin: u32) -> Result<(), std::io::Error> {
        assert!(pin < self.width);
        let mut data = self.node.read(interface, self.offset, 4).await?;
        let mut val = u32::from_le_bytes(data.try_into().unwrap());
        val |= 1 << pin;
        data = val.to_le_bytes().to_vec();
        self.node.write(interface, self.offset, &data).await?;
        Ok(())
    }

    pub async fn clear_pin(&self, interface: &mut crate::xfcp::Interface, pin: u32) -> Result<(), std::io::Error> {
        assert!(pin < self.width);
        let mut data = self.node.read(interface, self.offset, 4).await?;
        let mut val = u32::from_le_bytes(data.try_into().unwrap());
        val &= !(1 << pin);
        data = val.to_le_bytes().to_vec();
        self.node.write(interface, self.offset, &data).await?;
        Ok(())
    }
}
