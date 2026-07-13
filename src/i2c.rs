use crate::xgpio::GpioPin;

#[async_trait::async_trait]
pub trait I2c {
    async fn read(
        &self,
        interface: &mut crate::xfcp::Interface,
        address: u8,
        length: u8,
    ) -> Result<Vec<u8>, std::io::Error>;
    async fn write(
        &self,
        interface: &mut crate::xfcp::Interface,
        address: u8,
        data: &[u8],
    ) -> Result<(), std::io::Error>;
}

pub struct FlippedI2c<T> {
    pub i2c: T,
    pub flip_gpio: GpioPin,
    pub flipped: bool,
}

impl<T> FlippedI2c<T> where T: Clone + I2c {
    // returns (not flipped, flipped)
    pub fn new(i2c: T, flip_gpio: GpioPin) -> (Self, Self) {
        (
            Self {
                i2c: i2c.clone(),
                flip_gpio: flip_gpio.clone(),
                flipped: false,
            },
            Self {
                i2c,
                flip_gpio,
                flipped: true,
            },
        )
    }
}

#[async_trait::async_trait]
impl<T> I2c for FlippedI2c<T>
where
    T: I2c + Sync,
{
    async fn read(
        &self,
        interface: &mut crate::xfcp::Interface,
        address: u8,
        length: u8,
    ) -> Result<Vec<u8>, std::io::Error> {
        if self.flipped {
            self.flip_gpio.set(interface).await?;
        } else {
            self.flip_gpio.clear(interface).await?;
        }
        self.i2c.read(interface, address, length).await
    }

    async fn write(
        &self,
        interface: &mut crate::xfcp::Interface,
        address: u8,
        data: &[u8],
    ) -> Result<(), std::io::Error> {
        if self.flipped {
            self.flip_gpio.set(interface).await?;
        } else {
            self.flip_gpio.clear(interface).await?;
        }
        self.i2c.write(interface, address, data).await
    }
}
