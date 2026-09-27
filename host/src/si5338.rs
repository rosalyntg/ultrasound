use std::time::Duration;

use tokio::time::sleep;

use crate::{i2c::I2c, xfcp};

const CLK_IN_RATE: u32 = 25_000_000; // Hz

pub struct Si5338 {
    pub i2c: xfcp::I2CNode,
    pub address: u8,
}

impl Si5338 {
    pub async fn rev_id(&self, interface: &mut xfcp::Interface) -> Result<u8, std::io::Error> {
        Ok(self
            .i2c
            .read_at_offset_1b(interface, self.address, 0, 1)
            .await?[0])
    }
    pub async fn device_config(
        &self,
        interface: &mut xfcp::Interface,
    ) -> Result<[u8; 4], std::io::Error> {
        Ok(self
            .i2c
            .read_at_offset_1b(interface, self.address, 0, 4)
            .await?
            .try_into()
            .unwrap())
    }
    pub async fn status(&self, interface: &mut xfcp::Interface) -> Result<u8, std::io::Error> {
        Ok(self
            .i2c
            .read_at_offset_1b(interface, self.address, 218, 1)
            .await?[0])
    }
    pub async fn sticky_status(
        &self,
        interface: &mut xfcp::Interface,
    ) -> Result<u8, std::io::Error> {
        Ok(self
            .i2c
            .read_at_offset_1b(interface, self.address, 247, 1)
            .await?[0])
    }

