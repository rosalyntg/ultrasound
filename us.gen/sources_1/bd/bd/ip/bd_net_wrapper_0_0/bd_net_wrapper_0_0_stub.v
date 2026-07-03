// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// Copyright 2022-2026 Advanced Micro Devices, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2025.2.1 (lin64) Build 6403652 Thu Mar 19 13:47:00 MDT 2026
// Date        : Fri Jul  3 17:43:11 2026
// Host        : russell-shotover-arch running 64-bit Ubuntu 22.04.5 LTS
// Command     : write_verilog -force -mode synth_stub
//               /home/russell/ultrasound/fpga/us/us.gen/sources_1/bd/bd/ip/bd_net_wrapper_0_0/bd_net_wrapper_0_0_stub.v
// Design      : bd_net_wrapper_0_0
// Purpose     : Stub declaration of top-level module interface
// Device      : xcau15p-ffvb676-2-i
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* CHECK_LICENSE_TYPE = "bd_net_wrapper_0_0,net_wrapper,{}" *) (* CORE_GENERATION_INFO = "bd_net_wrapper_0_0,net_wrapper,{x_ipProduct=Vivado 2025.2.1,x_ipVendor=xilinx.com,x_ipLibrary=module_ref,x_ipName=net_wrapper,x_ipVersion=1.0,x_ipCoreRevision=1,x_ipLanguage=VERILOG,x_ipSimLanguage=MIXED}" *) (* DowngradeIPIdentifiedWarnings = "yes" *) 
(* IP_DEFINITION_SOURCE = "module_ref" *) (* X_CORE_INFO = "net_wrapper,Vivado 2025.2.1" *) 
module bd_net_wrapper_0_0(logic_clk, logic_rst, xgmii_rx_clk, 
  xgmii_rx_rst, xgmii_tx_clk, xgmii_tx_rst, xgmii_rxd, xgmii_rxc, xgmii_txd, xgmii_txc, 
  s_udp_hdr_valid, s_udp_hdr_ready, s_udp_ip_dscp, s_udp_ip_ecn, s_udp_ip_ttl, 
  s_udp_ip_source_ip, s_udp_ip_dest_ip, s_udp_source_port, s_udp_dest_port, s_udp_length, 
  s_udp_checksum, s_udp_payload_axis_tdata, s_udp_payload_axis_tkeep, 
  s_udp_payload_axis_tvalid, s_udp_payload_axis_tready, s_udp_payload_axis_tlast, 
  s_udp_payload_axis_tuser, m_udp_hdr_valid, m_udp_hdr_ready, m_udp_eth_dest_mac, 
  m_udp_eth_src_mac, m_udp_eth_type, m_udp_ip_version, m_udp_ip_ihl, m_udp_ip_dscp, 
  m_udp_ip_ecn, m_udp_ip_length, m_udp_ip_identification, m_udp_ip_flags, 
  m_udp_ip_fragment_offset, m_udp_ip_ttl, m_udp_ip_protocol, m_udp_ip_header_checksum, 
  m_udp_ip_source_ip, m_udp_ip_dest_ip, m_udp_source_port, m_udp_dest_port, m_udp_length, 
  m_udp_checksum, m_udp_payload_axis_tdata, m_udp_payload_axis_tkeep, 
  m_udp_payload_axis_tvalid, m_udp_payload_axis_tready, m_udp_payload_axis_tlast, 
  m_udp_payload_axis_tuser, rx_error_bad_frame, rx_error_bad_fcs, ip_rx_busy, ip_tx_busy, 
  udp_rx_busy, udp_tx_busy, local_mac, local_ip, gateway_ip, subnet_mask, clear_arp_cache)
