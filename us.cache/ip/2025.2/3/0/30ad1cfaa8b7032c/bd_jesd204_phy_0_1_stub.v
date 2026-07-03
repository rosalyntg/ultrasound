// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// Copyright 2022-2025 Advanced Micro Devices, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2025.2 (lin64) Build 6299465 Fri Nov 14 12:34:56 MST 2025
// Date        : Sun Feb 15 22:51:07 2026
// Host        : russell-shotover-arch running 64-bit Ubuntu 22.04.5 LTS
// Command     : write_verilog -force -mode synth_stub -rename_top decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix -prefix
//               decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix_ bd_jesd204_phy_0_1_stub.v
// Design      : bd_jesd204_phy_0_1
// Purpose     : Stub declaration of top-level module interface
// Device      : xcau15p-ffvb676-2-i
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* CORE_GENERATION_INFO = "bd_jesd204_phy_0_1,jesd204_phy_v4_1_3,{x_ipProduct=Vivado 2025.2,x_ipVendor=xilinx.com,x_ipLibrary=ip,x_ipName=jesd204_phy,x_ipVersion=4.1,x_ipCoreRevision=3,x_ipLanguage=VERILOG,x_ipSimLanguage=MIXED,C_COMPONENT_NAME=bd_jesd204_phy_0_1,C_FAMILY=kintexuplus,C_SILICON_REVISION=,C_LANES=4,C_SPEEDGRADE=-2,C_SupportLevel=1,C_TransceiverControl=false,c_sub_core_name=bd_jesd204_phy_0_1_gt,C_GT_Line_Rate=3.2,C_GT_REFCLK_FREQ=160,C_DRPCLK_FREQ=80.0,C_PLL_SELECTION=0,C_RX_GT_Line_Rate=3.2,C_RX_GT_REFCLK_FREQ=160,C_RX_PLL_SELECTION=0,C_QPLL_FBDIV=40,C_QPLL_REFCLKDIV=1,C_PLL0_FBDIV=1,C_PLL0_FBDIV_45=4,C_PLL0_REFCLKDIV=1,C_PLL1_FBDIV=1,C_PLL1_FBDIV_45=4,C_PLL1_REFCLKDIV=1,C_Axi_Lite=false,C_AXICLK_FREQ=100.0,C_Transceiver=GTHE4,C_GT_Loc=X0Y0,C_gt_val_extended_timeout=false,C_Tx_JesdVersion=1,C_Rx_JesdVersion=1,C_Tx_use_64b=0,C_Rx_use_64b=0,C_CHANNEL_POS=0,C_QUADS=0,C_Equalization_Mode=0,C_Rx_MasterChan=1,C_Tx_MasterChan=1,C_Ins_Loss=12,C_Config_Type=0,C_Min_Line_Rate=3.2,C_Max_Line_Rate=3.2,C_GT_ENUM=7}" *) (* DowngradeIPIdentifiedWarnings = "yes" *) (* X_CORE_INFO = "jesd204_phy_v4_1_3,Vivado 2025.2" *) 
module decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix(tx_sys_reset, rx_sys_reset, tx_reset_gt, 
  rx_reset_gt, tx_reset_done, rx_reset_done, gt_powergood, cpll_refclk, rxencommaalign, 
  tx_core_clk, txoutclk, rx_core_clk, rxoutclk, drpclk, gt0_txcharisk, gt0_txheader, gt0_txdata, 
  gt1_txcharisk, gt1_txheader, gt1_txdata, gt2_txcharisk, gt2_txheader, gt2_txdata, 
  gt3_txcharisk, gt3_txheader, gt3_txdata, gt0_rxcharisk, gt0_rxdisperr, gt0_rxnotintable, 
  gt0_rxheader, gt0_rxmisalign, gt0_rxblock_sync, gt0_rxdata, gt1_rxcharisk, gt1_rxdisperr, 
  gt1_rxnotintable, gt1_rxheader, gt1_rxmisalign, gt1_rxblock_sync, gt1_rxdata, 
  gt2_rxcharisk, gt2_rxdisperr, gt2_rxnotintable, gt2_rxheader, gt2_rxmisalign, 
  gt2_rxblock_sync, gt2_rxdata, gt3_rxcharisk, gt3_rxdisperr, gt3_rxnotintable, gt3_rxheader, 
  gt3_rxmisalign, gt3_rxblock_sync, gt3_rxdata, rxn_in, rxp_in, txn_out, txp_out)