    /// Read every status-relevant register and format them as a
    /// human-readable multi-line report (see Si5338-RM registers 0-6, 31-34,
    /// 45-49, 218, 226, 230, 235-237, 241, 246, 247).
    pub async fn pretty_status(
        &self,
        interface: &mut xfcp::Interface,
    ) -> Result<String, std::io::Error> {
        let id = self
            .i2c
            .read_at_offset_1b(interface, self.address, 0, 7)
            .await?;
        let drv = self
            .i2c
            .read_at_offset_1b(interface, self.address, 31, 4)
            .await?;
        let fcal_ovrd = self
            .i2c
            .read_at_offset_1b(interface, self.address, 45, 5)
            .await?;
        let status = self.status(interface).await?;
        let ms_reset = self
            .i2c
            .read_at_offset_1b(interface, self.address, 226, 1)
            .await?[0];
        let oeb = self
            .i2c
            .read_at_offset_1b(interface, self.address, 230, 1)
            .await?[0];
        let fcal = self
            .i2c
            .read_at_offset_1b(interface, self.address, 235, 3)
            .await?;
        let dis_lol = self
            .i2c
            .read_at_offset_1b(interface, self.address, 241, 1)
            .await?[0];
        let soft_reset = self
            .i2c
            .read_at_offset_1b(interface, self.address, 246, 1)
            .await?[0];
        let sticky = self.sticky_status(interface).await?;

        // Part number decode per Si5338-RM section 10.6.1
        let rev = match id[0] & 0x07 {
            0 => "A".to_string(),
            1 => "B".to_string(),
            n => format!("? ({n})"),
        };
        let base = id[2] & 0x3F; // "38" for Si5338
        let grade = id[3] >> 3; // 1..=24 -> A..=Z
        let grade = if (1..=24).contains(&grade) {
            char::from(b'A' + grade - 1)
        } else {
            '?'
        };
        let nvm = ((id[3] as u32 & 1) << 16) | ((id[4] as u32) << 8) | id[5] as u32;

        // Registers 218/247/6: D4 PLL_LOL, D3 LOS_FDBK, D2 LOS_CLKIN,
        // D0 SYS_CAL (247 = sticky versions, 6 = interrupt masks)
        let masks = id[6];
        let line = |name: &str, bit: u8, ok: &str, bad: &str| {
            format!(
                "  {name:<16} {:<15} sticky: {:<15} irq: {}\n",
                if status & (1 << bit) != 0 { bad } else { ok },
                if sticky & (1 << bit) != 0 { bad } else { ok },
                if masks & (1 << bit) != 0 {
                    "masked"
                } else {
                    "enabled"
                },
            )
        };

        let mut out = String::new();
        out += &format!("Si53{base:02}{grade} rev {rev}, NVM code {nvm:05}\n");
        out += &format!(
            "alarms: reg 218 = {status:#010b}, sticky reg 247 = {sticky:#010b}, irq mask reg 6 = {masks:#010b}\n"
        );
        out += &line("PLL:", 4, "locked", "LOSS OF LOCK");
        out += &line("feedback clock:", 3, "ok", "LOSS OF SIGNAL");
        out += &line("input clock:", 2, "ok", "LOSS OF SIGNAL");
        out += &line("calibration:", 0, "done", "IN PROGRESS");

        // PLL/reset machinery: reg 49[7] FCAL_OVRD_EN, regs 235-237 measured
        // FCAL vs regs 45-47 override values, reg 241[7] DIS_LOL,
        // reg 246[1] SOFT_RESET, reg 226[2] MS_RESET
        let fcal_meas = ((fcal[2] as u32 & 0x03) << 16) | ((fcal[1] as u32) << 8) | fcal[0] as u32;
        let fcal_over = ((fcal_ovrd[2] as u32 & 0x03) << 16)
            | ((fcal_ovrd[1] as u32) << 8)
            | fcal_ovrd[0] as u32;
        out += &format!(
            "pll: FCAL override {} (measured {fcal_meas:#07x}, override {fcal_over:#07x}), \
             LOL detection {}, soft reset {}, MS reset {}\n",
            if fcal_ovrd[4] & 0x80 != 0 {
                "ON"
            } else {
                "off"
            },
            if dis_lol & 0x80 != 0 {
                "DISABLED"
            } else {
                "enabled"
            },
            if soft_reset & 0x02 != 0 {
                "PENDING"
            } else {
                "idle"
            },
            if ms_reset & 0x04 != 0 {
                "ASSERTED"
            } else {
                "idle"
            },
        );

        // Outputs: reg 230 output-enable bars, regs 31-34 per-output R divider
        // input mux / divide ratio and power-down bits
        out += &format!(
            "outputs: reg 230 = {oeb:#04x}, all-output enable: {}\n",
            if oeb & 0x10 != 0 {
                "DISABLED (OEB_ALL)"
            } else {
                "enabled"
            },
        );
        for i in 0..4 {
            let d = drv[i];
            let mux = match d >> 5 {
                0b000 => "fbclk",
                0b001 => "refclk",
                0b010 => "P2 divider",
                0b011 => "P1 divider",
                0b100 => "xoclk",
                0b101 | 0b110 => "MultiSynth",
                _ => "no clock",
            };
            let rdiv = 1u8 << ((d >> 2) & 0x07).min(5);
            out += &format!(
                "  CLK{i}: {}, driver {}, MultiSynth {}, source {mux} / {rdiv}\n",
                if oeb & (1 << i) != 0 {
                    "DISABLED (OEB)"
                } else {
                    "enabled"
                },
                if d & 0x01 != 0 { "POWERED DOWN" } else { "up" },
                if d & 0x02 != 0 { "POWERED DOWN" } else { "up" },
            );
        }
        Ok(out)
    }

    async fn write_masked(
        &self,
        interface: &mut xfcp::Interface,
        addr: u8,
        val: u8,
        mask: u8,
    ) -> Result<(), std::io::Error> {
        let cur = self
            .i2c
            .read_at_offset_1b(interface, self.address, addr, 1)
            .await?;
        let new_val = (cur[0] & !mask) | (val & mask);
        self.i2c
            .write(interface, self.address, &[addr, new_val])
            .await
    }

