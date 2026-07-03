// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// Copyright 2022-2026 Advanced Micro Devices, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2025.2.1 (lin64) Build 6403652 Thu Mar 19 13:47:00 MDT 2026
// Date        : Mon Jun 29 23:06:59 2026
// Host        : russell-shotover-arch running 64-bit Ubuntu 22.04.5 LTS
// Command     : write_verilog -force -mode synth_stub
//               /home/russell/ultrasound/fpga/us/us.gen/sources_1/bd/bd/ip/bd_jesd204_phy_0_0/bd_jesd204_phy_0_0_stub.v
// Design      : bd_jesd204_phy_0_0
// Purpose     : Stub declaration of top-level module interface
// Device      : xcau15p-ffvb676-2-i
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* CORE_GENERATION_INFO = "bd_jesd204_phy_0_0,jesd204_phy_v4_1_4,{x_ipProduct=Vivado 2025.2.1,x_ipVendor=xilinx.com,x_ipLibrary=ip,x_ipName=jesd204_phy,x_ipVersion=4.1,x_ipCoreRevision=4,x_ipLanguage=VERILOG,x_ipSimLanguage=MIXED,C_COMPONENT_NAME=bd_jesd204_phy_0_0,C_FAMILY=kintexuplus,C_SILICON_REVISION=,C_LANES=4,C_SPEEDGRADE=-2,C_SupportLevel=1,C_TransceiverControl=true,c_sub_core_name=bd_jesd204_phy_0_0_gt,C_GT_Line_Rate=1,C_GT_REFCLK_FREQ=100,C_DRPCLK_FREQ=25.0,C_PLL_SELECTION=0,C_RX_GT_Line_Rate=1,C_RX_GT_REFCLK_FREQ=100,C_RX_PLL_SELECTION=0,C_QPLL_FBDIV=40,C_QPLL_REFCLKDIV=1,C_PLL0_FBDIV=1,C_PLL0_FBDIV_45=4,C_PLL0_REFCLKDIV=1,C_PLL1_FBDIV=1,C_PLL1_FBDIV_45=4,C_PLL1_REFCLKDIV=1,C_Axi_Lite=false,C_AXICLK_FREQ=100.0,C_Transceiver=GTHE4,C_GT_Loc=X0Y0,C_gt_val_extended_timeout=false,C_Tx_JesdVersion=1,C_Rx_JesdVersion=1,C_Tx_use_64b=0,C_Rx_use_64b=0,C_CHANNEL_POS=0,C_QUADS=0,C_Equalization_Mode=0,C_Rx_MasterChan=1,C_Tx_MasterChan=1,C_Ins_Loss=12,C_Config_Type=0,C_Min_Line_Rate=1,C_Max_Line_Rate=1,C_GT_ENUM=7}" *) (* DowngradeIPIdentifiedWarnings = "yes" *) (* X_CORE_INFO = "jesd204_phy_v4_1_4,Vivado 2025.2.1" *) 
module bd_jesd204_phy_0_0(gt_cplllock, gt_txresetdone, gt_rxresetdone, 
  gt_txprbsforceerr, gt_rxprbssel, gt_rxprbscntreset, gt_rxprbserr, gt_eyescantrigger, 
  gt_eyescanreset, gt_eyescandataerror, gt_txpmareset, gt_txpcsreset, gt_txbufstatus, 
  gt_rxpmareset, gt_rxpcsreset, gt_rxbufreset, gt_rxpmaresetdone, gt_rxcdrhold, 
  gt_rxcommadet, gt_rxdfelpmreset, gt_rxlpmen, gt_rxbufstatus, gt_rxrate, gt_dmonitorclk, 
  gt_dmonitorout, gt_loopback, gt_txpostcursor, gt_txprecursor, gt_txdiffctrl, gt_txpolarity, 
  gt_txinhibit, gt_rxpolarity, gt_pcsrsvdin, gt_rxpd, gt_txpd, gt0_drpaddr, gt0_drpdi, gt0_drpen, 
  gt0_drpwe, gt0_drpdo, gt0_drprdy, gt1_drpaddr, gt1_drpdi, gt1_drpen, gt1_drpwe, gt1_drpdo, 
  gt1_drprdy, gt2_drpaddr, gt2_drpdi, gt2_drpen, gt2_drpwe, gt2_drpdo, gt2_drprdy, gt3_drpaddr, 
  gt3_drpdi, gt3_drpen, gt3_drpwe, gt3_drpdo, gt3_drprdy, tx_sys_reset, rx_sys_reset, 
  tx_reset_gt, rx_reset_gt, tx_reset_done, rx_reset_done, gt_powergood, cpll_refclk, 
  rxencommaalign, tx_core_clk, txoutclk, rx_core_clk, rxoutclk, drpclk, gt0_txcharisk, 
  gt0_txheader, gt0_txdata, gt1_txcharisk, gt1_txheader, gt1_txdata, gt2_txcharisk, 
  gt2_txheader, gt2_txdata, gt3_txcharisk, gt3_txheader, gt3_txdata, gt0_rxcharisk, 
  gt0_rxdisperr, gt0_rxnotintable, gt0_rxheader, gt0_rxmisalign, gt0_rxblock_sync, 
  gt0_rxdata, gt1_rxcharisk, gt1_rxdisperr, gt1_rxnotintable, gt1_rxheader, gt1_rxmisalign, 
  gt1_rxblock_sync, gt1_rxdata, gt2_rxcharisk, gt2_rxdisperr, gt2_rxnotintable, gt2_rxheader, 
  gt2_rxmisalign, gt2_rxblock_sync, gt2_rxdata, gt3_rxcharisk, gt3_rxdisperr, 
  gt3_rxnotintable, gt3_rxheader, gt3_rxmisalign, gt3_rxblock_sync, gt3_rxdata, rxn_in, rxp_in, 
  txn_out, txp_out)
