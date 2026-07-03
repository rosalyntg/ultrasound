// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// Copyright 2022-2026 Advanced Micro Devices, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2025.2.1 (lin64) Build 6403652 Thu Mar 19 13:47:00 MDT 2026
// Date        : Mon Jun 29 23:07:08 2026
// Host        : russell-shotover-arch running 64-bit Ubuntu 22.04.5 LTS
// Command     : write_verilog -force -mode synth_stub -rename_top decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix -prefix
//               decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix_ bd_xxv_ethernet_0_0_stub.v
// Design      : bd_xxv_ethernet_0_0
// Purpose     : Stub declaration of top-level module interface
// Device      : xcau15p-ffvb676-2-i
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* CHECK_LICENSE_TYPE = "bd_xxv_ethernet_0_0,xxv_ethernet_core,{}" *) (* CORE_GENERATION_INFO = "bd_xxv_ethernet_0_0,xxv_ethernet_v5_0_3,{x_ipProduct=Vivado 2025.2.1,x_ipVendor=xilinx.com,x_ipLibrary=ip,x_ipName=xxv_ethernet,x_ipVersion=5.0,x_ipCoreRevision=3,x_ipLanguage=VERILOG,x_ipSimLanguage=MIXED,C_CORE=Ethernet PCS/PMA 64-bit,C_XGMII_INTERFACE=1,C_LINE_RATE=10,C_NUM_OF_CORES=1,C_CLOCKING=Asynchronous,C_DATA_PATH_INTERFACE=MII,C_RUNTIME_SWITCH=0,C_ENABLE_PREEMPTION=0,C_ENABLE_PREEMPTION_FIFO=0,C_ENABLE_DATAPATH_PARITY=0,C_BASE_R_KR=BASE-R,C_INCLUDE_FEC_LOGIC=0,C_INCLUDE_RSFEC_LOGIC=0,C_INCLUDE_HYBRID_CMAC_RSFEC_LOGIC=0,C_INCLUDE_AUTO_NEG_LT_LOGIC=None,C_ANLT_CLK_IN_MHZ=100,C_INCLUDE_AXI4_INTERFACE=0,C_INCLUDE_STATISTICS_COUNTERS=0,C_STATISTICS_REGS_TYPE=0,C_INCLUDE_USER_FIFO=0,C_ENABLE_TX_FLOW_CONTROL_LOGIC=0,C_ENABLE_RX_FLOW_CONTROL_LOGIC=0,C_ENABLE_TIME_STAMPING=0,C_PTP_OPERATION_MODE=2,C_PTP_CLOCKING_MODE=0,C_TX_LATENCY_ADJUST=0,C_ENABLE_VLANE_ADJUST_MODE=0,C_SYS_CLK=4000,C_GT_LOCATION=1,C_GT_REF_CLK_FREQ=156.25,C_GT_DRP_CLK=100.00,C_GT_TYPE=GTH,C_GT_GROUP_SELECT=Quad X0Y0,C_LANE1_GT_LOC=X0Y0,C_LANE2_GT_LOC=NA,C_LANE3_GT_LOC=NA,C_LANE4_GT_LOC=NA,C_INS_LOSS_NYQ=30,C_RX_EQ_MODE=AUTO,C_ENABLE_PIPELINE_REG=0,C_ADD_GT_CNTRL_STS_PORTS=1,C_ENABLE_GT_BOARD_INTERFACE=0,C_INCLUDE_SHARED_LOGIC=1,C_FAST_SIM_MODE=0,C_SWITCH_1_10_25G=0,C_FAMILY_CHK=artixuplus,IS_BOARD_PROJECT=0,VERSAL_GT_BOARD_FLOW=0,C_AXIS_TDATA_WIDTH=64,C_AXIS_TKEEP_WIDTH=7,C_TX_TOTAL_BYTES_WIDTH=4,C_GT_DIFFCTRL_WIDTH=4,C_MII_DATA_WIDTH=64,C_MII_CTRL_WIDTH=8,C_GTM_GROUP_SELECT=NA,C_CMAC_CORE_SELECT=CMACE4_X0Y0,C_GT_SETTINGS=internal,C_IS_GT_WIZ_OLD=0,x_ipLicense=xxv_eth_mac_pcs@2025.05(design_linking),x_ipLicense=xxv_eth_basekr@2025.05(design_linking),x_ipLicense=xxv_tsn_802d1cm@2025.05(design_linking)}" *) (* DowngradeIPIdentifiedWarnings = "yes" *) 
(* X_CORE_INFO = "xxv_ethernet_v5_0_3,Vivado 2025.2.1" *) 
module decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix(gt_rxp_in_0, gt_rxn_in_0, gt_txp_out_0, 
  gt_txn_out_0, tx_mii_clk_0, rx_core_clk_0, rx_clk_out_0, gt_loopback_in_0, rx_reset_0, 
  user_rx_reset_0, rxrecclkout_0, rx_mii_d_0, rx_mii_c_0, ctl_rx_test_pattern_0, 
  ctl_rx_test_pattern_enable_0, ctl_rx_data_pattern_select_0, 
  ctl_rx_prbs31_test_pattern_enable_0, stat_rx_block_lock_0, 
  stat_rx_framing_err_valid_0, stat_rx_framing_err_0, stat_rx_hi_ber_0, 
  stat_rx_valid_ctrl_code_0, stat_rx_bad_code_0, stat_rx_bad_code_valid_0, 
  stat_rx_error_valid_0, stat_rx_error_0, stat_rx_fifo_error_0, stat_rx_local_fault_0, 
  stat_rx_status_0, tx_reset_0, user_tx_reset_0, tx_mii_d_0, tx_mii_c_0, 
  ctl_tx_test_pattern_0, ctl_tx_test_pattern_enable_0, ctl_tx_test_pattern_select_0, 
  ctl_tx_data_pattern_select_0, ctl_tx_test_pattern_seed_a_0, 
  ctl_tx_test_pattern_seed_b_0, ctl_tx_prbs31_test_pattern_enable_0, 
  stat_tx_local_fault_0, gt_dmonitorout_0, gt_eyescandataerror_0, gt_eyescanreset_0, 
  gt_eyescantrigger_0, gt_pcsrsvdin_0, gt_rxbufreset_0, gt_rxbufstatus_0, gt_rxcdrhold_0, 
  gt_rxcommadeten_0, gt_rxdfeagchold_0, gt_rxdfelpmreset_0, gt_rxlatclk_0, gt_rxlpmen_0, 
  gt_rxpcsreset_0, gt_rxpmareset_0, gt_rxpolarity_0, gt_rxprbscntreset_0, gt_rxprbserr_0, 
  gt_rxprbslocked_0, gt_txresetdone_0, gt_rxprbssel_0, gt_rxrate_0, gt_rxslide_in_0, 
  gt_rxstartofseq_0, gt_txbufstatus_0, gt_txinhibit_0, gt_txlatclk_0, gt_txmaincursor_0, 
  gt_txpcsreset_0, gt_txpmareset_0, gt_txpolarity_0, gt_txpostcursor_0, 
  gt_txprbsforceerr_0, gt_txelecidle_0, gt_txprbssel_0, gt_txprecursor_0, gt_txdiffctrl_0, 
  gt_drpdo_0, gt_drprdy_0, gt_drpen_0, gt_drpwe_0, gt_drpaddr_0, gt_drpdi_0, gt_drpclk_0, 
  gt_drprst_0, gtwiz_reset_tx_datapath_0, gtwiz_reset_rx_datapath_0, gtpowergood_out_0, 
  txoutclksel_in_0, rxoutclksel_in_0, gt_refclk_p, gt_refclk_n, gt_refclk_out, 
  qpllreset_in_0, ctl_rx_wdt_disable_0, sys_reset, dclk)