/* synthesis syn_black_box black_box_pad_pin="tx_sys_reset,rx_sys_reset,tx_reset_gt,rx_reset_gt,tx_reset_done,rx_reset_done,gt_powergood,cpll_refclk,rxencommaalign,rxoutclk,gt0_txcharisk[3:0],gt0_txheader[1:0],gt0_txdata[63:0],gt1_txcharisk[3:0],gt1_txheader[1:0],gt1_txdata[63:0],gt2_txcharisk[3:0],gt2_txheader[1:0],gt2_txdata[63:0],gt3_txcharisk[3:0],gt3_txheader[1:0],gt3_txdata[63:0],gt0_rxcharisk[3:0],gt0_rxdisperr[3:0],gt0_rxnotintable[3:0],gt0_rxheader[1:0],gt0_rxmisalign,gt0_rxblock_sync,gt0_rxdata[63:0],gt1_rxcharisk[3:0],gt1_rxdisperr[3:0],gt1_rxnotintable[3:0],gt1_rxheader[1:0],gt1_rxmisalign,gt1_rxblock_sync,gt1_rxdata[63:0],gt2_rxcharisk[3:0],gt2_rxdisperr[3:0],gt2_rxnotintable[3:0],gt2_rxheader[1:0],gt2_rxmisalign,gt2_rxblock_sync,gt2_rxdata[63:0],gt3_rxcharisk[3:0],gt3_rxdisperr[3:0],gt3_rxnotintable[3:0],gt3_rxheader[1:0],gt3_rxmisalign,gt3_rxblock_sync,gt3_rxdata[63:0],rxn_in[3:0],rxp_in[3:0],txn_out[3:0],txp_out[3:0]" */
/* synthesis syn_force_seq_prim="tx_core_clk" */
/* synthesis syn_force_seq_prim="txoutclk" */
/* synthesis syn_force_seq_prim="rx_core_clk" */
/* synthesis syn_force_seq_prim="drpclk" */;
  input tx_sys_reset;
  input rx_sys_reset;
  input tx_reset_gt;
  input rx_reset_gt;
  output tx_reset_done;
  output rx_reset_done;
  output gt_powergood;
  input cpll_refclk;
  input rxencommaalign;
  input tx_core_clk /* synthesis syn_isclock = 1 */;
  output txoutclk /* synthesis syn_isclock = 1 */;
  input rx_core_clk /* synthesis syn_isclock = 1 */;
  output rxoutclk;
  input drpclk /* synthesis syn_isclock = 1 */;
  input [3:0]gt0_txcharisk;
  input [1:0]gt0_txheader;
  input [63:0]gt0_txdata;
  input [3:0]gt1_txcharisk;
  input [1:0]gt1_txheader;
  input [63:0]gt1_txdata;
  input [3:0]gt2_txcharisk;
  input [1:0]gt2_txheader;
  input [63:0]gt2_txdata;
  input [3:0]gt3_txcharisk;
  input [1:0]gt3_txheader;
  input [63:0]gt3_txdata;
  output [3:0]gt0_rxcharisk;
  output [3:0]gt0_rxdisperr;
  output [3:0]gt0_rxnotintable;
  output [1:0]gt0_rxheader;
  output gt0_rxmisalign;
  output gt0_rxblock_sync;
  output [63:0]gt0_rxdata;
  output [3:0]gt1_rxcharisk;
  output [3:0]gt1_rxdisperr;
  output [3:0]gt1_rxnotintable;
  output [1:0]gt1_rxheader;
  output gt1_rxmisalign;
  output gt1_rxblock_sync;
  output [63:0]gt1_rxdata;
  output [3:0]gt2_rxcharisk;
  output [3:0]gt2_rxdisperr;
  output [3:0]gt2_rxnotintable;
  output [1:0]gt2_rxheader;
  output gt2_rxmisalign;
  output gt2_rxblock_sync;
  output [63:0]gt2_rxdata;
  output [3:0]gt3_rxcharisk;
  output [3:0]gt3_rxdisperr;
  output [3:0]gt3_rxnotintable;
  output [1:0]gt3_rxheader;
  output gt3_rxmisalign;
  output gt3_rxblock_sync;
  output [63:0]gt3_rxdata;
  input [3:0]rxn_in;
  input [3:0]rxp_in;
  output [3:0]txn_out;
  output [3:0]txp_out;
endmodule