/* synthesis syn_black_box black_box_pad_pin="logic_rst,xgmii_rx_rst,xgmii_tx_rst,xgmii_rxd[63:0],xgmii_rxc[7:0],xgmii_txd[63:0],xgmii_txc[7:0],s_udp_hdr_valid,s_udp_hdr_ready,s_udp_ip_dscp[5:0],s_udp_ip_ecn[1:0],s_udp_ip_ttl[7:0],s_udp_ip_source_ip[31:0],s_udp_ip_dest_ip[31:0],s_udp_source_port[15:0],s_udp_dest_port[15:0],s_udp_length[15:0],s_udp_checksum[15:0],s_udp_payload_axis_tdata[63:0],s_udp_payload_axis_tkeep[7:0],s_udp_payload_axis_tvalid,s_udp_payload_axis_tready,s_udp_payload_axis_tlast,s_udp_payload_axis_tuser,m_udp_hdr_valid,m_udp_hdr_ready,m_udp_eth_dest_mac[47:0],m_udp_eth_src_mac[47:0],m_udp_eth_type[15:0],m_udp_ip_version[3:0],m_udp_ip_ihl[3:0],m_udp_ip_dscp[5:0],m_udp_ip_ecn[1:0],m_udp_ip_length[15:0],m_udp_ip_identification[15:0],m_udp_ip_flags[2:0],m_udp_ip_fragment_offset[12:0],m_udp_ip_ttl[7:0],m_udp_ip_protocol[7:0],m_udp_ip_header_checksum[15:0],m_udp_ip_source_ip[31:0],m_udp_ip_dest_ip[31:0],m_udp_source_port[15:0],m_udp_dest_port[15:0],m_udp_length[15:0],m_udp_checksum[15:0],m_udp_payload_axis_tdata[63:0],m_udp_payload_axis_tkeep[7:0],m_udp_payload_axis_tvalid,m_udp_payload_axis_tready,m_udp_payload_axis_tlast,m_udp_payload_axis_tuser,rx_error_bad_frame,rx_error_bad_fcs,ip_rx_busy,ip_tx_busy,udp_rx_busy,udp_tx_busy,local_mac[47:0],local_ip[31:0],gateway_ip[31:0],subnet_mask[31:0],clear_arp_cache" */
/* synthesis syn_force_seq_prim="logic_clk" */
/* synthesis syn_force_seq_prim="xgmii_rx_clk" */
/* synthesis syn_force_seq_prim="xgmii_tx_clk" */;
  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 logic_clk CLK" *) (* X_INTERFACE_MODE = "slave" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME logic_clk, ASSOCIATED_RESET logic_rst, FREQ_HZ 156250000, FREQ_TOLERANCE_HZ 0, PHASE 0, CLK_DOMAIN bd_xxv_ethernet_0_0_rx_clk_out_0, INSERT_VIP 0" *) input logic_clk /* synthesis syn_isclock = 1 */;
  (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 logic_rst RST" *) (* X_INTERFACE_MODE = "slave" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME logic_rst, POLARITY ACTIVE_LOW, INSERT_VIP 0" *) input logic_rst;
  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 xgmii_rx_clk CLK" *) (* X_INTERFACE_MODE = "slave" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME xgmii_rx_clk, ASSOCIATED_RESET xgmii_rx_rst, FREQ_HZ 156250000, FREQ_TOLERANCE_HZ 0, PHASE 0, CLK_DOMAIN bd_xxv_ethernet_0_0_rx_clk_out_0, INSERT_VIP 0" *) input xgmii_rx_clk /* synthesis syn_isclock = 1 */;
  (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 xgmii_rx_rst RST" *) (* X_INTERFACE_MODE = "slave" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME xgmii_rx_rst, POLARITY ACTIVE_LOW, INSERT_VIP 0" *) input xgmii_rx_rst;
  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 xgmii_tx_clk CLK" *) (* X_INTERFACE_MODE = "slave" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME xgmii_tx_clk, ASSOCIATED_RESET xgmii_tx_rst, FREQ_HZ 156250000, FREQ_TOLERANCE_HZ 0, PHASE 0, CLK_DOMAIN bd_xxv_ethernet_0_0_tx_mii_clk_0, INSERT_VIP 0" *) input xgmii_tx_clk /* synthesis syn_isclock = 1 */;
  (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 xgmii_tx_rst RST" *) (* X_INTERFACE_MODE = "slave" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME xgmii_tx_rst, POLARITY ACTIVE_LOW, INSERT_VIP 0" *) input xgmii_tx_rst;
  input [63:0]xgmii_rxd;
  input [7:0]xgmii_rxc;
  output [63:0]xgmii_txd;
  output [7:0]xgmii_txc;
  input s_udp_hdr_valid;
  output s_udp_hdr_ready;
  input [5:0]s_udp_ip_dscp;
  input [1:0]s_udp_ip_ecn;
  input [7:0]s_udp_ip_ttl;
  input [31:0]s_udp_ip_source_ip;
  input [31:0]s_udp_ip_dest_ip;
  input [15:0]s_udp_source_port;
  input [15:0]s_udp_dest_port;
  input [15:0]s_udp_length;
  input [15:0]s_udp_checksum;
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_udp_payload_axis TDATA" *) (* X_INTERFACE_MODE = "slave" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME s_udp_payload_axis, TDATA_NUM_BYTES 8, TDEST_WIDTH 0, TID_WIDTH 0, TUSER_WIDTH 1, HAS_TREADY 1, HAS_TSTRB 0, HAS_TKEEP 1, HAS_TLAST 1, FREQ_HZ 100000000, PHASE 0.0, LAYERED_METADATA undef, INSERT_VIP 0" *) input [63:0]s_udp_payload_axis_tdata;
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_udp_payload_axis TKEEP" *) input [7:0]s_udp_payload_axis_tkeep;
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_udp_payload_axis TVALID" *) input s_udp_payload_axis_tvalid;
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_udp_payload_axis TREADY" *) output s_udp_payload_axis_tready;
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_udp_payload_axis TLAST" *) input s_udp_payload_axis_tlast;
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_udp_payload_axis TUSER" *) input s_udp_payload_axis_tuser;
  output m_udp_hdr_valid;
  input m_udp_hdr_ready;
  output [47:0]m_udp_eth_dest_mac;
  output [47:0]m_udp_eth_src_mac;
  output [15:0]m_udp_eth_type;
  output [3:0]m_udp_ip_version;
  output [3:0]m_udp_ip_ihl;
  output [5:0]m_udp_ip_dscp;
  output [1:0]m_udp_ip_ecn;
  output [15:0]m_udp_ip_length;
  output [15:0]m_udp_ip_identification;
  output [2:0]m_udp_ip_flags;
  output [12:0]m_udp_ip_fragment_offset;
  output [7:0]m_udp_ip_ttl;
  output [7:0]m_udp_ip_protocol;
  output [15:0]m_udp_ip_header_checksum;
  output [31:0]m_udp_ip_source_ip;
  output [31:0]m_udp_ip_dest_ip;
  output [15:0]m_udp_source_port;
  output [15:0]m_udp_dest_port;
  output [15:0]m_udp_length;
  output [15:0]m_udp_checksum;
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_udp_payload_axis TDATA" *) (* X_INTERFACE_MODE = "master" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME m_udp_payload_axis, TDATA_NUM_BYTES 8, TDEST_WIDTH 0, TID_WIDTH 0, TUSER_WIDTH 1, HAS_TREADY 1, HAS_TSTRB 0, HAS_TKEEP 1, HAS_TLAST 1, FREQ_HZ 100000000, PHASE 0.0, LAYERED_METADATA undef, INSERT_VIP 0" *) output [63:0]m_udp_payload_axis_tdata;
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_udp_payload_axis TKEEP" *) output [7:0]m_udp_payload_axis_tkeep;
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_udp_payload_axis TVALID" *) output m_udp_payload_axis_tvalid;
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_udp_payload_axis TREADY" *) input m_udp_payload_axis_tready;
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_udp_payload_axis TLAST" *) output m_udp_payload_axis_tlast;
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_udp_payload_axis TUSER" *) output m_udp_payload_axis_tuser;
  output rx_error_bad_frame;
  output rx_error_bad_fcs;
  output ip_rx_busy;
  output ip_tx_busy;
  output udp_rx_busy;
  output udp_tx_busy;
  input [47:0]local_mac;
  input [31:0]local_ip;
  input [31:0]gateway_ip;
  input [31:0]subnet_mask;
  input clear_arp_cache;
endmodule