/* synthesis syn_black_box black_box_pad_pin="gt_rxp_in_0,gt_rxn_in_0,gt_txp_out_0,gt_txn_out_0,gt_loopback_in_0[2:0],rx_reset_0,user_rx_reset_0,rxrecclkout_0,rx_mii_d_0[63:0],rx_mii_c_0[7:0],ctl_rx_test_pattern_0,ctl_rx_test_pattern_enable_0,ctl_rx_data_pattern_select_0,ctl_rx_prbs31_test_pattern_enable_0,stat_rx_block_lock_0,stat_rx_framing_err_valid_0,stat_rx_framing_err_0,stat_rx_hi_ber_0,stat_rx_valid_ctrl_code_0,stat_rx_bad_code_0,stat_rx_bad_code_valid_0,stat_rx_error_valid_0,stat_rx_error_0[7:0],stat_rx_fifo_error_0,stat_rx_local_fault_0,stat_rx_status_0,tx_reset_0,user_tx_reset_0,tx_mii_d_0[63:0],tx_mii_c_0[7:0],ctl_tx_test_pattern_0,ctl_tx_test_pattern_enable_0,ctl_tx_test_pattern_select_0,ctl_tx_data_pattern_select_0,ctl_tx_test_pattern_seed_a_0[57:0],ctl_tx_test_pattern_seed_b_0[57:0],ctl_tx_prbs31_test_pattern_enable_0,stat_tx_local_fault_0,gt_dmonitorout_0[16:0],gt_eyescandataerror_0[0:0],gt_eyescanreset_0[0:0],gt_eyescantrigger_0[0:0],gt_pcsrsvdin_0[15:0],gt_rxbufreset_0[0:0],gt_rxbufstatus_0[2:0],gt_rxcdrhold_0[0:0],gt_rxcommadeten_0[0:0],gt_rxdfeagchold_0[0:0],gt_rxdfelpmreset_0[0:0],gt_rxlatclk_0[0:0],gt_rxlpmen_0[0:0],gt_rxpcsreset_0[0:0],gt_rxpmareset_0[0:0],gt_rxpolarity_0[0:0],gt_rxprbscntreset_0[0:0],gt_rxprbserr_0[0:0],gt_rxprbslocked_0[0:0],gt_txresetdone_0[0:0],gt_rxprbssel_0[3:0],gt_rxrate_0[2:0],gt_rxslide_in_0[0:0],gt_rxstartofseq_0[1:0],gt_txbufstatus_0[1:0],gt_txinhibit_0[0:0],gt_txlatclk_0[0:0],gt_txmaincursor_0[6:0],gt_txpcsreset_0[0:0],gt_txpmareset_0[0:0],gt_txpolarity_0[0:0],gt_txpostcursor_0[4:0],gt_txprbsforceerr_0[0:0],gt_txelecidle_0[0:0],gt_txprbssel_0[3:0],gt_txprecursor_0[4:0],gt_txdiffctrl_0[4:0],gt_drpdo_0[15:0],gt_drprdy_0[0:0],gt_drpen_0[0:0],gt_drpwe_0[0:0],gt_drpaddr_0[9:0],gt_drpdi_0[15:0],gt_drprst_0,gtwiz_reset_tx_datapath_0,gtwiz_reset_rx_datapath_0,gtpowergood_out_0,txoutclksel_in_0[2:0],rxoutclksel_in_0[2:0],gt_refclk_p[0:0],gt_refclk_n[0:0],gt_refclk_out[0:0],qpllreset_in_0,ctl_rx_wdt_disable_0,sys_reset" */
/* synthesis syn_force_seq_prim="tx_mii_clk_0" */
/* synthesis syn_force_seq_prim="rx_core_clk_0" */
/* synthesis syn_force_seq_prim="rx_clk_out_0" */
/* synthesis syn_force_seq_prim="gt_drpclk_0" */
/* synthesis syn_force_seq_prim="dclk" */;
  input gt_rxp_in_0;
  input gt_rxn_in_0;
  output gt_txp_out_0;
  output gt_txn_out_0;
  output tx_mii_clk_0 /* synthesis syn_isclock = 1 */;
  input rx_core_clk_0 /* synthesis syn_isclock = 1 */;
  output rx_clk_out_0 /* synthesis syn_isclock = 1 */;
  input [2:0]gt_loopback_in_0;
  input rx_reset_0;
  output user_rx_reset_0;
  output rxrecclkout_0;
  output [63:0]rx_mii_d_0;
  output [7:0]rx_mii_c_0;
  input ctl_rx_test_pattern_0;
  input ctl_rx_test_pattern_enable_0;
  input ctl_rx_data_pattern_select_0;
  input ctl_rx_prbs31_test_pattern_enable_0;
  output stat_rx_block_lock_0;
  output stat_rx_framing_err_valid_0;
  output stat_rx_framing_err_0;
  output stat_rx_hi_ber_0;
  output stat_rx_valid_ctrl_code_0;
  output stat_rx_bad_code_0;
  output stat_rx_bad_code_valid_0;
  output stat_rx_error_valid_0;
  output [7:0]stat_rx_error_0;
  output stat_rx_fifo_error_0;
  output stat_rx_local_fault_0;
  output stat_rx_status_0;
  input tx_reset_0;
  output user_tx_reset_0;
  input [63:0]tx_mii_d_0;
  input [7:0]tx_mii_c_0;
  input ctl_tx_test_pattern_0;
  input ctl_tx_test_pattern_enable_0;
  input ctl_tx_test_pattern_select_0;
  input ctl_tx_data_pattern_select_0;
  input [57:0]ctl_tx_test_pattern_seed_a_0;
  input [57:0]ctl_tx_test_pattern_seed_b_0;
  input ctl_tx_prbs31_test_pattern_enable_0;
  output stat_tx_local_fault_0;
  output [16:0]gt_dmonitorout_0;
  output [0:0]gt_eyescandataerror_0;
  input [0:0]gt_eyescanreset_0;
  input [0:0]gt_eyescantrigger_0;
  input [15:0]gt_pcsrsvdin_0;
  input [0:0]gt_rxbufreset_0;
  output [2:0]gt_rxbufstatus_0;
  input [0:0]gt_rxcdrhold_0;
  input [0:0]gt_rxcommadeten_0;
  input [0:0]gt_rxdfeagchold_0;
  input [0:0]gt_rxdfelpmreset_0;
  input [0:0]gt_rxlatclk_0;
  input [0:0]gt_rxlpmen_0;
  input [0:0]gt_rxpcsreset_0;
  input [0:0]gt_rxpmareset_0;
  input [0:0]gt_rxpolarity_0;
  input [0:0]gt_rxprbscntreset_0;
  output [0:0]gt_rxprbserr_0;
  output [0:0]gt_rxprbslocked_0;
  output [0:0]gt_txresetdone_0;
  input [3:0]gt_rxprbssel_0;
  input [2:0]gt_rxrate_0;
  input [0:0]gt_rxslide_in_0;
  output [1:0]gt_rxstartofseq_0;
  output [1:0]gt_txbufstatus_0;
  input [0:0]gt_txinhibit_0;
  input [0:0]gt_txlatclk_0;
  input [6:0]gt_txmaincursor_0;
  input [0:0]gt_txpcsreset_0;
  input [0:0]gt_txpmareset_0;
  input [0:0]gt_txpolarity_0;
  input [4:0]gt_txpostcursor_0;
  input [0:0]gt_txprbsforceerr_0;
  input [0:0]gt_txelecidle_0;
  input [3:0]gt_txprbssel_0;
  input [4:0]gt_txprecursor_0;
  input [4:0]gt_txdiffctrl_0;
  output [15:0]gt_drpdo_0;
  output [0:0]gt_drprdy_0;
  input [0:0]gt_drpen_0;
  input [0:0]gt_drpwe_0;
  input [9:0]gt_drpaddr_0;
  input [15:0]gt_drpdi_0;
  input gt_drpclk_0 /* synthesis syn_isclock = 1 */;
  input gt_drprst_0;
  input gtwiz_reset_tx_datapath_0;
  input gtwiz_reset_rx_datapath_0;
  output gtpowergood_out_0;
  input [2:0]txoutclksel_in_0;
  input [2:0]rxoutclksel_in_0;
  input [0:0]gt_refclk_p;
  input [0:0]gt_refclk_n;
  output [0:0]gt_refclk_out;
  input qpllreset_in_0;
  input ctl_rx_wdt_disable_0;
  input sys_reset;
  input dclk /* synthesis syn_isclock = 1 */;
endmodule
