-- Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
-- Copyright 2022-2026 Advanced Micro Devices, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2025.2.1 (lin64) Build 6403652 Thu Mar 19 13:47:00 MDT 2026
-- Date        : Sun Apr 19 18:13:24 2026
-- Host        : russell-shotover-arch running 64-bit Ubuntu 22.04.5 LTS
-- Command     : write_vhdl -force -mode synth_stub -rename_top decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix -prefix
--               decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix_ bd_jesd204_phy_0_0_stub.vhdl
-- Design      : bd_jesd204_phy_0_0
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xcau15p-ffvb676-2-i
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix is
  Port ( 
    tx_sys_reset : in STD_LOGIC;
    rx_sys_reset : in STD_LOGIC;
    tx_reset_gt : in STD_LOGIC;
    rx_reset_gt : in STD_LOGIC;
    tx_reset_done : out STD_LOGIC;
    rx_reset_done : out STD_LOGIC;
    gt_powergood : out STD_LOGIC;
    cpll_refclk : in STD_LOGIC;
    rxencommaalign : in STD_LOGIC;
    tx_core_clk : in STD_LOGIC;
    txoutclk : out STD_LOGIC;
    rx_core_clk : in STD_LOGIC;
    rxoutclk : out STD_LOGIC;
    drpclk : in STD_LOGIC;
    gt0_txcharisk : in STD_LOGIC_VECTOR ( 3 downto 0 );
    gt0_txheader : in STD_LOGIC_VECTOR ( 1 downto 0 );
    gt0_txdata : in STD_LOGIC_VECTOR ( 63 downto 0 );
    gt1_txcharisk : in STD_LOGIC_VECTOR ( 3 downto 0 );
    gt1_txheader : in STD_LOGIC_VECTOR ( 1 downto 0 );
    gt1_txdata : in STD_LOGIC_VECTOR ( 63 downto 0 );
    gt2_txcharisk : in STD_LOGIC_VECTOR ( 3 downto 0 );
    gt2_txheader : in STD_LOGIC_VECTOR ( 1 downto 0 );
    gt2_txdata : in STD_LOGIC_VECTOR ( 63 downto 0 );
    gt3_txcharisk : in STD_LOGIC_VECTOR ( 3 downto 0 );
    gt3_txheader : in STD_LOGIC_VECTOR ( 1 downto 0 );
    gt3_txdata : in STD_LOGIC_VECTOR ( 63 downto 0 );
    gt0_rxcharisk : out STD_LOGIC_VECTOR ( 3 downto 0 );
    gt0_rxdisperr : out STD_LOGIC_VECTOR ( 3 downto 0 );
    gt0_rxnotintable : out STD_LOGIC_VECTOR ( 3 downto 0 );
    gt0_rxheader : out STD_LOGIC_VECTOR ( 1 downto 0 );
    gt0_rxmisalign : out STD_LOGIC;
    gt0_rxblock_sync : out STD_LOGIC;
    gt0_rxdata : out STD_LOGIC_VECTOR ( 63 downto 0 );
    gt1_rxcharisk : out STD_LOGIC_VECTOR ( 3 downto 0 );
    gt1_rxdisperr : out STD_LOGIC_VECTOR ( 3 downto 0 );
    gt1_rxnotintable : out STD_LOGIC_VECTOR ( 3 downto 0 );
    gt1_rxheader : out STD_LOGIC_VECTOR ( 1 downto 0 );
    gt1_rxmisalign : out STD_LOGIC;
    gt1_rxblock_sync : out STD_LOGIC;
    gt1_rxdata : out STD_LOGIC_VECTOR ( 63 downto 0 );
    gt2_rxcharisk : out STD_LOGIC_VECTOR ( 3 downto 0 );
    gt2_rxdisperr : out STD_LOGIC_VECTOR ( 3 downto 0 );
    gt2_rxnotintable : out STD_LOGIC_VECTOR ( 3 downto 0 );
    gt2_rxheader : out STD_LOGIC_VECTOR ( 1 downto 0 );
    gt2_rxmisalign : out STD_LOGIC;
    gt2_rxblock_sync : out STD_LOGIC;
    gt2_rxdata : out STD_LOGIC_VECTOR ( 63 downto 0 );
    gt3_rxcharisk : out STD_LOGIC_VECTOR ( 3 downto 0 );
    gt3_rxdisperr : out STD_LOGIC_VECTOR ( 3 downto 0 );
    gt3_rxnotintable : out STD_LOGIC_VECTOR ( 3 downto 0 );
    gt3_rxheader : out STD_LOGIC_VECTOR ( 1 downto 0 );
    gt3_rxmisalign : out STD_LOGIC;
    gt3_rxblock_sync : out STD_LOGIC;
    gt3_rxdata : out STD_LOGIC_VECTOR ( 63 downto 0 );
    rxn_in : in STD_LOGIC_VECTOR ( 3 downto 0 );
    rxp_in : in STD_LOGIC_VECTOR ( 3 downto 0 );
    txn_out : out STD_LOGIC_VECTOR ( 3 downto 0 );
    txp_out : out STD_LOGIC_VECTOR ( 3 downto 0 )
  );

  attribute CORE_GENERATION_INFO : string;
  attribute CORE_GENERATION_INFO of decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix : entity is "bd_jesd204_phy_0_0,jesd204_phy_v4_1_4,{x_ipProduct=Vivado 2025.2.1,x_ipVendor=xilinx.com,x_ipLibrary=ip,x_ipName=jesd204_phy,x_ipVersion=4.1,x_ipCoreRevision=4,x_ipLanguage=VERILOG,x_ipSimLanguage=MIXED,C_COMPONENT_NAME=bd_jesd204_phy_0_0,C_FAMILY=kintexuplus,C_SILICON_REVISION=,C_LANES=4,C_SPEEDGRADE=-2,C_SupportLevel=1,C_TransceiverControl=false,c_sub_core_name=bd_jesd204_phy_0_0_gt,C_GT_Line_Rate=1,C_GT_REFCLK_FREQ=100,C_DRPCLK_FREQ=25.0,C_PLL_SELECTION=0,C_RX_GT_Line_Rate=1,C_RX_GT_REFCLK_FREQ=100,C_RX_PLL_SELECTION=0,C_QPLL_FBDIV=40,C_QPLL_REFCLKDIV=1,C_PLL0_FBDIV=1,C_PLL0_FBDIV_45=4,C_PLL0_REFCLKDIV=1,C_PLL1_FBDIV=1,C_PLL1_FBDIV_45=4,C_PLL1_REFCLKDIV=1,C_Axi_Lite=false,C_AXICLK_FREQ=100.0,C_Transceiver=GTHE4,C_GT_Loc=X0Y0,C_gt_val_extended_timeout=false,C_Tx_JesdVersion=1,C_Rx_JesdVersion=1,C_Tx_use_64b=0,C_Rx_use_64b=0,C_CHANNEL_POS=0,C_QUADS=0,C_Equalization_Mode=0,C_Rx_MasterChan=1,C_Tx_MasterChan=1,C_Ins_Loss=12,C_Config_Type=0,C_Min_Line_Rate=1,C_Max_Line_Rate=1,C_GT_ENUM=7}";
  attribute DowngradeIPIdentifiedWarnings : string;
  attribute DowngradeIPIdentifiedWarnings of decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix : entity is "yes";
end decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix;

architecture stub of decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix is
  attribute syn_black_box : boolean;
  attribute black_box_pad_pin : string;
  attribute syn_black_box of stub : architecture is true;
  attribute black_box_pad_pin of stub : architecture is "tx_sys_reset,rx_sys_reset,tx_reset_gt,rx_reset_gt,tx_reset_done,rx_reset_done,gt_powergood,cpll_refclk,rxencommaalign,tx_core_clk,txoutclk,rx_core_clk,rxoutclk,drpclk,gt0_txcharisk[3:0],gt0_txheader[1:0],gt0_txdata[63:0],gt1_txcharisk[3:0],gt1_txheader[1:0],gt1_txdata[63:0],gt2_txcharisk[3:0],gt2_txheader[1:0],gt2_txdata[63:0],gt3_txcharisk[3:0],gt3_txheader[1:0],gt3_txdata[63:0],gt0_rxcharisk[3:0],gt0_rxdisperr[3:0],gt0_rxnotintable[3:0],gt0_rxheader[1:0],gt0_rxmisalign,gt0_rxblock_sync,gt0_rxdata[63:0],gt1_rxcharisk[3:0],gt1_rxdisperr[3:0],gt1_rxnotintable[3:0],gt1_rxheader[1:0],gt1_rxmisalign,gt1_rxblock_sync,gt1_rxdata[63:0],gt2_rxcharisk[3:0],gt2_rxdisperr[3:0],gt2_rxnotintable[3:0],gt2_rxheader[1:0],gt2_rxmisalign,gt2_rxblock_sync,gt2_rxdata[63:0],gt3_rxcharisk[3:0],gt3_rxdisperr[3:0],gt3_rxnotintable[3:0],gt3_rxheader[1:0],gt3_rxmisalign,gt3_rxblock_sync,gt3_rxdata[63:0],rxn_in[3:0],rxp_in[3:0],txn_out[3:0],txp_out[3:0]";
  attribute X_CORE_INFO : string;
  attribute X_CORE_INFO of stub : architecture is "jesd204_phy_v4_1_4,Vivado 2025.2.1";
begin
end;
