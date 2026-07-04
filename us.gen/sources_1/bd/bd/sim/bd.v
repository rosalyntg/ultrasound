//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//Copyright 2022-2026 Advanced Micro Devices, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2025.2.1 (lin64) Build 6403652 Thu Mar 19 13:47:00 MDT 2026
//Date        : Sat Jul  4 14:23:05 2026
//Host        : russell-shotover-arch running 64-bit Ubuntu 22.04.5 LTS
//Command     : generate_target bd.bd
//Design      : bd
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

(* CORE_GENERATION_INFO = "bd,IP_Integrator,{x_ipVendor=xilinx.com,x_ipLibrary=BlockDiagram,x_ipName=bd,x_ipVersion=1.00.a,x_ipLanguage=VERILOG,numBlks=28,numReposBlks=27,numNonXlnxBlks=0,numHierBlks=1,maxHierDepth=1,numSysgenBlks=0,numHlsBlks=0,numHdlrefBlks=1,numPkgbdBlks=0,bdsource=USER,da_microblaze_riscv_cnt=1,synth_mode=Hierarchical}" *) (* HW_HANDOFF = "bd.hwdef" *) 
module bd
   (eth_refclk_clk_n,
    eth_refclk_clk_p,
    jesd_coreclk_clk_n,
    jesd_coreclk_clk_p,
    jesd_refclk_clk_n,
    jesd_refclk_clk_p,
    jesd_rxn,
    jesd_rxp,
    led,
    osc_200mhz_clk_n,
    osc_200mhz_clk_p,
    sfp_i2c_scl_i,
    sfp_i2c_scl_o,
    sfp_i2c_scl_t,
    sfp_i2c_sda_i,
    sfp_i2c_sda_o,
    sfp_i2c_sda_t,
    sfp_mod_abs,
    sfp_rx_gt_port_0_n,
    sfp_rx_gt_port_0_p,
    sfp_rx_gt_port_1_n,
    sfp_rx_gt_port_1_p,
    sfp_tx_gt_port_0_n,
    sfp_tx_gt_port_0_p,
    sfp_tx_gt_port_1_n,
    sfp_tx_gt_port_1_p);
  (* X_INTERFACE_INFO = "xilinx.com:interface:diff_clock:1.0 eth_refclk CLK_N" *) (* X_INTERFACE_MODE = "Slave" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME eth_refclk, CAN_DEBUG false, FREQ_HZ 156250000" *) input eth_refclk_clk_n;
  (* X_INTERFACE_INFO = "xilinx.com:interface:diff_clock:1.0 eth_refclk CLK_P" *) input eth_refclk_clk_p;
  (* X_INTERFACE_INFO = "xilinx.com:interface:diff_clock:1.0 jesd_coreclk CLK_N" *) (* X_INTERFACE_MODE = "Slave" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME jesd_coreclk, CAN_DEBUG false, FREQ_HZ 100000000" *) input [0:0]jesd_coreclk_clk_n;
  (* X_INTERFACE_INFO = "xilinx.com:interface:diff_clock:1.0 jesd_coreclk CLK_P" *) input [0:0]jesd_coreclk_clk_p;
  (* X_INTERFACE_INFO = "xilinx.com:interface:diff_clock:1.0 jesd_refclk CLK_N" *) (* X_INTERFACE_MODE = "Slave" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME jesd_refclk, CAN_DEBUG false, FREQ_HZ 100000000" *) input [0:0]jesd_refclk_clk_n;
  (* X_INTERFACE_INFO = "xilinx.com:interface:diff_clock:1.0 jesd_refclk CLK_P" *) input [0:0]jesd_refclk_clk_p;
  input [3:0]jesd_rxn;
  input [3:0]jesd_rxp;
  output [1:0]led;
  (* X_INTERFACE_INFO = "xilinx.com:interface:diff_clock:1.0 osc_200mhz CLK_N" *) (* X_INTERFACE_MODE = "Slave" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME osc_200mhz, CAN_DEBUG false, FREQ_HZ 200000000" *) input osc_200mhz_clk_n;
  (* X_INTERFACE_INFO = "xilinx.com:interface:diff_clock:1.0 osc_200mhz CLK_P" *) input osc_200mhz_clk_p;
  (* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 sfp_i2c SCL_I" *) (* X_INTERFACE_MODE = "Master" *) input sfp_i2c_scl_i;
  (* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 sfp_i2c SCL_O" *) output sfp_i2c_scl_o;
  (* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 sfp_i2c SCL_T" *) output sfp_i2c_scl_t;
  (* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 sfp_i2c SDA_I" *) input sfp_i2c_sda_i;
  (* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 sfp_i2c SDA_O" *) output sfp_i2c_sda_o;
  (* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 sfp_i2c SDA_T" *) output sfp_i2c_sda_t;
  input [0:0]sfp_mod_abs;
  (* X_INTERFACE_INFO = "xilinx.com:display_xxv_ethernet:gt_ports_int:2.0 sfp_rx gt_port_0_n" *) (* X_INTERFACE_MODE = "Slave" *) input sfp_rx_gt_port_0_n;
  (* X_INTERFACE_INFO = "xilinx.com:display_xxv_ethernet:gt_ports_int:2.0 sfp_rx gt_port_0_p" *) input sfp_rx_gt_port_0_p;
  (* X_INTERFACE_INFO = "xilinx.com:display_xxv_ethernet:gt_ports_int:2.0 sfp_rx gt_port_1_n" *) input sfp_rx_gt_port_1_n;
  (* X_INTERFACE_INFO = "xilinx.com:display_xxv_ethernet:gt_ports_int:2.0 sfp_rx gt_port_1_p" *) input sfp_rx_gt_port_1_p;
  (* X_INTERFACE_INFO = "xilinx.com:display_xxv_ethernet:gt_ports_int:2.0 sfp_tx gt_port_0_n" *) (* X_INTERFACE_MODE = "Master" *) output sfp_tx_gt_port_0_n;
  (* X_INTERFACE_INFO = "xilinx.com:display_xxv_ethernet:gt_ports_int:2.0 sfp_tx gt_port_0_p" *) output sfp_tx_gt_port_0_p;
  (* X_INTERFACE_INFO = "xilinx.com:display_xxv_ethernet:gt_ports_int:2.0 sfp_tx gt_port_1_n" *) output sfp_tx_gt_port_1_n;
  (* X_INTERFACE_INFO = "xilinx.com:display_xxv_ethernet:gt_ports_int:2.0 sfp_tx gt_port_1_p" *) output sfp_tx_gt_port_1_p;

  wire [15:0]c_counter_binary_0_Q;
  wire [15:0]c_counter_binary_1_Q;
  wire [0:0]clear_arp_cache;
  wire [0:0]drprst0;
  wire [0:0]drprst1;
  wire eth_refclk_clk_n;
  wire eth_refclk_clk_p;
  wire [31:0]gateway_ip;
  wire [0:0]ilconstant_1_dout;
  wire [0:0]jesd_coreclk_clk_n;
  wire [0:0]jesd_coreclk_clk_p;
  wire [0:0]jesd_refclk_clk_n;
  wire [0:0]jesd_refclk_clk_p;
  wire [3:0]jesd_rxn;
  wire [3:0]jesd_rxp;
  wire [1:0]led;
  wire [31:0]local_ip;
  wire [47:0]local_mac;
  wire [0:0]logic_rst;
  wire mdm_1_debug_sys_rst;
  wire microblaze_riscv_0_Clk;
  wire [31:0]microblaze_riscv_0_axi_dp_ARADDR;
  wire [2:0]microblaze_riscv_0_axi_dp_ARPROT;
  wire microblaze_riscv_0_axi_dp_ARREADY;
  wire microblaze_riscv_0_axi_dp_ARVALID;
  wire [31:0]microblaze_riscv_0_axi_dp_AWADDR;
  wire [2:0]microblaze_riscv_0_axi_dp_AWPROT;
  wire microblaze_riscv_0_axi_dp_AWREADY;
  wire microblaze_riscv_0_axi_dp_AWVALID;
  wire microblaze_riscv_0_axi_dp_BREADY;
  wire [1:0]microblaze_riscv_0_axi_dp_BRESP;
  wire microblaze_riscv_0_axi_dp_BVALID;
  wire [31:0]microblaze_riscv_0_axi_dp_RDATA;
  wire microblaze_riscv_0_axi_dp_RREADY;
  wire [1:0]microblaze_riscv_0_axi_dp_RRESP;
  wire microblaze_riscv_0_axi_dp_RVALID;
  wire [31:0]microblaze_riscv_0_axi_dp_WDATA;
  wire microblaze_riscv_0_axi_dp_WREADY;
  wire [3:0]microblaze_riscv_0_axi_dp_WSTRB;
  wire microblaze_riscv_0_axi_dp_WVALID;
  wire [8:0]microblaze_riscv_0_axi_periph_M02_AXI_ARADDR;
  wire microblaze_riscv_0_axi_periph_M02_AXI_ARREADY;
  wire microblaze_riscv_0_axi_periph_M02_AXI_ARVALID;
  wire [8:0]microblaze_riscv_0_axi_periph_M02_AXI_AWADDR;
  wire microblaze_riscv_0_axi_periph_M02_AXI_AWREADY;
  wire microblaze_riscv_0_axi_periph_M02_AXI_AWVALID;
  wire microblaze_riscv_0_axi_periph_M02_AXI_BREADY;
  wire [1:0]microblaze_riscv_0_axi_periph_M02_AXI_BRESP;
  wire microblaze_riscv_0_axi_periph_M02_AXI_BVALID;
  wire [31:0]microblaze_riscv_0_axi_periph_M02_AXI_RDATA;
  wire microblaze_riscv_0_axi_periph_M02_AXI_RREADY;
  wire [1:0]microblaze_riscv_0_axi_periph_M02_AXI_RRESP;
  wire microblaze_riscv_0_axi_periph_M02_AXI_RVALID;
  wire [31:0]microblaze_riscv_0_axi_periph_M02_AXI_WDATA;
  wire microblaze_riscv_0_axi_periph_M02_AXI_WREADY;
  wire [3:0]microblaze_riscv_0_axi_periph_M02_AXI_WSTRB;
  wire microblaze_riscv_0_axi_periph_M02_AXI_WVALID;
  wire microblaze_riscv_0_debug_CAPTURE;
  wire microblaze_riscv_0_debug_CLK;
  wire microblaze_riscv_0_debug_DISABLE;
  wire [0:7]microblaze_riscv_0_debug_REG_EN;
  wire microblaze_riscv_0_debug_RST;
  wire microblaze_riscv_0_debug_SHIFT;
  wire microblaze_riscv_0_debug_TDI;
  wire microblaze_riscv_0_debug_TDO;
  wire microblaze_riscv_0_debug_UPDATE;
  wire [0:31]microblaze_riscv_0_dlmb_1_ABUS;
  wire microblaze_riscv_0_dlmb_1_ADDRSTROBE;
  wire [0:3]microblaze_riscv_0_dlmb_1_BE;
  wire microblaze_riscv_0_dlmb_1_CE;
  wire [0:31]microblaze_riscv_0_dlmb_1_READDBUS;
  wire microblaze_riscv_0_dlmb_1_READSTROBE;
  wire microblaze_riscv_0_dlmb_1_READY;
  wire microblaze_riscv_0_dlmb_1_UE;
  wire microblaze_riscv_0_dlmb_1_WAIT;
  wire [0:31]microblaze_riscv_0_dlmb_1_WRITEDBUS;
  wire microblaze_riscv_0_dlmb_1_WRITESTROBE;
  wire [0:31]microblaze_riscv_0_ilmb_1_ABUS;
  wire microblaze_riscv_0_ilmb_1_ADDRSTROBE;
  wire microblaze_riscv_0_ilmb_1_CE;
  wire [0:31]microblaze_riscv_0_ilmb_1_READDBUS;
  wire microblaze_riscv_0_ilmb_1_READSTROBE;
  wire microblaze_riscv_0_ilmb_1_READY;
  wire microblaze_riscv_0_ilmb_1_UE;
  wire microblaze_riscv_0_ilmb_1_WAIT;
  wire [8:0]microblaze_riscv_0_intc_axi_ARADDR;
  wire microblaze_riscv_0_intc_axi_ARREADY;
  wire microblaze_riscv_0_intc_axi_ARVALID;
  wire [8:0]microblaze_riscv_0_intc_axi_AWADDR;
  wire microblaze_riscv_0_intc_axi_AWREADY;
  wire microblaze_riscv_0_intc_axi_AWVALID;
  wire microblaze_riscv_0_intc_axi_BREADY;
  wire [1:0]microblaze_riscv_0_intc_axi_BRESP;
  wire microblaze_riscv_0_intc_axi_BVALID;
  wire [31:0]microblaze_riscv_0_intc_axi_RDATA;
  wire microblaze_riscv_0_intc_axi_RREADY;
  wire [1:0]microblaze_riscv_0_intc_axi_RRESP;
  wire microblaze_riscv_0_intc_axi_RVALID;
  wire [31:0]microblaze_riscv_0_intc_axi_WDATA;
  wire microblaze_riscv_0_intc_axi_WREADY;
  wire [3:0]microblaze_riscv_0_intc_axi_WSTRB;
  wire microblaze_riscv_0_intc_axi_WVALID;
  wire [0:1]microblaze_riscv_0_interrupt_ACK;
  wire [31:0]microblaze_riscv_0_interrupt_ADDRESS;
  wire microblaze_riscv_0_interrupt_INTERRUPT;
  wire [1:0]microblaze_riscv_0_intr;
  wire [3:0]microblaze_riscv_0_mdm_axi_ARADDR;
  wire microblaze_riscv_0_mdm_axi_ARREADY;
  wire microblaze_riscv_0_mdm_axi_ARVALID;
  wire [3:0]microblaze_riscv_0_mdm_axi_AWADDR;
  wire microblaze_riscv_0_mdm_axi_AWREADY;
  wire microblaze_riscv_0_mdm_axi_AWVALID;
  wire microblaze_riscv_0_mdm_axi_BREADY;
  wire [1:0]microblaze_riscv_0_mdm_axi_BRESP;
  wire microblaze_riscv_0_mdm_axi_BVALID;
  wire [31:0]microblaze_riscv_0_mdm_axi_RDATA;
  wire microblaze_riscv_0_mdm_axi_RREADY;
  wire [1:0]microblaze_riscv_0_mdm_axi_RRESP;
  wire microblaze_riscv_0_mdm_axi_RVALID;
  wire [31:0]microblaze_riscv_0_mdm_axi_WDATA;
  wire microblaze_riscv_0_mdm_axi_WREADY;
  wire [3:0]microblaze_riscv_0_mdm_axi_WSTRB;
  wire microblaze_riscv_0_mdm_axi_WVALID;
  wire net_wrapper_0_ip_rx_busy;
  wire net_wrapper_0_ip_tx_busy;
  wire [31:0]net_wrapper_0_m_axi_ARADDR;
  wire net_wrapper_0_m_axi_ARREADY;
  wire net_wrapper_0_m_axi_ARVALID;
  wire [31:0]net_wrapper_0_m_axi_AWADDR;
  wire net_wrapper_0_m_axi_AWREADY;
  wire net_wrapper_0_m_axi_AWVALID;
  wire net_wrapper_0_m_axi_BREADY;
  wire [1:0]net_wrapper_0_m_axi_BRESP;
  wire net_wrapper_0_m_axi_BVALID;
  wire [31:0]net_wrapper_0_m_axi_RDATA;
  wire net_wrapper_0_m_axi_RREADY;
  wire [1:0]net_wrapper_0_m_axi_RRESP;
  wire net_wrapper_0_m_axi_RVALID;
  wire [31:0]net_wrapper_0_m_axi_WDATA;
  wire net_wrapper_0_m_axi_WREADY;
  wire [3:0]net_wrapper_0_m_axi_WSTRB;
  wire net_wrapper_0_m_axi_WVALID;
  wire net_wrapper_0_rx_error_bad_fcs;
  wire net_wrapper_0_rx_error_bad_frame;
  wire net_wrapper_0_tx_eth_hdr_ready;
  wire net_wrapper_0_tx_eth_hdr_valid;
  wire net_wrapper_0_udp_rx_busy;
  wire net_wrapper_0_udp_tx_busy;
  wire [7:0]net_wrapper_0_xgmii_txc;
  wire [63:0]net_wrapper_0_xgmii_txd;
  wire osc_200mhz_clk_n;
  wire osc_200mhz_clk_p;
  wire [0:0]qpllreset;
  wire [0:0]reset_rx_datapath0;
  wire [0:0]reset_rx_datapath1;
  wire [0:0]reset_tx_datapath0;
  wire [0:0]reset_tx_datapath1;
  wire [0:0]rst_sysclk_wiz_25M_bus_struct_reset;
  wire rst_sysclk_wiz_25M_mb_reset;
  wire [0:0]rst_sysclk_wiz_25M_peripheral_aresetn;
  wire [0:0]rx_reset;
  wire [0:0]rx_rst;
  wire sfp_i2c_iic2intc_irpt;
  wire sfp_i2c_scl_i;
  wire sfp_i2c_scl_o;
  wire sfp_i2c_scl_t;
  wire sfp_i2c_sda_i;
  wire sfp_i2c_sda_o;
  wire sfp_i2c_sda_t;
  wire [0:0]sfp_mod_abs;
  wire sfp_rx_gt_port_0_n;
  wire sfp_rx_gt_port_0_p;
  wire sfp_rx_gt_port_1_n;
  wire sfp_rx_gt_port_1_p;
  wire sfp_tx_gt_port_0_n;
  wire sfp_tx_gt_port_0_p;
  wire sfp_tx_gt_port_1_n;
  wire sfp_tx_gt_port_1_p;
  wire [31:0]subnet_mask;
  wire [0:0]sys_reset;
  wire [0:0]tx_reset;
  wire [0:0]tx_rst;
  wire [0:0]tx_test;
  wire [4:0]txdiffctrl;
  wire [0:0]txpolarity;
  wire [4:0]txpostcursor;
  wire [4:0]txprecursor;
  wire [0:0]txreset0;
  wire [0:0]util_ds_buf_0_IBUF_OUT;
  wire [0:0]util_ds_buf_1_BUFGCE_O;
  wire [2:0]vio_eth_probe_out10;
  wire [0:0]vio_eth_probe_out11;
  wire [1:0]xxv_ethernet_0_gt_txbufstatus_1;
  wire xxv_ethernet_0_gtpowergood_out_0;
  wire xxv_ethernet_0_rx_clk_out_0;
  wire xxv_ethernet_0_rx_clk_out_1;
  wire [7:0]xxv_ethernet_0_rx_mii_c_0;
  wire [63:0]xxv_ethernet_0_rx_mii_d_0;
  wire xxv_ethernet_0_stat_rx_bad_code_0;
  wire xxv_ethernet_0_stat_rx_bad_code_valid_0;
  wire xxv_ethernet_0_stat_rx_block_lock_0;
  wire [7:0]xxv_ethernet_0_stat_rx_error_0;
  wire xxv_ethernet_0_stat_rx_error_valid_0;
  wire xxv_ethernet_0_stat_rx_fifo_error_0;
  wire xxv_ethernet_0_stat_rx_framing_err_0;
  wire xxv_ethernet_0_stat_rx_framing_err_valid_0;
  wire xxv_ethernet_0_stat_rx_hi_ber_0;
  wire xxv_ethernet_0_stat_rx_local_fault_0;
  wire xxv_ethernet_0_stat_rx_status_0;
  wire xxv_ethernet_0_stat_rx_valid_ctrl_code_0;
  wire xxv_ethernet_0_stat_tx_local_fault_0;
  wire xxv_ethernet_0_tx_mii_clk_1;
  wire xxv_ethernet_0_user_rx_reset_0;
  wire xxv_ethernet_0_user_tx_reset_1;

  bd_axi_gpio_0_0 axi_gpio_0
       (.gpio_io_o(led),
        .s_axi_aclk(xxv_ethernet_0_rx_clk_out_0),
        .s_axi_araddr(net_wrapper_0_m_axi_ARADDR[8:0]),
        .s_axi_aresetn(logic_rst),
        .s_axi_arready(net_wrapper_0_m_axi_ARREADY),
        .s_axi_arvalid(net_wrapper_0_m_axi_ARVALID),
        .s_axi_awaddr(net_wrapper_0_m_axi_AWADDR[8:0]),
        .s_axi_awready(net_wrapper_0_m_axi_AWREADY),
        .s_axi_awvalid(net_wrapper_0_m_axi_AWVALID),
        .s_axi_bready(net_wrapper_0_m_axi_BREADY),
        .s_axi_bresp(net_wrapper_0_m_axi_BRESP),
        .s_axi_bvalid(net_wrapper_0_m_axi_BVALID),
        .s_axi_rdata(net_wrapper_0_m_axi_RDATA),
        .s_axi_rready(net_wrapper_0_m_axi_RREADY),
        .s_axi_rresp(net_wrapper_0_m_axi_RRESP),
        .s_axi_rvalid(net_wrapper_0_m_axi_RVALID),
        .s_axi_wdata(net_wrapper_0_m_axi_WDATA),
        .s_axi_wready(net_wrapper_0_m_axi_WREADY),
        .s_axi_wstrb(net_wrapper_0_m_axi_WSTRB),
        .s_axi_wvalid(net_wrapper_0_m_axi_WVALID));
  bd_c_counter_binary_0_0 c_counter_binary_0
       (.CLK(xxv_ethernet_0_rx_clk_out_0),
        .Q(c_counter_binary_0_Q));
  bd_c_counter_binary_1_0 c_counter_binary_1
       (.CLK(xxv_ethernet_0_tx_mii_clk_1),
        .Q(c_counter_binary_1_Q));
  bd_ila_0_0 ila_0
       (.clk(xxv_ethernet_0_tx_mii_clk_1),
        .probe0(net_wrapper_0_xgmii_txd),
        .probe1(net_wrapper_0_xgmii_txc),
        .probe2(net_wrapper_0_tx_eth_hdr_valid),
        .probe3(net_wrapper_0_tx_eth_hdr_ready));
  
  assign ilconstant_1_dout = 1'h1;
  bd_jesd204_phy_0_0 jesd204_phy_0
       (.cpll_refclk(util_ds_buf_0_IBUF_OUT),
        .drpclk(microblaze_riscv_0_Clk),
        .gt0_drpaddr({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .gt0_drpdi({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .gt0_drpen(1'b0),
        .gt0_drpwe(1'b0),
        .gt0_txcharisk({1'b0,1'b0,1'b0,1'b0}),
        .gt0_txdata({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .gt0_txheader({1'b0,1'b0}),
        .gt1_drpaddr({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .gt1_drpdi({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .gt1_drpen(1'b0),
        .gt1_drpwe(1'b0),
        .gt1_txcharisk({1'b0,1'b0,1'b0,1'b0}),
        .gt1_txdata({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .gt1_txheader({1'b0,1'b0}),
        .gt2_drpaddr({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .gt2_drpdi({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .gt2_drpen(1'b0),
        .gt2_drpwe(1'b0),
        .gt2_txcharisk({1'b0,1'b0,1'b0,1'b0}),
        .gt2_txdata({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .gt2_txheader({1'b0,1'b0}),
        .gt3_drpaddr({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .gt3_drpdi({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .gt3_drpen(1'b0),
        .gt3_drpwe(1'b0),
        .gt3_txcharisk({1'b0,1'b0,1'b0,1'b0}),
        .gt3_txdata({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .gt3_txheader({1'b0,1'b0}),
        .gt_dmonitorclk({1'b0,1'b0,1'b0,1'b0}),
        .gt_eyescanreset({1'b0,1'b0,1'b0,1'b0}),
        .gt_eyescantrigger({1'b0,1'b0,1'b0,1'b0}),
        .gt_loopback({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .gt_pcsrsvdin({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .gt_rxbufreset({1'b0,1'b0,1'b0,1'b0}),
        .gt_rxcdrhold({1'b0,1'b0,1'b0,1'b0}),
        .gt_rxdfelpmreset({1'b0,1'b0,1'b0,1'b0}),
        .gt_rxlpmen({1'b0,1'b0,1'b0,1'b0}),
        .gt_rxpcsreset({1'b0,1'b0,1'b0,1'b0}),
        .gt_rxpd({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .gt_rxpmareset({1'b0,1'b0,1'b0,1'b0}),
        .gt_rxpolarity({1'b0,1'b0,1'b0,1'b0}),
        .gt_rxprbscntreset({1'b0,1'b0,1'b0,1'b0}),
        .gt_rxprbssel({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .gt_rxrate({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .gt_txdiffctrl({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b1,1'b0,1'b0,1'b0}),
        .gt_txinhibit({1'b0,1'b0,1'b0,1'b0}),
        .gt_txpcsreset({1'b0,1'b0,1'b0,1'b0}),
        .gt_txpd({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .gt_txpmareset({1'b0,1'b0,1'b0,1'b0}),
        .gt_txpolarity({1'b0,1'b0,1'b0,1'b0}),
        .gt_txpostcursor({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .gt_txprbsforceerr({1'b0,1'b0,1'b0,1'b0}),
        .gt_txprecursor({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .rx_core_clk(util_ds_buf_1_BUFGCE_O),
        .rx_reset_gt(1'b0),
        .rx_sys_reset(1'b0),
        .rxencommaalign(1'b0),
        .rxn_in(jesd_rxn),
        .rxp_in(jesd_rxp),
        .tx_core_clk(util_ds_buf_1_BUFGCE_O),
        .tx_reset_gt(1'b0),
        .tx_sys_reset(1'b0));
  bd_util_ds_buf_1_1 jesd_coreclk_buf
       (.IBUF_DS_N(jesd_coreclk_clk_n),
        .IBUF_DS_P(jesd_coreclk_clk_p),
        .IBUF_OUT(util_ds_buf_1_BUFGCE_O));
  bd_mdm_1_0 mdm_1
       (.Dbg_Capture_0(microblaze_riscv_0_debug_CAPTURE),
        .Dbg_Clk_0(microblaze_riscv_0_debug_CLK),
        .Dbg_Disable_0(microblaze_riscv_0_debug_DISABLE),
        .Dbg_Reg_En_0(microblaze_riscv_0_debug_REG_EN),
        .Dbg_Rst_0(microblaze_riscv_0_debug_RST),
        .Dbg_Shift_0(microblaze_riscv_0_debug_SHIFT),
        .Dbg_TDI_0(microblaze_riscv_0_debug_TDI),
        .Dbg_TDO_0(microblaze_riscv_0_debug_TDO),
        .Dbg_Update_0(microblaze_riscv_0_debug_UPDATE),
        .Debug_SYS_Rst(mdm_1_debug_sys_rst),
        .S_AXI_ACLK(microblaze_riscv_0_Clk),
        .S_AXI_ARADDR(microblaze_riscv_0_mdm_axi_ARADDR),
        .S_AXI_ARESETN(rst_sysclk_wiz_25M_peripheral_aresetn),
        .S_AXI_ARREADY(microblaze_riscv_0_mdm_axi_ARREADY),
        .S_AXI_ARVALID(microblaze_riscv_0_mdm_axi_ARVALID),
        .S_AXI_AWADDR(microblaze_riscv_0_mdm_axi_AWADDR),
        .S_AXI_AWREADY(microblaze_riscv_0_mdm_axi_AWREADY),
        .S_AXI_AWVALID(microblaze_riscv_0_mdm_axi_AWVALID),
        .S_AXI_BREADY(microblaze_riscv_0_mdm_axi_BREADY),
        .S_AXI_BRESP(microblaze_riscv_0_mdm_axi_BRESP),
        .S_AXI_BVALID(microblaze_riscv_0_mdm_axi_BVALID),
        .S_AXI_RDATA(microblaze_riscv_0_mdm_axi_RDATA),
        .S_AXI_RREADY(microblaze_riscv_0_mdm_axi_RREADY),
        .S_AXI_RRESP(microblaze_riscv_0_mdm_axi_RRESP),
        .S_AXI_RVALID(microblaze_riscv_0_mdm_axi_RVALID),
        .S_AXI_WDATA(microblaze_riscv_0_mdm_axi_WDATA),
        .S_AXI_WREADY(microblaze_riscv_0_mdm_axi_WREADY),
        .S_AXI_WSTRB(microblaze_riscv_0_mdm_axi_WSTRB),
        .S_AXI_WVALID(microblaze_riscv_0_mdm_axi_WVALID));
  (* BMM_INFO_PROCESSOR = "riscv > bd microblaze_riscv_0_local_memory/dlmb_bram_if_cntlr" *) 
  (* KEEP_HIERARCHY = "YES" *) 
  bd_microblaze_riscv_0_0 microblaze_riscv_0
       (.Byte_Enable(microblaze_riscv_0_dlmb_1_BE),
        .Clk(microblaze_riscv_0_Clk),
        .DCE(microblaze_riscv_0_dlmb_1_CE),
        .DReady(microblaze_riscv_0_dlmb_1_READY),
        .DUE(microblaze_riscv_0_dlmb_1_UE),
        .DWait(microblaze_riscv_0_dlmb_1_WAIT),
        .D_AS(microblaze_riscv_0_dlmb_1_ADDRSTROBE),
        .Data_Addr(microblaze_riscv_0_dlmb_1_ABUS),
        .Data_Read(microblaze_riscv_0_dlmb_1_READDBUS),
        .Data_Write(microblaze_riscv_0_dlmb_1_WRITEDBUS),
        .Dbg_Capture(microblaze_riscv_0_debug_CAPTURE),
        .Dbg_Clk(microblaze_riscv_0_debug_CLK),
        .Dbg_Disable(microblaze_riscv_0_debug_DISABLE),
        .Dbg_Reg_En(microblaze_riscv_0_debug_REG_EN),
        .Dbg_Shift(microblaze_riscv_0_debug_SHIFT),
        .Dbg_TDI(microblaze_riscv_0_debug_TDI),
        .Dbg_TDO(microblaze_riscv_0_debug_TDO),
        .Dbg_Trig_Ack_In({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .Dbg_Trig_Out({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .Dbg_Update(microblaze_riscv_0_debug_UPDATE),
        .Debug_Rst(microblaze_riscv_0_debug_RST),
        .ICE(microblaze_riscv_0_ilmb_1_CE),
        .IFetch(microblaze_riscv_0_ilmb_1_READSTROBE),
        .IReady(microblaze_riscv_0_ilmb_1_READY),
        .IUE(microblaze_riscv_0_ilmb_1_UE),
        .IWAIT(microblaze_riscv_0_ilmb_1_WAIT),
        .I_AS(microblaze_riscv_0_ilmb_1_ADDRSTROBE),
        .Instr(microblaze_riscv_0_ilmb_1_READDBUS),
        .Instr_Addr(microblaze_riscv_0_ilmb_1_ABUS),
        .Interrupt(microblaze_riscv_0_interrupt_INTERRUPT),
        .Interrupt_Ack(microblaze_riscv_0_interrupt_ACK),
        .Interrupt_Address({microblaze_riscv_0_interrupt_ADDRESS[31],microblaze_riscv_0_interrupt_ADDRESS[30],microblaze_riscv_0_interrupt_ADDRESS[29],microblaze_riscv_0_interrupt_ADDRESS[28],microblaze_riscv_0_interrupt_ADDRESS[27],microblaze_riscv_0_interrupt_ADDRESS[26],microblaze_riscv_0_interrupt_ADDRESS[25],microblaze_riscv_0_interrupt_ADDRESS[24],microblaze_riscv_0_interrupt_ADDRESS[23],microblaze_riscv_0_interrupt_ADDRESS[22],microblaze_riscv_0_interrupt_ADDRESS[21],microblaze_riscv_0_interrupt_ADDRESS[20],microblaze_riscv_0_interrupt_ADDRESS[19],microblaze_riscv_0_interrupt_ADDRESS[18],microblaze_riscv_0_interrupt_ADDRESS[17],microblaze_riscv_0_interrupt_ADDRESS[16],microblaze_riscv_0_interrupt_ADDRESS[15],microblaze_riscv_0_interrupt_ADDRESS[14],microblaze_riscv_0_interrupt_ADDRESS[13],microblaze_riscv_0_interrupt_ADDRESS[12],microblaze_riscv_0_interrupt_ADDRESS[11],microblaze_riscv_0_interrupt_ADDRESS[10],microblaze_riscv_0_interrupt_ADDRESS[9],microblaze_riscv_0_interrupt_ADDRESS[8],microblaze_riscv_0_interrupt_ADDRESS[7],microblaze_riscv_0_interrupt_ADDRESS[6],microblaze_riscv_0_interrupt_ADDRESS[5],microblaze_riscv_0_interrupt_ADDRESS[4],microblaze_riscv_0_interrupt_ADDRESS[3],microblaze_riscv_0_interrupt_ADDRESS[2],microblaze_riscv_0_interrupt_ADDRESS[1],microblaze_riscv_0_interrupt_ADDRESS[0]}),
        .M_AXI_DP_ARADDR(microblaze_riscv_0_axi_dp_ARADDR),
        .M_AXI_DP_ARPROT(microblaze_riscv_0_axi_dp_ARPROT),
        .M_AXI_DP_ARREADY(microblaze_riscv_0_axi_dp_ARREADY),
        .M_AXI_DP_ARVALID(microblaze_riscv_0_axi_dp_ARVALID),
        .M_AXI_DP_AWADDR(microblaze_riscv_0_axi_dp_AWADDR),
        .M_AXI_DP_AWPROT(microblaze_riscv_0_axi_dp_AWPROT),
        .M_AXI_DP_AWREADY(microblaze_riscv_0_axi_dp_AWREADY),
        .M_AXI_DP_AWVALID(microblaze_riscv_0_axi_dp_AWVALID),
        .M_AXI_DP_BREADY(microblaze_riscv_0_axi_dp_BREADY),
        .M_AXI_DP_BRESP(microblaze_riscv_0_axi_dp_BRESP),
        .M_AXI_DP_BVALID(microblaze_riscv_0_axi_dp_BVALID),
        .M_AXI_DP_RDATA(microblaze_riscv_0_axi_dp_RDATA),
        .M_AXI_DP_RREADY(microblaze_riscv_0_axi_dp_RREADY),
        .M_AXI_DP_RRESP(microblaze_riscv_0_axi_dp_RRESP),
        .M_AXI_DP_RVALID(microblaze_riscv_0_axi_dp_RVALID),
        .M_AXI_DP_WDATA(microblaze_riscv_0_axi_dp_WDATA),
        .M_AXI_DP_WREADY(microblaze_riscv_0_axi_dp_WREADY),
        .M_AXI_DP_WSTRB(microblaze_riscv_0_axi_dp_WSTRB),
        .M_AXI_DP_WVALID(microblaze_riscv_0_axi_dp_WVALID),
        .Read_Strobe(microblaze_riscv_0_dlmb_1_READSTROBE),
        .Reset(rst_sysclk_wiz_25M_mb_reset),
        .Write_Strobe(microblaze_riscv_0_dlmb_1_WRITESTROBE));
  bd_microblaze_riscv_0_axi_intc_0 microblaze_riscv_0_axi_intc
       (.interrupt_address(microblaze_riscv_0_interrupt_ADDRESS),
        .intr(microblaze_riscv_0_intr),
        .irq(microblaze_riscv_0_interrupt_INTERRUPT),
        .processor_ack({microblaze_riscv_0_interrupt_ACK[0],microblaze_riscv_0_interrupt_ACK[1]}),
        .processor_clk(microblaze_riscv_0_Clk),
        .processor_rst(rst_sysclk_wiz_25M_mb_reset),
        .s_axi_aclk(microblaze_riscv_0_Clk),
        .s_axi_araddr(microblaze_riscv_0_intc_axi_ARADDR),
        .s_axi_aresetn(rst_sysclk_wiz_25M_peripheral_aresetn),
        .s_axi_arready(microblaze_riscv_0_intc_axi_ARREADY),
        .s_axi_arvalid(microblaze_riscv_0_intc_axi_ARVALID),
        .s_axi_awaddr(microblaze_riscv_0_intc_axi_AWADDR),
        .s_axi_awready(microblaze_riscv_0_intc_axi_AWREADY),
        .s_axi_awvalid(microblaze_riscv_0_intc_axi_AWVALID),
        .s_axi_bready(microblaze_riscv_0_intc_axi_BREADY),
        .s_axi_bresp(microblaze_riscv_0_intc_axi_BRESP),
        .s_axi_bvalid(microblaze_riscv_0_intc_axi_BVALID),
        .s_axi_rdata(microblaze_riscv_0_intc_axi_RDATA),
        .s_axi_rready(microblaze_riscv_0_intc_axi_RREADY),
        .s_axi_rresp(microblaze_riscv_0_intc_axi_RRESP),
        .s_axi_rvalid(microblaze_riscv_0_intc_axi_RVALID),
        .s_axi_wdata(microblaze_riscv_0_intc_axi_WDATA),
        .s_axi_wready(microblaze_riscv_0_intc_axi_WREADY),
        .s_axi_wstrb(microblaze_riscv_0_intc_axi_WSTRB),
        .s_axi_wvalid(microblaze_riscv_0_intc_axi_WVALID));
  bd_microblaze_riscv_0_axi_periph_0 microblaze_riscv_0_axi_periph
       (.M00_AXI_araddr(microblaze_riscv_0_intc_axi_ARADDR),
        .M00_AXI_arready(microblaze_riscv_0_intc_axi_ARREADY),
        .M00_AXI_arvalid(microblaze_riscv_0_intc_axi_ARVALID),
        .M00_AXI_awaddr(microblaze_riscv_0_intc_axi_AWADDR),
        .M00_AXI_awready(microblaze_riscv_0_intc_axi_AWREADY),
        .M00_AXI_awvalid(microblaze_riscv_0_intc_axi_AWVALID),
        .M00_AXI_bready(microblaze_riscv_0_intc_axi_BREADY),
        .M00_AXI_bresp(microblaze_riscv_0_intc_axi_BRESP),
        .M00_AXI_bvalid(microblaze_riscv_0_intc_axi_BVALID),
        .M00_AXI_rdata(microblaze_riscv_0_intc_axi_RDATA),
        .M00_AXI_rready(microblaze_riscv_0_intc_axi_RREADY),
        .M00_AXI_rresp(microblaze_riscv_0_intc_axi_RRESP),
        .M00_AXI_rvalid(microblaze_riscv_0_intc_axi_RVALID),
        .M00_AXI_wdata(microblaze_riscv_0_intc_axi_WDATA),
        .M00_AXI_wready(microblaze_riscv_0_intc_axi_WREADY),
        .M00_AXI_wstrb(microblaze_riscv_0_intc_axi_WSTRB),
        .M00_AXI_wvalid(microblaze_riscv_0_intc_axi_WVALID),
        .M01_AXI_araddr(microblaze_riscv_0_mdm_axi_ARADDR),
        .M01_AXI_arready(microblaze_riscv_0_mdm_axi_ARREADY),
        .M01_AXI_arvalid(microblaze_riscv_0_mdm_axi_ARVALID),
        .M01_AXI_awaddr(microblaze_riscv_0_mdm_axi_AWADDR),
        .M01_AXI_awready(microblaze_riscv_0_mdm_axi_AWREADY),
        .M01_AXI_awvalid(microblaze_riscv_0_mdm_axi_AWVALID),
        .M01_AXI_bready(microblaze_riscv_0_mdm_axi_BREADY),
        .M01_AXI_bresp(microblaze_riscv_0_mdm_axi_BRESP),
        .M01_AXI_bvalid(microblaze_riscv_0_mdm_axi_BVALID),
        .M01_AXI_rdata(microblaze_riscv_0_mdm_axi_RDATA),
        .M01_AXI_rready(microblaze_riscv_0_mdm_axi_RREADY),
        .M01_AXI_rresp(microblaze_riscv_0_mdm_axi_RRESP),
        .M01_AXI_rvalid(microblaze_riscv_0_mdm_axi_RVALID),
        .M01_AXI_wdata(microblaze_riscv_0_mdm_axi_WDATA),
        .M01_AXI_wready(microblaze_riscv_0_mdm_axi_WREADY),
        .M01_AXI_wstrb(microblaze_riscv_0_mdm_axi_WSTRB),
        .M01_AXI_wvalid(microblaze_riscv_0_mdm_axi_WVALID),
        .M02_AXI_araddr(microblaze_riscv_0_axi_periph_M02_AXI_ARADDR),
        .M02_AXI_arready(microblaze_riscv_0_axi_periph_M02_AXI_ARREADY),
        .M02_AXI_arvalid(microblaze_riscv_0_axi_periph_M02_AXI_ARVALID),
        .M02_AXI_awaddr(microblaze_riscv_0_axi_periph_M02_AXI_AWADDR),
        .M02_AXI_awready(microblaze_riscv_0_axi_periph_M02_AXI_AWREADY),
        .M02_AXI_awvalid(microblaze_riscv_0_axi_periph_M02_AXI_AWVALID),
        .M02_AXI_bready(microblaze_riscv_0_axi_periph_M02_AXI_BREADY),
        .M02_AXI_bresp(microblaze_riscv_0_axi_periph_M02_AXI_BRESP),
        .M02_AXI_bvalid(microblaze_riscv_0_axi_periph_M02_AXI_BVALID),
        .M02_AXI_rdata(microblaze_riscv_0_axi_periph_M02_AXI_RDATA),
        .M02_AXI_rready(microblaze_riscv_0_axi_periph_M02_AXI_RREADY),
        .M02_AXI_rresp(microblaze_riscv_0_axi_periph_M02_AXI_RRESP),
        .M02_AXI_rvalid(microblaze_riscv_0_axi_periph_M02_AXI_RVALID),
        .M02_AXI_wdata(microblaze_riscv_0_axi_periph_M02_AXI_WDATA),
        .M02_AXI_wready(microblaze_riscv_0_axi_periph_M02_AXI_WREADY),
        .M02_AXI_wstrb(microblaze_riscv_0_axi_periph_M02_AXI_WSTRB),
        .M02_AXI_wvalid(microblaze_riscv_0_axi_periph_M02_AXI_WVALID),
        .S00_AXI_araddr(microblaze_riscv_0_axi_dp_ARADDR),
        .S00_AXI_arprot(microblaze_riscv_0_axi_dp_ARPROT),
        .S00_AXI_arready(microblaze_riscv_0_axi_dp_ARREADY),
        .S00_AXI_arvalid(microblaze_riscv_0_axi_dp_ARVALID),
        .S00_AXI_awaddr(microblaze_riscv_0_axi_dp_AWADDR),
        .S00_AXI_awprot(microblaze_riscv_0_axi_dp_AWPROT),
        .S00_AXI_awready(microblaze_riscv_0_axi_dp_AWREADY),
        .S00_AXI_awvalid(microblaze_riscv_0_axi_dp_AWVALID),
        .S00_AXI_bready(microblaze_riscv_0_axi_dp_BREADY),
        .S00_AXI_bresp(microblaze_riscv_0_axi_dp_BRESP),
        .S00_AXI_bvalid(microblaze_riscv_0_axi_dp_BVALID),
        .S00_AXI_rdata(microblaze_riscv_0_axi_dp_RDATA),
        .S00_AXI_rready(microblaze_riscv_0_axi_dp_RREADY),
        .S00_AXI_rresp(microblaze_riscv_0_axi_dp_RRESP),
        .S00_AXI_rvalid(microblaze_riscv_0_axi_dp_RVALID),
        .S00_AXI_wdata(microblaze_riscv_0_axi_dp_WDATA),
        .S00_AXI_wready(microblaze_riscv_0_axi_dp_WREADY),
        .S00_AXI_wstrb(microblaze_riscv_0_axi_dp_WSTRB),
        .S00_AXI_wvalid(microblaze_riscv_0_axi_dp_WVALID),
        .aclk(microblaze_riscv_0_Clk),
        .aresetn(rst_sysclk_wiz_25M_peripheral_aresetn));
  microblaze_riscv_0_local_memory_imp_1MZ5VT7 microblaze_riscv_0_local_memory
       (.DLMB_abus(microblaze_riscv_0_dlmb_1_ABUS),
        .DLMB_addrstrobe(microblaze_riscv_0_dlmb_1_ADDRSTROBE),
        .DLMB_be(microblaze_riscv_0_dlmb_1_BE),
        .DLMB_ce(microblaze_riscv_0_dlmb_1_CE),
        .DLMB_readdbus(microblaze_riscv_0_dlmb_1_READDBUS),
        .DLMB_readstrobe(microblaze_riscv_0_dlmb_1_READSTROBE),
        .DLMB_ready(microblaze_riscv_0_dlmb_1_READY),
        .DLMB_ue(microblaze_riscv_0_dlmb_1_UE),
        .DLMB_wait(microblaze_riscv_0_dlmb_1_WAIT),
        .DLMB_writedbus(microblaze_riscv_0_dlmb_1_WRITEDBUS),
        .DLMB_writestrobe(microblaze_riscv_0_dlmb_1_WRITESTROBE),
        .ILMB_abus(microblaze_riscv_0_ilmb_1_ABUS),
        .ILMB_addrstrobe(microblaze_riscv_0_ilmb_1_ADDRSTROBE),
        .ILMB_ce(microblaze_riscv_0_ilmb_1_CE),
        .ILMB_readdbus(microblaze_riscv_0_ilmb_1_READDBUS),
        .ILMB_readstrobe(microblaze_riscv_0_ilmb_1_READSTROBE),
        .ILMB_ready(microblaze_riscv_0_ilmb_1_READY),
        .ILMB_ue(microblaze_riscv_0_ilmb_1_UE),
        .ILMB_wait(microblaze_riscv_0_ilmb_1_WAIT),
        .LMB_Clk(microblaze_riscv_0_Clk),
        .SYS_Rst(rst_sysclk_wiz_25M_bus_struct_reset));
  assign microblaze_riscv_0_intr = {1'b0, sfp_i2c_iic2intc_irpt};
  bd_net_wrapper_0_0 net_wrapper_0
       (.clear_arp_cache(clear_arp_cache),
        .gateway_ip(gateway_ip),
        .ip_rx_busy(net_wrapper_0_ip_rx_busy),
        .ip_tx_busy(net_wrapper_0_ip_tx_busy),
        .local_ip(local_ip),
        .local_mac(local_mac),
        .logic_clk(xxv_ethernet_0_rx_clk_out_0),
        .logic_rst(logic_rst),
        .m_axi_araddr(net_wrapper_0_m_axi_ARADDR),
        .m_axi_arready(net_wrapper_0_m_axi_ARREADY),
        .m_axi_arvalid(net_wrapper_0_m_axi_ARVALID),
        .m_axi_awaddr(net_wrapper_0_m_axi_AWADDR),
        .m_axi_awready(net_wrapper_0_m_axi_AWREADY),
        .m_axi_awvalid(net_wrapper_0_m_axi_AWVALID),
        .m_axi_bready(net_wrapper_0_m_axi_BREADY),
        .m_axi_bresp(net_wrapper_0_m_axi_BRESP),
        .m_axi_bvalid(net_wrapper_0_m_axi_BVALID),
        .m_axi_rdata(net_wrapper_0_m_axi_RDATA),
        .m_axi_rready(net_wrapper_0_m_axi_RREADY),
        .m_axi_rresp(net_wrapper_0_m_axi_RRESP),
        .m_axi_rvalid(net_wrapper_0_m_axi_RVALID),
        .m_axi_wdata(net_wrapper_0_m_axi_WDATA),
        .m_axi_wready(net_wrapper_0_m_axi_WREADY),
        .m_axi_wstrb(net_wrapper_0_m_axi_WSTRB),
        .m_axi_wvalid(net_wrapper_0_m_axi_WVALID),
        .rx_error_bad_fcs(net_wrapper_0_rx_error_bad_fcs),
        .rx_error_bad_frame(net_wrapper_0_rx_error_bad_frame),
        .subnet_mask(subnet_mask),
        .tx_eth_hdr_ready(net_wrapper_0_tx_eth_hdr_ready),
        .tx_eth_hdr_valid(net_wrapper_0_tx_eth_hdr_valid),
        .tx_test(tx_test),
        .udp_rx_busy(net_wrapper_0_udp_rx_busy),
        .udp_tx_busy(net_wrapper_0_udp_tx_busy),
        .xgmii_rx_clk(xxv_ethernet_0_rx_clk_out_0),
        .xgmii_rx_rst(rx_rst),
        .xgmii_rxc(xxv_ethernet_0_rx_mii_c_0),
        .xgmii_rxd(xxv_ethernet_0_rx_mii_d_0),
        .xgmii_tx_clk(xxv_ethernet_0_tx_mii_clk_1),
        .xgmii_tx_rst(tx_rst),
        .xgmii_txc(net_wrapper_0_xgmii_txc),
        .xgmii_txd(net_wrapper_0_xgmii_txd));
  bd_rst_sysclk_wiz_25M_0 rst_sysclk_wiz_25M
       (.aux_reset_in(1'b1),
        .bus_struct_reset(rst_sysclk_wiz_25M_bus_struct_reset),
        .dcm_locked(1'b1),
        .ext_reset_in(ilconstant_1_dout),
        .mb_debug_sys_rst(mdm_1_debug_sys_rst),
        .mb_reset(rst_sysclk_wiz_25M_mb_reset),
        .peripheral_aresetn(rst_sysclk_wiz_25M_peripheral_aresetn),
        .slowest_sync_clk(microblaze_riscv_0_Clk));
  bd_axi_iic_0_0 sfp_i2c
       (.iic2intc_irpt(sfp_i2c_iic2intc_irpt),
        .s_axi_aclk(microblaze_riscv_0_Clk),
        .s_axi_araddr(microblaze_riscv_0_axi_periph_M02_AXI_ARADDR),
        .s_axi_aresetn(rst_sysclk_wiz_25M_peripheral_aresetn),
        .s_axi_arready(microblaze_riscv_0_axi_periph_M02_AXI_ARREADY),
        .s_axi_arvalid(microblaze_riscv_0_axi_periph_M02_AXI_ARVALID),
        .s_axi_awaddr(microblaze_riscv_0_axi_periph_M02_AXI_AWADDR),
        .s_axi_awready(microblaze_riscv_0_axi_periph_M02_AXI_AWREADY),
        .s_axi_awvalid(microblaze_riscv_0_axi_periph_M02_AXI_AWVALID),
        .s_axi_bready(microblaze_riscv_0_axi_periph_M02_AXI_BREADY),
        .s_axi_bresp(microblaze_riscv_0_axi_periph_M02_AXI_BRESP),
        .s_axi_bvalid(microblaze_riscv_0_axi_periph_M02_AXI_BVALID),
        .s_axi_rdata(microblaze_riscv_0_axi_periph_M02_AXI_RDATA),
        .s_axi_rready(microblaze_riscv_0_axi_periph_M02_AXI_RREADY),
        .s_axi_rresp(microblaze_riscv_0_axi_periph_M02_AXI_RRESP),
        .s_axi_rvalid(microblaze_riscv_0_axi_periph_M02_AXI_RVALID),
        .s_axi_wdata(microblaze_riscv_0_axi_periph_M02_AXI_WDATA),
        .s_axi_wready(microblaze_riscv_0_axi_periph_M02_AXI_WREADY),
        .s_axi_wstrb(microblaze_riscv_0_axi_periph_M02_AXI_WSTRB),
        .s_axi_wvalid(microblaze_riscv_0_axi_periph_M02_AXI_WVALID),
        .scl_i(sfp_i2c_scl_i),
        .scl_o(sfp_i2c_scl_o),
        .scl_t(sfp_i2c_scl_t),
        .sda_i(sfp_i2c_sda_i),
        .sda_o(sfp_i2c_sda_o),
        .sda_t(sfp_i2c_sda_t));
  bd_clk_wiz_0_0 sysclk_wiz
       (.clk_in1_n(osc_200mhz_clk_n),
        .clk_in1_p(osc_200mhz_clk_p),
        .mhz25(microblaze_riscv_0_Clk));
  bd_util_ds_buf_0_0 util_ds_buf_0
       (.IBUF_DS_N(jesd_refclk_clk_n),
        .IBUF_DS_P(jesd_refclk_clk_p),
        .IBUF_OUT(util_ds_buf_0_IBUF_OUT));
  bd_vio_0_2 vio_eth
       (.clk(microblaze_riscv_0_Clk),
        .probe_in0(xxv_ethernet_0_stat_tx_local_fault_0),
        .probe_in1(xxv_ethernet_0_stat_rx_bad_code_0),
        .probe_in10(xxv_ethernet_0_gtpowergood_out_0),
        .probe_in11(xxv_ethernet_0_stat_rx_hi_ber_0),
        .probe_in12(xxv_ethernet_0_stat_rx_local_fault_0),
        .probe_in13(xxv_ethernet_0_stat_rx_valid_ctrl_code_0),
        .probe_in14(1'b0),
        .probe_in15(xxv_ethernet_0_user_rx_reset_0),
        .probe_in16(xxv_ethernet_0_stat_rx_status_0),
        .probe_in17(c_counter_binary_0_Q),
        .probe_in18(c_counter_binary_1_Q),
        .probe_in19(sfp_mod_abs),
        .probe_in2(xxv_ethernet_0_stat_rx_bad_code_valid_0),
        .probe_in20(xxv_ethernet_0_gt_txbufstatus_1),
        .probe_in3(xxv_ethernet_0_stat_rx_block_lock_0),
        .probe_in4(xxv_ethernet_0_stat_rx_error_0),
        .probe_in5(xxv_ethernet_0_stat_rx_error_valid_0),
        .probe_in6(xxv_ethernet_0_stat_rx_fifo_error_0),
        .probe_in7(xxv_ethernet_0_stat_rx_framing_err_0),
        .probe_in8(xxv_ethernet_0_stat_rx_framing_err_valid_0),
        .probe_in9(xxv_ethernet_0_user_tx_reset_1),
        .probe_out0(txpolarity),
        .probe_out1(reset_tx_datapath0),
        .probe_out10(vio_eth_probe_out10),
        .probe_out11(vio_eth_probe_out11),
        .probe_out12(reset_tx_datapath1),
        .probe_out13(reset_rx_datapath1),
        .probe_out14(txdiffctrl),
        .probe_out15(drprst0),
        .probe_out16(drprst1),
        .probe_out2(reset_rx_datapath0),
        .probe_out3(txpostcursor),
        .probe_out4(sys_reset),
        .probe_out5(rx_reset),
        .probe_out6(tx_reset),
        .probe_out7(qpllreset),
        .probe_out8(txprecursor),
        .probe_out9(txreset0));
  bd_vio_0_1 vio_rx
       (.clk(xxv_ethernet_0_rx_clk_out_0),
        .probe_in0({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .probe_in1({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .probe_in10({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .probe_in11({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .probe_in12({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .probe_in13({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .probe_in14({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .probe_in15({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .probe_in16({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .probe_in17({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .probe_in18({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .probe_in19({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .probe_in2({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .probe_in20(net_wrapper_0_rx_error_bad_frame),
        .probe_in21(net_wrapper_0_rx_error_bad_fcs),
        .probe_in22(net_wrapper_0_ip_rx_busy),
        .probe_in23(net_wrapper_0_ip_tx_busy),
        .probe_in24(net_wrapper_0_udp_rx_busy),
        .probe_in25(net_wrapper_0_udp_tx_busy),
        .probe_in3({1'b0,1'b0,1'b0,1'b0}),
        .probe_in4({1'b0,1'b0,1'b0,1'b0}),
        .probe_in5({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .probe_in6({1'b0,1'b0}),
        .probe_in7({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .probe_in8({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .probe_in9({1'b0,1'b0,1'b0}),
        .probe_out0(rx_rst),
        .probe_out1(logic_rst),
        .probe_out2(local_mac),
        .probe_out3(local_ip),
        .probe_out4(gateway_ip),
        .probe_out5(subnet_mask),
        .probe_out6(clear_arp_cache),
        .probe_out7(tx_test));
  bd_vio_0_0 vio_tx
       (.clk(xxv_ethernet_0_tx_mii_clk_1),
        .probe_in0(net_wrapper_0_tx_eth_hdr_valid),
        .probe_in1(net_wrapper_0_tx_eth_hdr_ready),
        .probe_out0(tx_rst));
  bd_xxv_ethernet_0_0 xxv_ethernet_0
       (.ctl_rx_data_pattern_select_0(1'b0),
        .ctl_rx_data_pattern_select_1(1'b0),
        .ctl_rx_prbs31_test_pattern_enable_0(1'b0),
        .ctl_rx_prbs31_test_pattern_enable_1(1'b0),
        .ctl_rx_test_pattern_0(1'b0),
        .ctl_rx_test_pattern_1(1'b0),
        .ctl_rx_test_pattern_enable_0(1'b0),
        .ctl_rx_test_pattern_enable_1(1'b0),
        .ctl_rx_wdt_disable_0(1'b0),
        .ctl_rx_wdt_disable_1(1'b0),
        .ctl_tx_data_pattern_select_0(1'b0),
        .ctl_tx_data_pattern_select_1(1'b0),
        .ctl_tx_prbs31_test_pattern_enable_0(1'b0),
        .ctl_tx_prbs31_test_pattern_enable_1(1'b0),
        .ctl_tx_test_pattern_0(1'b0),
        .ctl_tx_test_pattern_1(1'b0),
        .ctl_tx_test_pattern_enable_0(1'b0),
        .ctl_tx_test_pattern_enable_1(1'b0),
        .ctl_tx_test_pattern_seed_a_0({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .ctl_tx_test_pattern_seed_a_1({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .ctl_tx_test_pattern_seed_b_0({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .ctl_tx_test_pattern_seed_b_1({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .ctl_tx_test_pattern_select_0(1'b0),
        .ctl_tx_test_pattern_select_1(1'b0),
        .dclk(microblaze_riscv_0_Clk),
        .gt_drpaddr_0({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .gt_drpaddr_1({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .gt_drpclk_0(microblaze_riscv_0_Clk),
        .gt_drpclk_1(microblaze_riscv_0_Clk),
        .gt_drpdi_0({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .gt_drpdi_1({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .gt_drpen_0(1'b0),
        .gt_drpen_1(1'b0),
        .gt_drprst_0(drprst0),
        .gt_drprst_1(drprst1),
        .gt_drpwe_0(1'b0),
        .gt_drpwe_1(1'b0),
        .gt_eyescanreset_0(1'b0),
        .gt_eyescanreset_1(1'b0),
        .gt_eyescantrigger_0(1'b0),
        .gt_eyescantrigger_1(1'b0),
        .gt_loopback_in_0(vio_eth_probe_out10),
        .gt_loopback_in_1({1'b0,1'b0,1'b0}),
        .gt_pcsrsvdin_0({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .gt_pcsrsvdin_1({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .gt_refclk_n(eth_refclk_clk_n),
        .gt_refclk_p(eth_refclk_clk_p),
        .gt_rxbufreset_0(1'b0),
        .gt_rxbufreset_1(1'b0),
        .gt_rxcdrhold_0(1'b0),
        .gt_rxcdrhold_1(1'b0),
        .gt_rxcommadeten_0(1'b0),
        .gt_rxcommadeten_1(1'b0),
        .gt_rxdfeagchold_0(1'b0),
        .gt_rxdfeagchold_1(1'b0),
        .gt_rxdfelpmreset_0(1'b0),
        .gt_rxdfelpmreset_1(1'b0),
        .gt_rxlatclk_0(1'b0),
        .gt_rxlatclk_1(1'b0),
        .gt_rxlpmen_0(1'b0),
        .gt_rxlpmen_1(1'b0),
        .gt_rxn_in_0(sfp_rx_gt_port_0_n),
        .gt_rxn_in_1(sfp_rx_gt_port_1_n),
        .gt_rxp_in_0(sfp_rx_gt_port_0_p),
        .gt_rxp_in_1(sfp_rx_gt_port_1_p),
        .gt_rxpcsreset_0(1'b0),
        .gt_rxpcsreset_1(1'b0),
        .gt_rxpmareset_0(1'b0),
        .gt_rxpmareset_1(1'b0),
        .gt_rxpolarity_0(1'b0),
        .gt_rxpolarity_1(1'b0),
        .gt_rxprbscntreset_0(1'b0),
        .gt_rxprbscntreset_1(1'b0),
        .gt_rxprbssel_0({1'b0,1'b0,1'b0,1'b0}),
        .gt_rxprbssel_1({1'b0,1'b0,1'b0,1'b0}),
        .gt_rxrate_0({1'b0,1'b0,1'b0}),
        .gt_rxrate_1({1'b0,1'b0,1'b0}),
        .gt_rxslide_in_0(1'b0),
        .gt_rxslide_in_1(1'b0),
        .gt_txbufstatus_1(xxv_ethernet_0_gt_txbufstatus_1),
        .gt_txdiffctrl_0({1'b0,1'b0,1'b0,1'b0,1'b0}),
        .gt_txdiffctrl_1(txdiffctrl),
        .gt_txelecidle_0(1'b0),
        .gt_txelecidle_1(1'b0),
        .gt_txinhibit_0(1'b0),
        .gt_txinhibit_1(1'b0),
        .gt_txlatclk_0(1'b0),
        .gt_txlatclk_1(1'b0),
        .gt_txmaincursor_0({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .gt_txmaincursor_1({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .gt_txn_out_0(sfp_tx_gt_port_0_n),
        .gt_txn_out_1(sfp_tx_gt_port_1_n),
        .gt_txp_out_0(sfp_tx_gt_port_0_p),
        .gt_txp_out_1(sfp_tx_gt_port_1_p),
        .gt_txpcsreset_0(1'b0),
        .gt_txpcsreset_1(1'b0),
        .gt_txpmareset_0(1'b0),
        .gt_txpmareset_1(1'b0),
        .gt_txpolarity_0(1'b0),
        .gt_txpolarity_1(txpolarity),
        .gt_txpostcursor_0({1'b0,1'b0,1'b0,1'b0,1'b0}),
        .gt_txpostcursor_1(txpostcursor),
        .gt_txprbsforceerr_0(1'b0),
        .gt_txprbsforceerr_1(1'b0),
        .gt_txprbssel_0({1'b0,1'b0,1'b0,1'b0}),
        .gt_txprbssel_1({1'b0,1'b0,1'b0,1'b0}),
        .gt_txprecursor_0({1'b0,1'b0,1'b0,1'b0,1'b0}),
        .gt_txprecursor_1(txprecursor),
        .gtpowergood_out_0(xxv_ethernet_0_gtpowergood_out_0),
        .gtwiz_reset_rx_datapath_0(reset_rx_datapath0),
        .gtwiz_reset_rx_datapath_1(reset_rx_datapath1),
        .gtwiz_reset_tx_datapath_0(reset_tx_datapath0),
        .gtwiz_reset_tx_datapath_1(reset_tx_datapath1),
        .qpllreset_in_0(qpllreset),
        .rx_clk_out_0(xxv_ethernet_0_rx_clk_out_0),
        .rx_clk_out_1(xxv_ethernet_0_rx_clk_out_1),
        .rx_core_clk_0(xxv_ethernet_0_rx_clk_out_0),
        .rx_core_clk_1(xxv_ethernet_0_rx_clk_out_1),
        .rx_mii_c_0(xxv_ethernet_0_rx_mii_c_0),
        .rx_mii_d_0(xxv_ethernet_0_rx_mii_d_0),
        .rx_reset_0(rx_reset),
        .rx_reset_1(vio_eth_probe_out11),
        .rxoutclksel_in_0({1'b1,1'b0,1'b1}),
        .rxoutclksel_in_1({1'b1,1'b0,1'b1}),
        .stat_rx_bad_code_0(xxv_ethernet_0_stat_rx_bad_code_0),
        .stat_rx_bad_code_valid_0(xxv_ethernet_0_stat_rx_bad_code_valid_0),
        .stat_rx_block_lock_0(xxv_ethernet_0_stat_rx_block_lock_0),
        .stat_rx_error_0(xxv_ethernet_0_stat_rx_error_0),
        .stat_rx_error_valid_0(xxv_ethernet_0_stat_rx_error_valid_0),
        .stat_rx_fifo_error_0(xxv_ethernet_0_stat_rx_fifo_error_0),
        .stat_rx_framing_err_0(xxv_ethernet_0_stat_rx_framing_err_0),
        .stat_rx_framing_err_valid_0(xxv_ethernet_0_stat_rx_framing_err_valid_0),
        .stat_rx_hi_ber_0(xxv_ethernet_0_stat_rx_hi_ber_0),
        .stat_rx_local_fault_0(xxv_ethernet_0_stat_rx_local_fault_0),
        .stat_rx_status_0(xxv_ethernet_0_stat_rx_status_0),
        .stat_rx_valid_ctrl_code_0(xxv_ethernet_0_stat_rx_valid_ctrl_code_0),
        .stat_tx_local_fault_0(xxv_ethernet_0_stat_tx_local_fault_0),
        .sys_reset(sys_reset),
        .tx_mii_c_0({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .tx_mii_c_1(net_wrapper_0_xgmii_txc),
        .tx_mii_clk_1(xxv_ethernet_0_tx_mii_clk_1),
        .tx_mii_d_0({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .tx_mii_d_1(net_wrapper_0_xgmii_txd),
        .tx_reset_0(txreset0),
        .tx_reset_1(tx_reset),
        .txoutclksel_in_0({1'b1,1'b0,1'b1}),
        .txoutclksel_in_1({1'b1,1'b0,1'b1}),
        .user_rx_reset_0(xxv_ethernet_0_user_rx_reset_0),
        .user_tx_reset_1(xxv_ethernet_0_user_tx_reset_1));
endmodule

module microblaze_riscv_0_local_memory_imp_1MZ5VT7
   (DLMB_abus,
    DLMB_addrstrobe,
    DLMB_be,
    DLMB_ce,
    DLMB_readdbus,
    DLMB_readstrobe,
    DLMB_ready,
    DLMB_ue,
    DLMB_wait,
    DLMB_writedbus,
    DLMB_writestrobe,
    ILMB_abus,
    ILMB_addrstrobe,
    ILMB_ce,
    ILMB_readdbus,
    ILMB_readstrobe,
    ILMB_ready,
    ILMB_ue,
    ILMB_wait,
    LMB_Clk,
    SYS_Rst);
  input [0:31]DLMB_abus;
  input DLMB_addrstrobe;
  input [0:3]DLMB_be;
  output DLMB_ce;
  output [0:31]DLMB_readdbus;
  input DLMB_readstrobe;
  output DLMB_ready;
  output DLMB_ue;
  output DLMB_wait;
  input [0:31]DLMB_writedbus;
  input DLMB_writestrobe;
  input [0:31]ILMB_abus;
  input ILMB_addrstrobe;
  output ILMB_ce;
  output [0:31]ILMB_readdbus;
  input ILMB_readstrobe;
  output ILMB_ready;
  output ILMB_ue;
  output ILMB_wait;
  input LMB_Clk;
  input SYS_Rst;

  wire [0:31]DLMB_abus;
  wire DLMB_addrstrobe;
  wire [0:3]DLMB_be;
  wire DLMB_ce;
  wire [0:31]DLMB_readdbus;
  wire DLMB_readstrobe;
  wire DLMB_ready;
  wire DLMB_ue;
  wire DLMB_wait;
  wire [0:31]DLMB_writedbus;
  wire DLMB_writestrobe;
  wire [0:31]ILMB_abus;
  wire ILMB_addrstrobe;
  wire ILMB_ce;
  wire [0:31]ILMB_readdbus;
  wire ILMB_readstrobe;
  wire ILMB_ready;
  wire ILMB_ue;
  wire ILMB_wait;
  wire LMB_Clk;
  wire SYS_Rst;
  wire [0:31]microblaze_riscv_0_dlmb_bus_ABUS;
  wire microblaze_riscv_0_dlmb_bus_ADDRSTROBE;
  wire [0:3]microblaze_riscv_0_dlmb_bus_BE;
  wire microblaze_riscv_0_dlmb_bus_CE;
  wire [0:31]microblaze_riscv_0_dlmb_bus_READDBUS;
  wire microblaze_riscv_0_dlmb_bus_READSTROBE;
  wire microblaze_riscv_0_dlmb_bus_READY;
  wire microblaze_riscv_0_dlmb_bus_UE;
  wire microblaze_riscv_0_dlmb_bus_WAIT;
  wire [0:31]microblaze_riscv_0_dlmb_bus_WRITEDBUS;
  wire microblaze_riscv_0_dlmb_bus_WRITESTROBE;
  wire [0:31]microblaze_riscv_0_dlmb_cntlr_ADDR;
  wire microblaze_riscv_0_dlmb_cntlr_CLK;
  wire [0:31]microblaze_riscv_0_dlmb_cntlr_DIN;
  wire [31:0]microblaze_riscv_0_dlmb_cntlr_DOUT;
  wire microblaze_riscv_0_dlmb_cntlr_EN;
  wire microblaze_riscv_0_dlmb_cntlr_RST;
  wire [0:3]microblaze_riscv_0_dlmb_cntlr_WE;
  wire [0:31]microblaze_riscv_0_ilmb_bus_ABUS;
  wire microblaze_riscv_0_ilmb_bus_ADDRSTROBE;
  wire [0:3]microblaze_riscv_0_ilmb_bus_BE;
  wire microblaze_riscv_0_ilmb_bus_CE;
  wire [0:31]microblaze_riscv_0_ilmb_bus_READDBUS;
  wire microblaze_riscv_0_ilmb_bus_READSTROBE;
  wire microblaze_riscv_0_ilmb_bus_READY;
  wire microblaze_riscv_0_ilmb_bus_UE;
  wire microblaze_riscv_0_ilmb_bus_WAIT;
  wire [0:31]microblaze_riscv_0_ilmb_bus_WRITEDBUS;
  wire microblaze_riscv_0_ilmb_bus_WRITESTROBE;
  wire [0:31]microblaze_riscv_0_ilmb_cntlr_ADDR;
  wire microblaze_riscv_0_ilmb_cntlr_CLK;
  wire [0:31]microblaze_riscv_0_ilmb_cntlr_DIN;
  wire [31:0]microblaze_riscv_0_ilmb_cntlr_DOUT;
  wire microblaze_riscv_0_ilmb_cntlr_EN;
  wire microblaze_riscv_0_ilmb_cntlr_RST;
  wire [0:3]microblaze_riscv_0_ilmb_cntlr_WE;

  (* BMM_INFO_ADDRESS_SPACE = "byte  0x00000000 32 > bd microblaze_riscv_0_local_memory/lmb_bram" *) 
  (* KEEP_HIERARCHY = "YES" *) 
  bd_dlmb_bram_if_cntlr_0 dlmb_bram_if_cntlr
       (.BRAM_Addr_A(microblaze_riscv_0_dlmb_cntlr_ADDR),
        .BRAM_Clk_A(microblaze_riscv_0_dlmb_cntlr_CLK),
        .BRAM_Din_A({microblaze_riscv_0_dlmb_cntlr_DOUT[31],microblaze_riscv_0_dlmb_cntlr_DOUT[30],microblaze_riscv_0_dlmb_cntlr_DOUT[29],microblaze_riscv_0_dlmb_cntlr_DOUT[28],microblaze_riscv_0_dlmb_cntlr_DOUT[27],microblaze_riscv_0_dlmb_cntlr_DOUT[26],microblaze_riscv_0_dlmb_cntlr_DOUT[25],microblaze_riscv_0_dlmb_cntlr_DOUT[24],microblaze_riscv_0_dlmb_cntlr_DOUT[23],microblaze_riscv_0_dlmb_cntlr_DOUT[22],microblaze_riscv_0_dlmb_cntlr_DOUT[21],microblaze_riscv_0_dlmb_cntlr_DOUT[20],microblaze_riscv_0_dlmb_cntlr_DOUT[19],microblaze_riscv_0_dlmb_cntlr_DOUT[18],microblaze_riscv_0_dlmb_cntlr_DOUT[17],microblaze_riscv_0_dlmb_cntlr_DOUT[16],microblaze_riscv_0_dlmb_cntlr_DOUT[15],microblaze_riscv_0_dlmb_cntlr_DOUT[14],microblaze_riscv_0_dlmb_cntlr_DOUT[13],microblaze_riscv_0_dlmb_cntlr_DOUT[12],microblaze_riscv_0_dlmb_cntlr_DOUT[11],microblaze_riscv_0_dlmb_cntlr_DOUT[10],microblaze_riscv_0_dlmb_cntlr_DOUT[9],microblaze_riscv_0_dlmb_cntlr_DOUT[8],microblaze_riscv_0_dlmb_cntlr_DOUT[7],microblaze_riscv_0_dlmb_cntlr_DOUT[6],microblaze_riscv_0_dlmb_cntlr_DOUT[5],microblaze_riscv_0_dlmb_cntlr_DOUT[4],microblaze_riscv_0_dlmb_cntlr_DOUT[3],microblaze_riscv_0_dlmb_cntlr_DOUT[2],microblaze_riscv_0_dlmb_cntlr_DOUT[1],microblaze_riscv_0_dlmb_cntlr_DOUT[0]}),
        .BRAM_Dout_A(microblaze_riscv_0_dlmb_cntlr_DIN),
        .BRAM_EN_A(microblaze_riscv_0_dlmb_cntlr_EN),
        .BRAM_Rst_A(microblaze_riscv_0_dlmb_cntlr_RST),
        .BRAM_WEN_A(microblaze_riscv_0_dlmb_cntlr_WE),
        .LMB_ABus(microblaze_riscv_0_dlmb_bus_ABUS),
        .LMB_AddrStrobe(microblaze_riscv_0_dlmb_bus_ADDRSTROBE),
        .LMB_BE(microblaze_riscv_0_dlmb_bus_BE),
        .LMB_Clk(LMB_Clk),
        .LMB_ReadStrobe(microblaze_riscv_0_dlmb_bus_READSTROBE),
        .LMB_Rst(SYS_Rst),
        .LMB_WriteDBus(microblaze_riscv_0_dlmb_bus_WRITEDBUS),
        .LMB_WriteStrobe(microblaze_riscv_0_dlmb_bus_WRITESTROBE),
        .Sl_CE(microblaze_riscv_0_dlmb_bus_CE),
        .Sl_DBus(microblaze_riscv_0_dlmb_bus_READDBUS),
        .Sl_Ready(microblaze_riscv_0_dlmb_bus_READY),
        .Sl_UE(microblaze_riscv_0_dlmb_bus_UE),
        .Sl_Wait(microblaze_riscv_0_dlmb_bus_WAIT));
  bd_dlmb_v10_0 dlmb_v10
       (.LMB_ABus(microblaze_riscv_0_dlmb_bus_ABUS),
        .LMB_AddrStrobe(microblaze_riscv_0_dlmb_bus_ADDRSTROBE),
        .LMB_BE(microblaze_riscv_0_dlmb_bus_BE),
        .LMB_CE(DLMB_ce),
        .LMB_Clk(LMB_Clk),
        .LMB_ReadDBus(DLMB_readdbus),
        .LMB_ReadStrobe(microblaze_riscv_0_dlmb_bus_READSTROBE),
        .LMB_Ready(DLMB_ready),
        .LMB_UE(DLMB_ue),
        .LMB_Wait(DLMB_wait),
        .LMB_WriteDBus(microblaze_riscv_0_dlmb_bus_WRITEDBUS),
        .LMB_WriteStrobe(microblaze_riscv_0_dlmb_bus_WRITESTROBE),
        .M_ABus(DLMB_abus),
        .M_AddrStrobe(DLMB_addrstrobe),
        .M_BE(DLMB_be),
        .M_DBus(DLMB_writedbus),
        .M_ReadStrobe(DLMB_readstrobe),
        .M_WriteStrobe(DLMB_writestrobe),
        .SYS_Rst(SYS_Rst),
        .Sl_CE(microblaze_riscv_0_dlmb_bus_CE),
        .Sl_DBus(microblaze_riscv_0_dlmb_bus_READDBUS),
        .Sl_Ready(microblaze_riscv_0_dlmb_bus_READY),
        .Sl_UE(microblaze_riscv_0_dlmb_bus_UE),
        .Sl_Wait(microblaze_riscv_0_dlmb_bus_WAIT));
  bd_ilmb_bram_if_cntlr_0 ilmb_bram_if_cntlr
       (.BRAM_Addr_A(microblaze_riscv_0_ilmb_cntlr_ADDR),
        .BRAM_Clk_A(microblaze_riscv_0_ilmb_cntlr_CLK),
        .BRAM_Din_A({microblaze_riscv_0_ilmb_cntlr_DOUT[31],microblaze_riscv_0_ilmb_cntlr_DOUT[30],microblaze_riscv_0_ilmb_cntlr_DOUT[29],microblaze_riscv_0_ilmb_cntlr_DOUT[28],microblaze_riscv_0_ilmb_cntlr_DOUT[27],microblaze_riscv_0_ilmb_cntlr_DOUT[26],microblaze_riscv_0_ilmb_cntlr_DOUT[25],microblaze_riscv_0_ilmb_cntlr_DOUT[24],microblaze_riscv_0_ilmb_cntlr_DOUT[23],microblaze_riscv_0_ilmb_cntlr_DOUT[22],microblaze_riscv_0_ilmb_cntlr_DOUT[21],microblaze_riscv_0_ilmb_cntlr_DOUT[20],microblaze_riscv_0_ilmb_cntlr_DOUT[19],microblaze_riscv_0_ilmb_cntlr_DOUT[18],microblaze_riscv_0_ilmb_cntlr_DOUT[17],microblaze_riscv_0_ilmb_cntlr_DOUT[16],microblaze_riscv_0_ilmb_cntlr_DOUT[15],microblaze_riscv_0_ilmb_cntlr_DOUT[14],microblaze_riscv_0_ilmb_cntlr_DOUT[13],microblaze_riscv_0_ilmb_cntlr_DOUT[12],microblaze_riscv_0_ilmb_cntlr_DOUT[11],microblaze_riscv_0_ilmb_cntlr_DOUT[10],microblaze_riscv_0_ilmb_cntlr_DOUT[9],microblaze_riscv_0_ilmb_cntlr_DOUT[8],microblaze_riscv_0_ilmb_cntlr_DOUT[7],microblaze_riscv_0_ilmb_cntlr_DOUT[6],microblaze_riscv_0_ilmb_cntlr_DOUT[5],microblaze_riscv_0_ilmb_cntlr_DOUT[4],microblaze_riscv_0_ilmb_cntlr_DOUT[3],microblaze_riscv_0_ilmb_cntlr_DOUT[2],microblaze_riscv_0_ilmb_cntlr_DOUT[1],microblaze_riscv_0_ilmb_cntlr_DOUT[0]}),
        .BRAM_Dout_A(microblaze_riscv_0_ilmb_cntlr_DIN),
        .BRAM_EN_A(microblaze_riscv_0_ilmb_cntlr_EN),
        .BRAM_Rst_A(microblaze_riscv_0_ilmb_cntlr_RST),
        .BRAM_WEN_A(microblaze_riscv_0_ilmb_cntlr_WE),
        .LMB_ABus(microblaze_riscv_0_ilmb_bus_ABUS),
        .LMB_AddrStrobe(microblaze_riscv_0_ilmb_bus_ADDRSTROBE),
        .LMB_BE(microblaze_riscv_0_ilmb_bus_BE),
        .LMB_Clk(LMB_Clk),
        .LMB_ReadStrobe(microblaze_riscv_0_ilmb_bus_READSTROBE),
        .LMB_Rst(SYS_Rst),
        .LMB_WriteDBus(microblaze_riscv_0_ilmb_bus_WRITEDBUS),
        .LMB_WriteStrobe(microblaze_riscv_0_ilmb_bus_WRITESTROBE),
        .Sl_CE(microblaze_riscv_0_ilmb_bus_CE),
        .Sl_DBus(microblaze_riscv_0_ilmb_bus_READDBUS),
        .Sl_Ready(microblaze_riscv_0_ilmb_bus_READY),
        .Sl_UE(microblaze_riscv_0_ilmb_bus_UE),
        .Sl_Wait(microblaze_riscv_0_ilmb_bus_WAIT));
  bd_ilmb_v10_0 ilmb_v10
       (.LMB_ABus(microblaze_riscv_0_ilmb_bus_ABUS),
        .LMB_AddrStrobe(microblaze_riscv_0_ilmb_bus_ADDRSTROBE),
        .LMB_BE(microblaze_riscv_0_ilmb_bus_BE),
        .LMB_CE(ILMB_ce),
        .LMB_Clk(LMB_Clk),
        .LMB_ReadDBus(ILMB_readdbus),
        .LMB_ReadStrobe(microblaze_riscv_0_ilmb_bus_READSTROBE),
        .LMB_Ready(ILMB_ready),
        .LMB_UE(ILMB_ue),
        .LMB_Wait(ILMB_wait),
        .LMB_WriteDBus(microblaze_riscv_0_ilmb_bus_WRITEDBUS),
        .LMB_WriteStrobe(microblaze_riscv_0_ilmb_bus_WRITESTROBE),
        .M_ABus(ILMB_abus),
        .M_AddrStrobe(ILMB_addrstrobe),
        .M_BE({1'b0,1'b0,1'b0,1'b0}),
        .M_DBus({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .M_ReadStrobe(ILMB_readstrobe),
        .M_WriteStrobe(1'b0),
        .SYS_Rst(SYS_Rst),
        .Sl_CE(microblaze_riscv_0_ilmb_bus_CE),
        .Sl_DBus(microblaze_riscv_0_ilmb_bus_READDBUS),
        .Sl_Ready(microblaze_riscv_0_ilmb_bus_READY),
        .Sl_UE(microblaze_riscv_0_ilmb_bus_UE),
        .Sl_Wait(microblaze_riscv_0_ilmb_bus_WAIT));
  bd_lmb_bram_0 lmb_bram
       (.addra({microblaze_riscv_0_dlmb_cntlr_ADDR[0],microblaze_riscv_0_dlmb_cntlr_ADDR[1],microblaze_riscv_0_dlmb_cntlr_ADDR[2],microblaze_riscv_0_dlmb_cntlr_ADDR[3],microblaze_riscv_0_dlmb_cntlr_ADDR[4],microblaze_riscv_0_dlmb_cntlr_ADDR[5],microblaze_riscv_0_dlmb_cntlr_ADDR[6],microblaze_riscv_0_dlmb_cntlr_ADDR[7],microblaze_riscv_0_dlmb_cntlr_ADDR[8],microblaze_riscv_0_dlmb_cntlr_ADDR[9],microblaze_riscv_0_dlmb_cntlr_ADDR[10],microblaze_riscv_0_dlmb_cntlr_ADDR[11],microblaze_riscv_0_dlmb_cntlr_ADDR[12],microblaze_riscv_0_dlmb_cntlr_ADDR[13],microblaze_riscv_0_dlmb_cntlr_ADDR[14],microblaze_riscv_0_dlmb_cntlr_ADDR[15],microblaze_riscv_0_dlmb_cntlr_ADDR[16],microblaze_riscv_0_dlmb_cntlr_ADDR[17],microblaze_riscv_0_dlmb_cntlr_ADDR[18],microblaze_riscv_0_dlmb_cntlr_ADDR[19],microblaze_riscv_0_dlmb_cntlr_ADDR[20],microblaze_riscv_0_dlmb_cntlr_ADDR[21],microblaze_riscv_0_dlmb_cntlr_ADDR[22],microblaze_riscv_0_dlmb_cntlr_ADDR[23],microblaze_riscv_0_dlmb_cntlr_ADDR[24],microblaze_riscv_0_dlmb_cntlr_ADDR[25],microblaze_riscv_0_dlmb_cntlr_ADDR[26],microblaze_riscv_0_dlmb_cntlr_ADDR[27],microblaze_riscv_0_dlmb_cntlr_ADDR[28],microblaze_riscv_0_dlmb_cntlr_ADDR[29],microblaze_riscv_0_dlmb_cntlr_ADDR[30],microblaze_riscv_0_dlmb_cntlr_ADDR[31]}),
        .addrb({microblaze_riscv_0_ilmb_cntlr_ADDR[0],microblaze_riscv_0_ilmb_cntlr_ADDR[1],microblaze_riscv_0_ilmb_cntlr_ADDR[2],microblaze_riscv_0_ilmb_cntlr_ADDR[3],microblaze_riscv_0_ilmb_cntlr_ADDR[4],microblaze_riscv_0_ilmb_cntlr_ADDR[5],microblaze_riscv_0_ilmb_cntlr_ADDR[6],microblaze_riscv_0_ilmb_cntlr_ADDR[7],microblaze_riscv_0_ilmb_cntlr_ADDR[8],microblaze_riscv_0_ilmb_cntlr_ADDR[9],microblaze_riscv_0_ilmb_cntlr_ADDR[10],microblaze_riscv_0_ilmb_cntlr_ADDR[11],microblaze_riscv_0_ilmb_cntlr_ADDR[12],microblaze_riscv_0_ilmb_cntlr_ADDR[13],microblaze_riscv_0_ilmb_cntlr_ADDR[14],microblaze_riscv_0_ilmb_cntlr_ADDR[15],microblaze_riscv_0_ilmb_cntlr_ADDR[16],microblaze_riscv_0_ilmb_cntlr_ADDR[17],microblaze_riscv_0_ilmb_cntlr_ADDR[18],microblaze_riscv_0_ilmb_cntlr_ADDR[19],microblaze_riscv_0_ilmb_cntlr_ADDR[20],microblaze_riscv_0_ilmb_cntlr_ADDR[21],microblaze_riscv_0_ilmb_cntlr_ADDR[22],microblaze_riscv_0_ilmb_cntlr_ADDR[23],microblaze_riscv_0_ilmb_cntlr_ADDR[24],microblaze_riscv_0_ilmb_cntlr_ADDR[25],microblaze_riscv_0_ilmb_cntlr_ADDR[26],microblaze_riscv_0_ilmb_cntlr_ADDR[27],microblaze_riscv_0_ilmb_cntlr_ADDR[28],microblaze_riscv_0_ilmb_cntlr_ADDR[29],microblaze_riscv_0_ilmb_cntlr_ADDR[30],microblaze_riscv_0_ilmb_cntlr_ADDR[31]}),
        .clka(microblaze_riscv_0_dlmb_cntlr_CLK),
        .clkb(microblaze_riscv_0_ilmb_cntlr_CLK),
        .dina({microblaze_riscv_0_dlmb_cntlr_DIN[0],microblaze_riscv_0_dlmb_cntlr_DIN[1],microblaze_riscv_0_dlmb_cntlr_DIN[2],microblaze_riscv_0_dlmb_cntlr_DIN[3],microblaze_riscv_0_dlmb_cntlr_DIN[4],microblaze_riscv_0_dlmb_cntlr_DIN[5],microblaze_riscv_0_dlmb_cntlr_DIN[6],microblaze_riscv_0_dlmb_cntlr_DIN[7],microblaze_riscv_0_dlmb_cntlr_DIN[8],microblaze_riscv_0_dlmb_cntlr_DIN[9],microblaze_riscv_0_dlmb_cntlr_DIN[10],microblaze_riscv_0_dlmb_cntlr_DIN[11],microblaze_riscv_0_dlmb_cntlr_DIN[12],microblaze_riscv_0_dlmb_cntlr_DIN[13],microblaze_riscv_0_dlmb_cntlr_DIN[14],microblaze_riscv_0_dlmb_cntlr_DIN[15],microblaze_riscv_0_dlmb_cntlr_DIN[16],microblaze_riscv_0_dlmb_cntlr_DIN[17],microblaze_riscv_0_dlmb_cntlr_DIN[18],microblaze_riscv_0_dlmb_cntlr_DIN[19],microblaze_riscv_0_dlmb_cntlr_DIN[20],microblaze_riscv_0_dlmb_cntlr_DIN[21],microblaze_riscv_0_dlmb_cntlr_DIN[22],microblaze_riscv_0_dlmb_cntlr_DIN[23],microblaze_riscv_0_dlmb_cntlr_DIN[24],microblaze_riscv_0_dlmb_cntlr_DIN[25],microblaze_riscv_0_dlmb_cntlr_DIN[26],microblaze_riscv_0_dlmb_cntlr_DIN[27],microblaze_riscv_0_dlmb_cntlr_DIN[28],microblaze_riscv_0_dlmb_cntlr_DIN[29],microblaze_riscv_0_dlmb_cntlr_DIN[30],microblaze_riscv_0_dlmb_cntlr_DIN[31]}),
        .dinb({microblaze_riscv_0_ilmb_cntlr_DIN[0],microblaze_riscv_0_ilmb_cntlr_DIN[1],microblaze_riscv_0_ilmb_cntlr_DIN[2],microblaze_riscv_0_ilmb_cntlr_DIN[3],microblaze_riscv_0_ilmb_cntlr_DIN[4],microblaze_riscv_0_ilmb_cntlr_DIN[5],microblaze_riscv_0_ilmb_cntlr_DIN[6],microblaze_riscv_0_ilmb_cntlr_DIN[7],microblaze_riscv_0_ilmb_cntlr_DIN[8],microblaze_riscv_0_ilmb_cntlr_DIN[9],microblaze_riscv_0_ilmb_cntlr_DIN[10],microblaze_riscv_0_ilmb_cntlr_DIN[11],microblaze_riscv_0_ilmb_cntlr_DIN[12],microblaze_riscv_0_ilmb_cntlr_DIN[13],microblaze_riscv_0_ilmb_cntlr_DIN[14],microblaze_riscv_0_ilmb_cntlr_DIN[15],microblaze_riscv_0_ilmb_cntlr_DIN[16],microblaze_riscv_0_ilmb_cntlr_DIN[17],microblaze_riscv_0_ilmb_cntlr_DIN[18],microblaze_riscv_0_ilmb_cntlr_DIN[19],microblaze_riscv_0_ilmb_cntlr_DIN[20],microblaze_riscv_0_ilmb_cntlr_DIN[21],microblaze_riscv_0_ilmb_cntlr_DIN[22],microblaze_riscv_0_ilmb_cntlr_DIN[23],microblaze_riscv_0_ilmb_cntlr_DIN[24],microblaze_riscv_0_ilmb_cntlr_DIN[25],microblaze_riscv_0_ilmb_cntlr_DIN[26],microblaze_riscv_0_ilmb_cntlr_DIN[27],microblaze_riscv_0_ilmb_cntlr_DIN[28],microblaze_riscv_0_ilmb_cntlr_DIN[29],microblaze_riscv_0_ilmb_cntlr_DIN[30],microblaze_riscv_0_ilmb_cntlr_DIN[31]}),
        .douta(microblaze_riscv_0_dlmb_cntlr_DOUT),
        .doutb(microblaze_riscv_0_ilmb_cntlr_DOUT),
        .ena(microblaze_riscv_0_dlmb_cntlr_EN),
        .enb(microblaze_riscv_0_ilmb_cntlr_EN),
        .rsta(microblaze_riscv_0_dlmb_cntlr_RST),
        .rstb(microblaze_riscv_0_ilmb_cntlr_RST),
        .wea({microblaze_riscv_0_dlmb_cntlr_WE[0],microblaze_riscv_0_dlmb_cntlr_WE[1],microblaze_riscv_0_dlmb_cntlr_WE[2],microblaze_riscv_0_dlmb_cntlr_WE[3]}),
        .web({microblaze_riscv_0_ilmb_cntlr_WE[0],microblaze_riscv_0_ilmb_cntlr_WE[1],microblaze_riscv_0_ilmb_cntlr_WE[2],microblaze_riscv_0_ilmb_cntlr_WE[3]}));
endmodule