/* synthesis syn_black_box black_box_pad_pin="gt_cplllock[3:0],gt_txresetdone[3:0],gt_rxresetdone[3:0],gt_txprbsforceerr[3:0],gt_rxprbssel[15:0],gt_rxprbscntreset[3:0],gt_rxprbserr[3:0],gt_eyescantrigger[3:0],gt_eyescanreset[3:0],gt_eyescandataerror[3:0],gt_txpmareset[3:0],gt_txpcsreset[3:0],gt_txbufstatus[7:0],gt_rxpmareset[3:0],gt_rxpcsreset[3:0],gt_rxbufreset[3:0],gt_rxpmaresetdone[3:0],gt_rxcdrhold[3:0],gt_rxcommadet[3:0],gt_rxdfelpmreset[3:0],gt_rxlpmen[3:0],gt_rxbufstatus[11:0],gt_rxrate[11:0],gt_dmonitorclk[3:0],gt_dmonitorout[63:0],gt_loopback[11:0],gt_txpostcursor[19:0],gt_txprecursor[19:0],gt_txdiffctrl[19:0],gt_txpolarity[3:0],gt_txinhibit[3:0],gt_rxpolarity[3:0],gt_pcsrsvdin[63:0],gt_rxpd[7:0],gt_txpd[7:0],gt0_drpaddr[9:0],gt0_drpdi[15:0],gt0_drpen,gt0_drpwe,gt0_drpdo[15:0],gt0_drprdy,gt1_drpaddr[9:0],gt1_drpdi[15:0],gt1_drpen,gt1_drpwe,gt1_drpdo[15:0],gt1_drprdy,gt2_drpaddr[9:0],gt2_drpdi[15:0],gt2_drpen,gt2_drpwe,gt2_drpdo[15:0],gt2_drprdy,gt3_drpaddr[9:0],gt3_drpdi[15:0],gt3_drpen,gt3_drpwe,gt3_drpdo[15:0],gt3_drprdy,tx_sys_reset,rx_sys_reset,tx_reset_gt,rx_reset_gt,tx_reset_done,rx_reset_done,gt_powergood,cpll_refclk,rxencommaalign,rxoutclk,gt0_txcharisk[3:0],gt0_txheader[1:0],gt0_txdata[63:0],gt1_txcharisk[3:0],gt1_txheader[1:0],gt1_txdata[63:0],gt2_txcharisk[3:0],gt2_txheader[1:0],gt2_txdata[63:0],gt3_txcharisk[3:0],gt3_txheader[1:0],gt3_txdata[63:0],gt0_rxcharisk[3:0],gt0_rxdisperr[3:0],gt0_rxnotintable[3:0],gt0_rxheader[1:0],gt0_rxmisalign,gt0_rxblock_sync,gt0_rxdata[63:0],gt1_rxcharisk[3:0],gt1_rxdisperr[3:0],gt1_rxnotintable[3:0],gt1_rxheader[1:0],gt1_rxmisalign,gt1_rxblock_sync,gt1_rxdata[63:0],gt2_rxcharisk[3:0],gt2_rxdisperr[3:0],gt2_rxnotintable[3:0],gt2_rxheader[1:0],gt2_rxmisalign,gt2_rxblock_sync,gt2_rxdata[63:0],gt3_rxcharisk[3:0],gt3_rxdisperr[3:0],gt3_rxnotintable[3:0],gt3_rxheader[1:0],gt3_rxmisalign,gt3_rxblock_sync,gt3_rxdata[63:0],rxn_in[3:0],rxp_in[3:0],txn_out[3:0],txp_out[3:0]" */
/* synthesis syn_force_seq_prim="tx_core_clk" */
/* synthesis syn_force_seq_prim="txoutclk" */
/* synthesis syn_force_seq_prim="rx_core_clk" */
/* synthesis syn_force_seq_prim="drpclk" */;
  output [3:0]gt_cplllock;
  output [3:0]gt_txresetdone;
  output [3:0]gt_rxresetdone;
  input [3:0]gt_txprbsforceerr;
  input [15:0]gt_rxprbssel;
  input [3:0]gt_rxprbscntreset;
  output [3:0]gt_rxprbserr;
  input [3:0]gt_eyescantrigger;
  input [3:0]gt_eyescanreset;
  output [3:0]gt_eyescandataerror;
  input [3:0]gt_txpmareset;
  input [3:0]gt_txpcsreset;
  output [7:0]gt_txbufstatus;
  input [3:0]gt_rxpmareset;
  input [3:0]gt_rxpcsreset;
  input [3:0]gt_rxbufreset;
  output [3:0]gt_rxpmaresetdone;
  input [3:0]gt_rxcdrhold;
  output [3:0]gt_rxcommadet;
  input [3:0]gt_rxdfelpmreset;
  input [3:0]gt_rxlpmen;
  output [11:0]gt_rxbufstatus;
  input [11:0]gt_rxrate;
  input [3:0]gt_dmonitorclk;
  output [63:0]gt_dmonitorout;
  input [11:0]gt_loopback;
  input [19:0]gt_txpostcursor;
  input [19:0]gt_txprecursor;
  input [19:0]gt_txdiffctrl;
  input [3:0]gt_txpolarity;
  input [3:0]gt_txinhibit;
  input [3:0]gt_rxpolarity;
  input [63:0]gt_pcsrsvdin;
  input [7:0]gt_rxpd;
  input [7:0]gt_txpd;
  input [9:0]gt0_drpaddr;
  input [15:0]gt0_drpdi;
  input gt0_drpen;
  input gt0_drpwe;
  output [15:0]gt0_drpdo;
  output gt0_drprdy;
  input [9:0]gt1_drpaddr;
  input [15:0]gt1_drpdi;
  input gt1_drpen;
  input gt1_drpwe;
  output [15:0]gt1_drpdo;
  output gt1_drprdy;
  input [9:0]gt2_drpaddr;
  input [15:0]gt2_drpdi;
  input gt2_drpen;
  input gt2_drpwe;
  output [15:0]gt2_drpdo;
  output gt2_drprdy;
  input [9:0]gt3_drpaddr;
  input [15:0]gt3_drpdi;
  input gt3_drpen;
  input gt3_drpwe;
  output [15:0]gt3_drpdo;
  output gt3_drprdy;
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