    async fn wait_status_clear(
        &self,
        interface: &mut xfcp::Interface,
        mask: u8,
    ) -> Result<(), std::io::Error> {
        for _ in 0..100 {
            if self.status(interface).await? & mask == 0 {
                return Ok(());
            }
            sleep(Duration::from_millis(5)).await;
        }
        Err(std::io::Error::new(
            std::io::ErrorKind::TimedOut,
            format!("si5338: status bits {mask:#04x} did not clear"),
        ))
    }

    // I2C programming procedure from the Si5338 datasheet, Figure 9. Writing
    // the register map alone leaves the PLL/MultiSynths running on the
    // power-up configuration; the soft reset + FCAL copy is what applies it.
    pub async fn init(&self, interface: &mut xfcp::Interface) -> Result<(), std::io::Error> {
        // disable outputs (OEB_ALL = 1) and pause the LOL state machine
        self.write_masked(interface, 230, 0x10, 0x10).await?;
        self.write_masked(interface, 241, 0x80, 0x80).await?;

        for (addr, val, mask) in REG_STORE {
            self.write_masked(interface, *addr, *val, *mask).await?;
        }

        // wait for a valid input clock (LOS_CLKIN clear; LOS_FDBK is ignored
        // since this config uses the crystal with internal feedback)
        self.wait_status_clear(interface, 0x04).await?;

        // lock the PLL to the new config: FCAL_OVRD_EN = 0, then soft reset
        // (plain write of 0x02, no read-modify-write, per the datasheet)
        self.write_masked(interface, 49, 0x00, 0x80).await?;
        self.i2c
            .write(interface, self.address, &[246, 0x02])
            .await?;
        sleep(Duration::from_millis(25)).await;

        // restart LOL
        self.i2c
            .write(interface, self.address, &[241, 0x65])
            .await?;

        // wait for lock: PLL_LOL, LOS_CLKIN and SYS_CAL all clear
        self.wait_status_clear(interface, 0x15).await?;

        // copy the FCAL values the PLL just calibrated into the override
        // registers and use them from now on (FCAL_OVRD_EN = 1)
        let fcal = self
            .i2c
            .read_at_offset_1b(interface, self.address, 235, 3)
            .await?;
        self.i2c
            .write(interface, self.address, &[45, fcal[0]])
            .await?;
        self.i2c
            .write(interface, self.address, &[46, fcal[1]])
            .await?;
        self.i2c
            .write(
                interface,
                self.address,
                &[47, 0b000101 << 2 | (fcal[2] & 0x03)],
            )
            .await?;
        self.write_masked(interface, 49, 0x80, 0x80).await?;

        // enable outputs (OEB_ALL = 0)
        self.write_masked(interface, 230, 0x00, 0x10).await?;

        Ok(())
    }
}
//Register map for use with AN428 (JumpStart)
//https://www.skyworksinc.com/timing
//#BEGIN_HEADER
//Date = Thursday, July 16, 2026 7:53 PM
//File version = 3
//Software Name = ClockBuilder Pro
//Software version = 4.18.0.0
//Software date = 3 23, 2026
//Chip = Si533x
//Part Number = Si533x
//#END_HEADER
//Input Frequency (MHz) = 25.000000000
//Input Type = Crystal
//P1 = 1
//Input Mux = XoClk
//FDBK Input Frequency (MHz) = 25.000000000
//FDBK Input Type = OFF
//P2 = 1
//FDBK Mux = NoClk
//PFD Input Frequency (MHz) = 25.000000000
//VCO Frequency (GHz) = 2.500000
//N = 100  (100.0000)
//Internal feedback enabled
//Output Clock 0
// Output Frequency (MHz) = 50.000000000
// Mux Selection = IDn
// MultiSynth = 50  (50.0000)
// R = 1
//Output Clock 1
// Output Frequency (MHz) = 100.000000000
// Mux Selection = IDn
// MultiSynth = 25  (25.0000)
// R = 1
//Output Clock 2
// Output Frequency (MHz) = 50.000000000
// Mux Selection = IDn
// MultiSynth = 50  (50.0000)
// R = 1
//Output Clock 3
// Output Frequency (MHz) = 50.000000000
// Mux Selection = IDn
// MultiSynth = 50  (50.0000)
// R = 1
//Driver 0
// Enabled
// Powered on
// Output voltage = 3.30
// Output type = 3.3V LVDS
// Output state when disabled = StopLow
//Driver 1
// Enabled
// Powered on
// Output voltage = 3.30
// Output type = 3.3V LVDS
// Output state when disabled = StopLow
//Driver 2
// Enabled
// Powered on
// Output voltage = 3.30
// Output type = 3.3V LVDS
// Output state when disabled = StopLow
//Driver 3
// Enabled
// Powered on
// Output voltage = 3.30
// Output type = 3.3V LVDS
// Output state when disabled = StopLow
//Clock 0 phase inc/dec step size (ns) = 0.000
//Clock 1 phase inc/dec step size (ns) = 0.000
//Clock 2 phase inc/dec step size (ns) = 0.000
//Clock 3 phase inc/dec step size (ns) = 0.000
//Phase increment and decrement pin control is off
//Frequency increment and decrement pin control is off
//Frequency increment and decrement is disabled
//Initial phase offset 0 (ns) = 0.000
//Initial phase offset 1 (ns) = 0.000
//Initial phase offset 2 (ns) = 0.000
//Initial phase offset 3 (ns) = 0.000
//SSC is disabled

