-- Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
-- Copyright 2022-2026 Advanced Micro Devices, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2025.2.1 (lin64) Build 6403652 Thu Mar 19 13:47:00 MDT 2026
-- Date        : Mon Jun 29 23:06:58 2026
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
    gt_cplllock : out STD_LOGIC_VECTOR ( 3 downto 0 );
    gt_txresetdone : out STD_LOGIC_VECTOR ( 3 downto 0 );
    gt_rxresetdone : out STD_LOGIC_VECTOR ( 3 downto 0 );
    gt_txprbsforceerr : in STD_LOGIC_VECTOR ( 3 downto 0 );
    gt_rxprbssel : in STD_LOGIC_VECTOR ( 15 downto 0 );
    gt_rxprbscntreset : in STD_LOGIC_VECTOR ( 3 downto 0 );
    gt_rxprbserr : out STD_LOGIC_VECTOR ( 3 downto 0 );
    gt_eyescantrigger : in STD_LOGIC_VECTOR ( 3 downto 0 );
    gt_eyescanreset : in STD_LOGIC_VECTOR ( 3 downto 0 );
    gt_eyescandataerror : out STD_LOGIC_VECTOR ( 3 downto 0 );
    gt_txpmareset : in STD_LOGIC_VECTOR ( 3 downto 0 );
    gt_txpcsreset : in STD_LOGIC_VECTOR ( 3 downto 0 );
    gt_txbufstatus : out STD_LOGIC_VECTOR ( 7 downto 0 );
    gt_rxpmareset : in STD_LOGIC_VECTOR ( 3 downto 0 );
    gt_rxpcsreset : in STD_LOGIC_VECTOR ( 3 downto 0 );
    gt_rxbufreset : in STD_LOGIC_VECTOR ( 3 downto 0 );
    gt_rxpmaresetdone : out STD_LOGIC_VECTOR ( 3 downto 0 );
    gt_rxcdrhold : in STD_LOGIC_VECTOR ( 3 downto 0 );
    gt_rxcommadet : out STD_LOGIC_VECTOR ( 3 downto 0 );
    gt_rxdfelpmreset : in STD_LOGIC_VECTOR ( 3 downto 0 );
    gt_rxlpmen : in STD_LOGIC_VECTOR ( 3 downto 0 );
    gt_rxbufstatus : out STD_LOGIC_VECTOR ( 11 downto 0 );
    gt_rxrate : in STD_LOGIC_VECTOR ( 11 downto 0 );
    gt_dmonitorclk : in STD_LOGIC_VECTOR ( 3 downto 0 );
    gt_dmonitorout : out STD_LOGIC_VECTOR ( 63 downto 0 );
    gt_loopback : in STD_LOGIC_VECTOR ( 11 downto 0 );
    gt_txpostcursor : in STD_LOGIC_VECTOR ( 19 downto 0 );
    gt_txprecursor : in STD_LOGIC_VECTOR ( 19 downto 0 );
    gt_txdiffctrl : in STD_LOGIC_VECTOR ( 19 downto 0 );
    gt_txpolarity : in STD_LOGIC_VECTOR ( 3 downto 0 );
    gt_txinhibit : in STD_LOGIC_VECTOR ( 3 downto 0 );
    gt_rxpolarity : in STD_LOGIC_VECTOR ( 3 downto 0 );
    gt_pcsrsvdin : in STD_LOGIC_VECTOR ( 63 downto 0 );
    gt_rxpd : in STD_LOGIC_VECTOR ( 7 downto 0 );
    gt_txpd : in STD_LOGIC_VECTOR ( 7 downto 0 );
    gt0_drpaddr : in STD_LOGIC_VECTOR ( 9 downto 0 );
    gt0_drpdi : in STD_LOGIC_VECTOR ( 15 downto 0 );
    gt0_drpen : in STD_LOGIC;
    gt0_drpwe : in STD_LOGIC;
    gt0_drpdo : out STD_LOGIC_VECTOR ( 15 downto 0 );
    gt0_drprdy : out STD_LOGIC;
    gt1_drpaddr : in STD_LOGIC_VECTOR ( 9 downto 0 );
    gt1_drpdi : in STD_LOGIC_VECTOR ( 15 downto 0 );
    gt1_drpen : in STD_LOGIC;
    gt1_drpwe : in STD_LOGIC;
    gt1_drpdo : out STD_LOGIC_VECTOR ( 15 downto 0 );
    gt1_drprdy : out STD_LOGIC;
    gt2_drpaddr : in STD_LOGIC_VECTOR ( 9 downto 0 );
    gt2_drpdi : in STD_LOGIC_VECTOR ( 15 downto 0 );
    gt2_drpen : in STD_LOGIC;
    gt2_drpwe : in STD_LOGIC;
    gt2_drpdo : out STD_LOGIC_VECTOR ( 15 downto 0 );
    gt2_drprdy : out STD_LOGIC;
    gt3_drpaddr : in STD_LOGIC_VECTOR ( 9 downto 0 );
    gt3_drpdi : in STD_LOGIC_VECTOR ( 15 downto 0 );
    gt3_drpen : in STD_LOGIC;
    gt3_drpwe : in STD_LOGIC;
    gt3_drpdo : out STD_LOGIC_VECTOR ( 15 downto 0 );
    gt3_drprdy : out STD_LOGIC;
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
  attribute CORE_GENERATION_INFO of decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix : entity is "bd_jesd204_phy_0_0,jesd204_phy_v4_1_4,{x_ipProduct=Vivado 2025.2.1,x_ipVendor=xilinx.com,x_ipLibrary=ip,x_ipName=jesd204_phy,x_ipVersion=4.1,x_ipCoreRevision=4,x_ipLanguage=VERILOG,x_ipSimLanguage=MIXED,C_COMPONENT_NAME=bd_jesd204_phy_0_0,C_FAMILY=kintexuplus,C_SILICON_REVISION=,C_LANES=4,C_SPEEDGRADE=-2,C_SupportLevel=1,C_TransceiverControl=true,c_sub_core_name=bd_jesd204_phy_0_0_gt,C_GT_Line_Rate=1,C_GT_REFCLK_FREQ=100,C_DRPCLK_FREQ=25.0,C_PLL_SELECTION=0,C_RX_GT_Line_Rate=1,C_RX_GT_REFCLK_FREQ=100,C_RX_PLL_SELECTION=0,C_QPLL_FBDIV=40,C_QPLL_REFCLKDIV=1,C_PLL0_FBDIV=1,C_PLL0_FBDIV_45=4,C_PLL0_REFCLKDIV=1,C_PLL1_FBDIV=1,C_PLL1_FBDIV_45=4,C_PLL1_REFCLKDIV=1,C_Axi_Lite=false,C_AXICLK_FREQ=100.0,C_Transceiver=GTHE4,C_GT_Loc=X0Y0,C_gt_val_extended_timeout=false,C_Tx_JesdVersion=1,C_Rx_JesdVersion=1,C_Tx_use_64b=0,C_Rx_use_64b=0,C_CHANNEL_POS=0,C_QUADS=0,C_Equalization_Mode=0,C_Rx_MasterChan=1,C_Tx_MasterChan=1,C_Ins_Loss=12,C_Config_Type=0,C_Min_Line_Rate=1,C_Max_Line_Rate=1,C_GT_ENUM=7}";
  attribute DowngradeIPIdentifiedWarnings : string;
  attribute DowngradeIPIdentifiedWarnings of decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix : entity is "yes";
end decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix;

architecture stub of decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix is
  attribute syn_black_box : boolean;
  attribute black_box_pad_pin : string;
  attribute syn_black_box of stub : architecture is true;
  attribute black_box_pad_pin of stub : architecture is "gt_cplllock[3:0],gt_txresetdone[3:0],gt_rxresetdone[3:0],gt_txprbsforceerr[3:0],gt_rxprbssel[15:0],gt_rxprbscntreset[3:0],gt_rxprbserr[3:0],gt_eyescantrigger[3:0],gt_eyescanreset[3:0],gt_eyescandataerror[3:0],gt_txpmareset[3:0],gt_txpcsreset[3:0],gt_txbufstatus[7:0],gt_rxpmareset[3:0],gt_rxpcsreset[3:0],gt_rxbufreset[3:0],gt_rxpmaresetdone[3:0],gt_rxcdrhold[3:0],gt_rxcommadet[3:0],gt_rxdfelpmreset[3:0],gt_rxlpmen[3:0],gt_rxbufstatus[11:0],gt_rxrate[11:0],gt_dmonitorclk[3:0],gt_dmonitorout[63:0],gt_loopback[11:0],gt_txpostcursor[19:0],gt_txprecursor[19:0],gt_txdiffctrl[19:0],gt_txpolarity[3:0],gt_txinhibit[3:0],gt_rxpolarity[3:0],gt_pcsrsvdin[63:0],gt_rxpd[7:0],gt_txpd[7:0],gt0_drpaddr[9:0],gt0_drpdi[15:0],gt0_drpen,gt0_drpwe,gt0_drpdo[15:0],gt0_drprdy,gt1_drpaddr[9:0],gt1_drpdi[15:0],gt1_drpen,gt1_drpwe,gt1_drpdo[15:0],gt1_drprdy,gt2_drpaddr[9:0],gt2_drpdi[15:0],gt2_drpen,gt2_drpwe,gt2_drpdo[15:0],gt2_drprdy,gt3_drpaddr[9:0],gt3_drpdi[15:0],gt3_drpen,gt3_drpwe,gt3_drpdo[15:0],gt3_drprdy,tx_sys_reset,rx_sys_reset,tx_reset_gt,rx_reset_gt,tx_reset_done,rx_reset_done,gt_powergood,cpll_refclk,rxencommaalign,tx_core_clk,txoutclk,rx_core_clk,rxoutclk,drpclk,gt0_txcharisk[3:0],gt0_txheader[1:0],gt0_txdata[63:0],gt1_txcharisk[3:0],gt1_txheader[1:0],gt1_txdata[63:0],gt2_txcharisk[3:0],gt2_txheader[1:0],gt2_txdata[63:0],gt3_txcharisk[3:0],gt3_txheader[1:0],gt3_txdata[63:0],gt0_rxcharisk[3:0],gt0_rxdisperr[3:0],gt0_rxnotintable[3:0],gt0_rxheader[1:0],gt0_rxmisalign,gt0_rxblock_sync,gt0_rxdata[63:0],gt1_rxcharisk[3:0],gt1_rxdisperr[3:0],gt1_rxnotintable[3:0],gt1_rxheader[1:0],gt1_rxmisalign,gt1_rxblock_sync,gt1_rxdata[63:0],gt2_rxcharisk[3:0],gt2_rxdisperr[3:0],gt2_rxnotintable[3:0],gt2_rxheader[1:0],gt2_rxmisalign,gt2_rxblock_sync,gt2_rxdata[63:0],gt3_rxcharisk[3:0],gt3_rxdisperr[3:0],gt3_rxnotintable[3:0],gt3_rxheader[1:0],gt3_rxmisalign,gt3_rxblock_sync,gt3_rxdata[63:0],rxn_in[3:0],rxp_in[3:0],txn_out[3:0],txp_out[3:0]";
  attribute X_CORE_INFO : string;
  attribute X_CORE_INFO of stub : architecture is "jesd204_phy_v4_1_4,Vivado 2025.2.1";
begin
end;
