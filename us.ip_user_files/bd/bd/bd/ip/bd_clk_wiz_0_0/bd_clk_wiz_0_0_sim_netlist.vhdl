-- Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
-- Copyright 2022-2026 Advanced Micro Devices, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2025.2.1 (lin64) Build 6403652 Thu Mar 19 13:47:00 MDT 2026
-- Date        : Sun Apr 19 19:02:56 2026
-- Host        : russell-shotover-arch running 64-bit Ubuntu 22.04.5 LTS
-- Command     : write_vhdl -force -mode funcsim
--               /home/russell/ultrasound/fpga/us/us.gen/sources_1/bd/bd/ip/bd_clk_wiz_0_0/bd_clk_wiz_0_0_sim_netlist.vhdl
-- Design      : bd_clk_wiz_0_0
-- Purpose     : This VHDL netlist is a functional simulation representation of the design and should not be modified or
--               synthesized. This netlist cannot be used for SDF annotated simulation.
-- Device      : xcau15p-ffvb676-2-i
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity bd_clk_wiz_0_0_clk_wiz is
  port (
    mhz25 : out STD_LOGIC;
    clk_in1_p : in STD_LOGIC;
    clk_in1_n : in STD_LOGIC
  );
end bd_clk_wiz_0_0_clk_wiz;

architecture STRUCTURE of bd_clk_wiz_0_0_clk_wiz is
  signal clk_in1_bd_clk_wiz_0_0 : STD_LOGIC;
  signal clk_in1_bd_clk_wiz_0_0_buf : STD_LOGIC;
  attribute BOX_TYPE : string;
  attribute BOX_TYPE of BUFGCE_DIV_CLK1_inst : label is "PRIMITIVE";
  attribute BOX_TYPE of clkin1_bufg1 : label is "PRIMITIVE";
  attribute XILINX_LEGACY_PRIM : string;
  attribute XILINX_LEGACY_PRIM of clkin1_bufg1 : label is "BUFG";
  attribute XILINX_TRANSFORM_PINMAP : string;
  attribute XILINX_TRANSFORM_PINMAP of clkin1_bufg1 : label is "VCC:CE";
  attribute BOX_TYPE of clkin1_ibufds : label is "PRIMITIVE";
  attribute CAPACITANCE : string;
  attribute CAPACITANCE of clkin1_ibufds : label is "DONT_CARE";
  attribute IBUF_DELAY_VALUE : string;
  attribute IBUF_DELAY_VALUE of clkin1_ibufds : label is "0";
  attribute IFD_DELAY_VALUE : string;
  attribute IFD_DELAY_VALUE of clkin1_ibufds : label is "AUTO";
begin
BUFGCE_DIV_CLK1_inst: unisim.vcomponents.BUFGCE_DIV
    generic map(
      BUFGCE_DIVIDE => 8,
      CE_TYPE => "SYNC",
      HARDSYNC_CLR => "FALSE",
      IS_CE_INVERTED => '0',
      IS_CLR_INVERTED => '0',
      IS_I_INVERTED => '0',
      SIM_DEVICE => "ULTRASCALE",
      STARTUP_SYNC => "FALSE"
    )
        port map (
      CE => '1',
      CLR => '0',
      I => clk_in1_bd_clk_wiz_0_0,
      O => mhz25
    );
clkin1_bufg1: unisim.vcomponents.BUFGCE
    generic map(
      CE_TYPE => "ASYNC",
      SIM_DEVICE => "ULTRASCALE_PLUS"
    )
        port map (
      CE => '1',
      I => clk_in1_bd_clk_wiz_0_0_buf,
      O => clk_in1_bd_clk_wiz_0_0
    );
clkin1_ibufds: unisim.vcomponents.IBUFDS
    generic map(
      DIFF_TERM => false,
      IOSTANDARD => "DEFAULT"
    )
        port map (
      I => clk_in1_p,
      IB => clk_in1_n,
      O => clk_in1_bd_clk_wiz_0_0_buf
    );
end STRUCTURE;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity bd_clk_wiz_0_0 is
  port (
    mhz25 : out STD_LOGIC;
    clk_in1_p : in STD_LOGIC;
    clk_in1_n : in STD_LOGIC
  );
  attribute NotValidForBitStream : boolean;
  attribute NotValidForBitStream of bd_clk_wiz_0_0 : entity is true;
end bd_clk_wiz_0_0;

architecture STRUCTURE of bd_clk_wiz_0_0 is
begin
inst: entity work.bd_clk_wiz_0_0_clk_wiz
     port map (
      clk_in1_n => clk_in1_n,
      clk_in1_p => clk_in1_p,
      mhz25 => mhz25
    );
end STRUCTURE;