// #define NUM_REGS_MAX 350

// typedef struct Reg_Data{
//    unsigned char Reg_Addr;
//    unsigned char Reg_Val;
//    unsigned char Reg_Mask;
// } Reg_Data;

const REG_STORE: &[(u8, u8, u8)] = &[
    (0, 0x00, 0x00),
    (1, 0x00, 0x00),
    (2, 0x00, 0x00),
    (3, 0x00, 0x00),
    (4, 0x00, 0x00),
    (5, 0x00, 0x00),
    (6, 0x08, 0x1D),
    (7, 0x00, 0x00),
    (8, 0x70, 0x00),
    (9, 0x0F, 0x00),
    (10, 0x00, 0x00),
    (11, 0x00, 0x00),
    (12, 0x00, 0x00),
    (13, 0x00, 0x00),
    (14, 0x00, 0x00),
    (15, 0x00, 0x00),
    (16, 0x00, 0x00),
    (17, 0x00, 0x00),
    (18, 0x00, 0x00),
    (19, 0x00, 0x00),
    (20, 0x00, 0x00),
    (21, 0x00, 0x00),
    (22, 0x00, 0x00),
    (23, 0x00, 0x00),
    (24, 0x00, 0x00),
    (25, 0x00, 0x00),
    (26, 0x00, 0x00),
    (27, 0x70, 0x80),
    (28, 0x16, 0xFF),
    (29, 0x90, 0xFF),
    (30, 0xB0, 0xFF),
    (31, 0xC0, 0xFF),
    (32, 0xC0, 0xFF),
    (33, 0xC0, 0xFF),
    (34, 0xC0, 0xFF),
    (35, 0x00, 0xFF),
    (36, 0x06, 0x1F),
    (37, 0x06, 0x1F),
    (38, 0x06, 0x1F),
    (39, 0x06, 0x1F),
    (40, 0x63, 0xFF),
    (41, 0x0C, 0x7F),
    (42, 0x23, 0x3F),
    (43, 0x00, 0x00),
    (44, 0x00, 0x00),
    (45, 0x00, 0xFF),
    (46, 0x00, 0xFF),
    (47, 0x14, 0x3F),
    (48, 0x3A, 0xFF),
    (49, 0x00, 0xFF),
    (50, 0xC4, 0xFF),
    (51, 0x07, 0xFF),
    (52, 0x10, 0xFF),
    (53, 0x00, 0xFF),
    (54, 0x17, 0xFF),
    (55, 0x00, 0xFF),
    (56, 0x00, 0xFF),
    (57, 0x00, 0xFF),
    (58, 0x00, 0xFF),
    (59, 0x01, 0xFF),
    (60, 0x00, 0xFF),
    (61, 0x00, 0xFF),
    (62, 0x00, 0x3F),
    (63, 0x10, 0xFF),
    (64, 0x80, 0xFF),
    (65, 0x0A, 0xFF),
    (66, 0x00, 0xFF),
    (67, 0x00, 0xFF),
    (68, 0x00, 0xFF),
    (69, 0x00, 0xFF),
    (70, 0x01, 0xFF),
    (71, 0x00, 0xFF),
    (72, 0x00, 0xFF),
    (73, 0x00, 0x3F),
    (74, 0x10, 0xFF),
    (75, 0x00, 0xFF),
    (76, 0x17, 0xFF),
    (77, 0x00, 0xFF),
    (78, 0x00, 0xFF),
    (79, 0x00, 0xFF),
    (80, 0x00, 0xFF),
    (81, 0x01, 0xFF),
    (82, 0x00, 0xFF),
    (83, 0x00, 0xFF),
    (84, 0x00, 0x3F),
    (85, 0x10, 0xFF),
    (86, 0x00, 0xFF),
    (87, 0x17, 0xFF),
    (88, 0x00, 0xFF),
    (89, 0x00, 0xFF),
    (90, 0x00, 0xFF),
    (91, 0x00, 0xFF),
    (92, 0x01, 0xFF),
    (93, 0x00, 0xFF),
    (94, 0x00, 0xFF),
    (95, 0x00, 0x3F),
    (96, 0x10, 0x00),
    (97, 0x00, 0xFF),
    (98, 0x30, 0xFF),
    (99, 0x00, 0xFF),
    (100, 0x00, 0xFF),
    (101, 0x00, 0xFF),
    (102, 0x00, 0xFF),
    (103, 0x01, 0xFF),
    (104, 0x00, 0xFF),
    (105, 0x00, 0xFF),
    (106, 0x80, 0xBF),
    (107, 0x00, 0xFF),
    (108, 0x00, 0xFF),
    (109, 0x00, 0xFF),
    (110, 0x40, 0xFF),
    (111, 0x00, 0xFF),
    (112, 0x00, 0xFF),
    (113, 0x00, 0xFF),
    (114, 0x40, 0xFF),
    (115, 0x00, 0xFF),
    (116, 0x80, 0xFF),
    (117, 0x00, 0xFF),
    (118, 0x40, 0xFF),
    (119, 0x00, 0xFF),
    (120, 0x00, 0xFF),
    (121, 0x00, 0xFF),
    (122, 0x40, 0xFF),
    (123, 0x00, 0xFF),
    (124, 0x00, 0xFF),
    (125, 0x00, 0xFF),
    (126, 0x00, 0xFF),
    (127, 0x00, 0xFF),
    (128, 0x00, 0xFF),
    (129, 0x00, 0x0F),
    (130, 0x00, 0x0F),
    (131, 0x00, 0xFF),
    (132, 0x00, 0xFF),
    (133, 0x00, 0xFF),
    (134, 0x00, 0xFF),
    (135, 0x00, 0xFF),
    (136, 0x00, 0xFF),
    (137, 0x00, 0xFF),
    (138, 0x00, 0xFF),
    (139, 0x00, 0xFF),
    (140, 0x00, 0xFF),
    (141, 0x00, 0xFF),
    (142, 0x00, 0xFF),
    (143, 0x00, 0xFF),
    (144, 0x00, 0xFF),
    (145, 0x00, 0x00),
    (146, 0xFF, 0x00),
    (147, 0x00, 0x00),
    (148, 0x00, 0x00),
    (149, 0x00, 0x00),
    (150, 0x00, 0x00),
    (151, 0x00, 0x00),
    (152, 0x00, 0xFF),
    (153, 0x00, 0xFF),
    (154, 0x00, 0xFF),
    (155, 0x00, 0xFF),
    (156, 0x00, 0xFF),
    (157, 0x00, 0xFF),
    (158, 0x00, 0x0F),
    (159, 0x00, 0x0F),
    (160, 0x00, 0xFF),
    (161, 0x00, 0xFF),
    (162, 0x00, 0xFF),
    (163, 0x00, 0xFF),
    (164, 0x00, 0xFF),
    (165, 0x00, 0xFF),
    (166, 0x00, 0xFF),
    (167, 0x00, 0xFF),
    (168, 0x00, 0xFF),
    (169, 0x00, 0xFF),
    (170, 0x00, 0xFF),
    (171, 0x00, 0xFF),
    (172, 0x00, 0xFF),
    (173, 0x00, 0xFF),
    (174, 0x00, 0xFF),
    (175, 0x00, 0xFF),
    (176, 0x00, 0xFF),
    (177, 0x00, 0xFF),
    (178, 0x00, 0xFF),
    (179, 0x00, 0xFF),
    (180, 0x00, 0xFF),
    (181, 0x00, 0x0F),
    (182, 0x00, 0xFF),
    (183, 0x00, 0xFF),
    (184, 0x00, 0xFF),
    (185, 0x00, 0xFF),
    (186, 0x00, 0xFF),
    (187, 0x00, 0xFF),
    (188, 0x00, 0xFF),
    (189, 0x00, 0xFF),
    (190, 0x00, 0xFF),
    (191, 0x00, 0xFF),
    (192, 0x00, 0xFF),
    (193, 0x00, 0xFF),
    (194, 0x00, 0xFF),
    (195, 0x00, 0xFF),
    (196, 0x00, 0xFF),
    (197, 0x00, 0xFF),
    (198, 0x00, 0xFF),
    (199, 0x00, 0xFF),
    (200, 0x00, 0xFF),
    (201, 0x00, 0xFF),
    (202, 0x00, 0xFF),
    (203, 0x00, 0x0F),
    (204, 0x00, 0xFF),
    (205, 0x00, 0xFF),
    (206, 0x00, 0xFF),
    (207, 0x00, 0xFF),
    (208, 0x00, 0xFF),
    (209, 0x00, 0xFF),
    (210, 0x00, 0xFF),
    (211, 0x00, 0xFF),
    (212, 0x00, 0xFF),
    (213, 0x00, 0xFF),
    (214, 0x00, 0xFF),
    (215, 0x00, 0xFF),
    (216, 0x00, 0xFF),
    (217, 0x00, 0xFF),
    (218, 0x00, 0x00),
    (219, 0x00, 0x00),
    (220, 0x00, 0x00),
    (221, 0x0D, 0x00),
    (222, 0x00, 0x00),
    (223, 0x00, 0x00),
    (224, 0xF4, 0x00),
    (225, 0xF0, 0x00),
    (226, 0x00, 0x00),
    (227, 0x00, 0x00),
    (228, 0x00, 0x00),
    (229, 0x00, 0x00),
    (230, 0x00, 0x0F),
    (231, 0x00, 0x00),
    (232, 0x00, 0x00),
    (233, 0x00, 0x00),
    (234, 0x00, 0x00),
    (235, 0x00, 0x00),
    (236, 0x00, 0x00),
    (237, 0x00, 0x00),
    (238, 0x14, 0x00),
    (239, 0x00, 0x00),
    (240, 0x00, 0x00),
    (242, 0x02, 0x02),
    (243, 0xF0, 0x00),
    (244, 0x00, 0x00),
    (245, 0x00, 0x00),
    (247, 0x00, 0x00),
    (248, 0x00, 0x00),
    (249, 0xA8, 0x00),
    (250, 0x00, 0x00),
    (251, 0x84, 0x00),
    (252, 0x00, 0x00),
    (253, 0x00, 0x00),
    (254, 0x00, 0x00),
    (255, 1, 0xFF), // set page bit to 1
    (0, 0x00, 0x00),
    (1, 0x00, 0x00),
    (2, 0x00, 0x00),
    (3, 0x00, 0x00),
    (4, 0x00, 0x00),
    (5, 0x00, 0x00),
    (6, 0x00, 0x00),
    (7, 0x00, 0x00),
    (8, 0x00, 0x00),
    (9, 0x00, 0x00),
    (10, 0x00, 0x00),
    (11, 0x00, 0x00),
    (12, 0x00, 0x00),
    (13, 0x00, 0x00),
    (14, 0x00, 0x00),
    (15, 0x00, 0x00),
    (16, 0x00, 0x00),
    (17, 0x01, 0x00),
    (18, 0x00, 0x00),
    (19, 0x00, 0x00),
    (20, 0x90, 0x00),
    (21, 0x31, 0x00),
    (22, 0x00, 0x00),
    (23, 0x00, 0x00),
    (24, 0x01, 0x00),
    (25, 0x00, 0x00),
    (26, 0x00, 0x00),
    (27, 0x00, 0x00),
    (28, 0x00, 0x00),
    (29, 0x00, 0x00),
    (30, 0x00, 0x00),
    (31, 0x00, 0xFF),
    (32, 0x00, 0xFF),
    (33, 0x01, 0xFF),
    (34, 0x00, 0xFF),
    (35, 0x00, 0xFF),
    (36, 0x90, 0xFF),
    (37, 0x31, 0xFF),
    (38, 0x00, 0xFF),
    (39, 0x00, 0xFF),
    (40, 0x01, 0xFF),
    (41, 0x00, 0xFF),
    (42, 0x00, 0xFF),
    (43, 0x00, 0x0F),
    (44, 0x00, 0x00),
    (45, 0x00, 0x00),
    (46, 0x00, 0x00),
    (47, 0x00, 0xFF),
    (48, 0x00, 0xFF),
    (49, 0x01, 0xFF),
    (50, 0x00, 0xFF),
    (51, 0x00, 0xFF),
    (52, 0x90, 0xFF),
    (53, 0x31, 0xFF),
    (54, 0x00, 0xFF),
    (55, 0x00, 0xFF),
    (56, 0x01, 0xFF),
    (57, 0x00, 0xFF),
    (58, 0x00, 0xFF),
    (59, 0x00, 0x0F),
    (60, 0x00, 0x00),
    (61, 0x00, 0x00),
    (62, 0x00, 0x00),
    (63, 0x00, 0xFF),
    (64, 0x00, 0xFF),
    (65, 0x01, 0xFF),
    (66, 0x00, 0xFF),
    (67, 0x00, 0xFF),
    (68, 0x90, 0xFF),
    (69, 0x31, 0xFF),
    (70, 0x00, 0xFF),
    (71, 0x00, 0xFF),
    (72, 0x01, 0xFF),
    (73, 0x00, 0xFF),
    (74, 0x00, 0xFF),
    (75, 0x00, 0x0F),
    (76, 0x00, 0x00),
    (77, 0x00, 0x00),
    (78, 0x00, 0x00),
    (79, 0x00, 0xFF),
    (80, 0x00, 0xFF),
    (81, 0x00, 0xFF),
    (82, 0x00, 0xFF),
    (83, 0x00, 0xFF),
    (84, 0x90, 0xFF),
    (85, 0x31, 0xFF),
    (86, 0x00, 0xFF),
    (87, 0x00, 0xFF),
    (88, 0x01, 0xFF),
    (89, 0x00, 0xFF),
    (90, 0x00, 0xFF),
    (91, 0x00, 0x0F),
    (92, 0x00, 0x00),
    (93, 0x00, 0x00),
    (94, 0x00, 0x00),
    (255, 0, 0xFF),
]; // set page bit to 0
//End of file
