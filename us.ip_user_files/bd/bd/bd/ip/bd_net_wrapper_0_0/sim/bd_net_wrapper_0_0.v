// (c) Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// (c) Copyright 2022-2026 Advanced Micro Devices, Inc. All rights reserved.
// 
// This file contains confidential and proprietary information
// of AMD and is protected under U.S. and international copyright
// and other intellectual property laws.
// 
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// AMD, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND AMD HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) AMD shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or AMD had been advised of the
// possibility of the same.
// 
// CRITICAL APPLICATIONS
// AMD products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of AMD products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
// 
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
// 
// DO NOT MODIFY THIS FILE.


// IP VLNV: xilinx.com:module_ref:net_wrapper:1.0
// IP Revision: 1

`timescale 1ns/1ps

(* IP_DEFINITION_SOURCE = "module_ref" *)
(* DowngradeIPIdentifiedWarnings = "yes" *)
module bd_net_wrapper_0_0 (
  logic_clk,
  logic_rst,
  xgmii_rx_clk,
  xgmii_rx_rst,
  xgmii_tx_clk,
  xgmii_tx_rst,
  xgmii_rxd,
  xgmii_rxc,
  xgmii_txd,
  xgmii_txc,
  s_udp_hdr_valid,
  s_udp_hdr_ready,
  s_udp_ip_dscp,
  s_udp_ip_ecn,
  s_udp_ip_ttl,
  s_udp_ip_source_ip,
  s_udp_ip_dest_ip,
  s_udp_source_port,
  s_udp_dest_port,
  s_udp_length,
  s_udp_checksum,
  s_udp_payload_axis_tdata,
  s_udp_payload_axis_tkeep,
  s_udp_payload_axis_tvalid,
  s_udp_payload_axis_tready,
  s_udp_payload_axis_tlast,
  s_udp_payload_axis_tuser,
  m_udp_hdr_valid,
  m_udp_hdr_ready,
  m_udp_eth_dest_mac,
  m_udp_eth_src_mac,
  m_udp_eth_type,
  m_udp_ip_version,
  m_udp_ip_ihl,
  m_udp_ip_dscp,
  m_udp_ip_ecn,
  m_udp_ip_length,
  m_udp_ip_identification,
  m_udp_ip_flags,
  m_udp_ip_fragment_offset,
  m_udp_ip_ttl,
  m_udp_ip_protocol,
  m_udp_ip_header_checksum,
  m_udp_ip_source_ip,
  m_udp_ip_dest_ip,
  m_udp_source_port,
  m_udp_dest_port,
  m_udp_length,
  m_udp_checksum,
  m_udp_payload_axis_tdata,
  m_udp_payload_axis_tkeep,
  m_udp_payload_axis_tvalid,
  m_udp_payload_axis_tready,
  m_udp_payload_axis_tlast,
  m_udp_payload_axis_tuser,
  rx_error_bad_frame,
  rx_error_bad_fcs,
  ip_rx_busy,
  ip_tx_busy,
  udp_rx_busy,
  udp_tx_busy,
  local_mac,
  local_ip,
  gateway_ip,
  subnet_mask,
  clear_arp_cache
);

(* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 logic_clk CLK" *)
(* X_INTERFACE_MODE = "slave" *)
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME logic_clk, ASSOCIATED_RESET logic_rst, FREQ_HZ 156250000, FREQ_TOLERANCE_HZ 0, PHASE 0, CLK_DOMAIN bd_xxv_ethernet_0_0_rx_clk_out_0, INSERT_VIP 0" *)
input wire logic_clk;
(* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 logic_rst RST" *)
(* X_INTERFACE_MODE = "slave" *)
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME logic_rst, POLARITY ACTIVE_LOW, INSERT_VIP 0" *)
input wire logic_rst;
(* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 xgmii_rx_clk CLK" *)
(* X_INTERFACE_MODE = "slave" *)
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME xgmii_rx_clk, ASSOCIATED_RESET xgmii_rx_rst, FREQ_HZ 156250000, FREQ_TOLERANCE_HZ 0, PHASE 0, CLK_DOMAIN bd_xxv_ethernet_0_0_rx_clk_out_0, INSERT_VIP 0" *)
input wire xgmii_rx_clk;
(* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 xgmii_rx_rst RST" *)
(* X_INTERFACE_MODE = "slave" *)
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME xgmii_rx_rst, POLARITY ACTIVE_LOW, INSERT_VIP 0" *)
input wire xgmii_rx_rst;
(* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 xgmii_tx_clk CLK" *)
(* X_INTERFACE_MODE = "slave" *)
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME xgmii_tx_clk, ASSOCIATED_RESET xgmii_tx_rst, FREQ_HZ 156250000, FREQ_TOLERANCE_HZ 0, PHASE 0, CLK_DOMAIN bd_xxv_ethernet_0_0_tx_mii_clk_0, INSERT_VIP 0" *)
input wire xgmii_tx_clk;
(* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 xgmii_tx_rst RST" *)
(* X_INTERFACE_MODE = "slave" *)
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME xgmii_tx_rst, POLARITY ACTIVE_LOW, INSERT_VIP 0" *)
input wire xgmii_tx_rst;
input wire [63 : 0] xgmii_rxd;
input wire [7 : 0] xgmii_rxc;
output wire [63 : 0] xgmii_txd;
output wire [7 : 0] xgmii_txc;
input wire s_udp_hdr_valid;
output wire s_udp_hdr_ready;
input wire [5 : 0] s_udp_ip_dscp;
input wire [1 : 0] s_udp_ip_ecn;
input wire [7 : 0] s_udp_ip_ttl;
input wire [31 : 0] s_udp_ip_source_ip;
input wire [31 : 0] s_udp_ip_dest_ip;
input wire [15 : 0] s_udp_source_port;
input wire [15 : 0] s_udp_dest_port;
input wire [15 : 0] s_udp_length;
input wire [15 : 0] s_udp_checksum;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_udp_payload_axis TDATA" *)
(* X_INTERFACE_MODE = "slave" *)
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME s_udp_payload_axis, TDATA_NUM_BYTES 8, TDEST_WIDTH 0, TID_WIDTH 0, TUSER_WIDTH 1, HAS_TREADY 1, HAS_TSTRB 0, HAS_TKEEP 1, HAS_TLAST 1, FREQ_HZ 100000000, PHASE 0.0, LAYERED_METADATA undef, INSERT_VIP 0" *)
input wire [63 : 0] s_udp_payload_axis_tdata;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_udp_payload_axis TKEEP" *)
input wire [7 : 0] s_udp_payload_axis_tkeep;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_udp_payload_axis TVALID" *)
input wire s_udp_payload_axis_tvalid;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_udp_payload_axis TREADY" *)
output wire s_udp_payload_axis_tready;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_udp_payload_axis TLAST" *)
input wire s_udp_payload_axis_tlast;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_udp_payload_axis TUSER" *)
input wire s_udp_payload_axis_tuser;
output wire m_udp_hdr_valid;
input wire m_udp_hdr_ready;
output wire [47 : 0] m_udp_eth_dest_mac;
output wire [47 : 0] m_udp_eth_src_mac;
output wire [15 : 0] m_udp_eth_type;
output wire [3 : 0] m_udp_ip_version;
output wire [3 : 0] m_udp_ip_ihl;
output wire [5 : 0] m_udp_ip_dscp;
output wire [1 : 0] m_udp_ip_ecn;
output wire [15 : 0] m_udp_ip_length;
output wire [15 : 0] m_udp_ip_identification;
output wire [2 : 0] m_udp_ip_flags;
output wire [12 : 0] m_udp_ip_fragment_offset;
output wire [7 : 0] m_udp_ip_ttl;
output wire [7 : 0] m_udp_ip_protocol;
output wire [15 : 0] m_udp_ip_header_checksum;
output wire [31 : 0] m_udp_ip_source_ip;
output wire [31 : 0] m_udp_ip_dest_ip;
output wire [15 : 0] m_udp_source_port;
output wire [15 : 0] m_udp_dest_port;
output wire [15 : 0] m_udp_length;
output wire [15 : 0] m_udp_checksum;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_udp_payload_axis TDATA" *)
(* X_INTERFACE_MODE = "master" *)
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME m_udp_payload_axis, TDATA_NUM_BYTES 8, TDEST_WIDTH 0, TID_WIDTH 0, TUSER_WIDTH 1, HAS_TREADY 1, HAS_TSTRB 0, HAS_TKEEP 1, HAS_TLAST 1, FREQ_HZ 100000000, PHASE 0.0, LAYERED_METADATA undef, INSERT_VIP 0" *)
output wire [63 : 0] m_udp_payload_axis_tdata;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_udp_payload_axis TKEEP" *)
output wire [7 : 0] m_udp_payload_axis_tkeep;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_udp_payload_axis TVALID" *)
output wire m_udp_payload_axis_tvalid;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_udp_payload_axis TREADY" *)
input wire m_udp_payload_axis_tready;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_udp_payload_axis TLAST" *)
output wire m_udp_payload_axis_tlast;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_udp_payload_axis TUSER" *)
output wire m_udp_payload_axis_tuser;
output wire rx_error_bad_frame;
output wire rx_error_bad_fcs;
output wire ip_rx_busy;
output wire ip_tx_busy;
output wire udp_rx_busy;
output wire udp_tx_busy;
input wire [47 : 0] local_mac;
input wire [31 : 0] local_ip;
input wire [31 : 0] gateway_ip;
input wire [31 : 0] subnet_mask;
input wire clear_arp_cache;

  net_wrapper inst (
    .logic_clk(logic_clk),
    .logic_rst(logic_rst),
    .xgmii_rx_clk(xgmii_rx_clk),
    .xgmii_rx_rst(xgmii_rx_rst),
    .xgmii_tx_clk(xgmii_tx_clk),
    .xgmii_tx_rst(xgmii_tx_rst),
    .xgmii_rxd(xgmii_rxd),
    .xgmii_rxc(xgmii_rxc),
    .xgmii_txd(xgmii_txd),
    .xgmii_txc(xgmii_txc),
    .s_udp_hdr_valid(s_udp_hdr_valid),
    .s_udp_hdr_ready(s_udp_hdr_ready),
    .s_udp_ip_dscp(s_udp_ip_dscp),
    .s_udp_ip_ecn(s_udp_ip_ecn),
    .s_udp_ip_ttl(s_udp_ip_ttl),
    .s_udp_ip_source_ip(s_udp_ip_source_ip),
    .s_udp_ip_dest_ip(s_udp_ip_dest_ip),
    .s_udp_source_port(s_udp_source_port),
    .s_udp_dest_port(s_udp_dest_port),
    .s_udp_length(s_udp_length),
    .s_udp_checksum(s_udp_checksum),
    .s_udp_payload_axis_tdata(s_udp_payload_axis_tdata),
    .s_udp_payload_axis_tkeep(s_udp_payload_axis_tkeep),
    .s_udp_payload_axis_tvalid(s_udp_payload_axis_tvalid),
    .s_udp_payload_axis_tready(s_udp_payload_axis_tready),
    .s_udp_payload_axis_tlast(s_udp_payload_axis_tlast),
    .s_udp_payload_axis_tuser(s_udp_payload_axis_tuser),
    .m_udp_hdr_valid(m_udp_hdr_valid),
    .m_udp_hdr_ready(m_udp_hdr_ready),
    .m_udp_eth_dest_mac(m_udp_eth_dest_mac),
    .m_udp_eth_src_mac(m_udp_eth_src_mac),
    .m_udp_eth_type(m_udp_eth_type),
    .m_udp_ip_version(m_udp_ip_version),
    .m_udp_ip_ihl(m_udp_ip_ihl),
    .m_udp_ip_dscp(m_udp_ip_dscp),
    .m_udp_ip_ecn(m_udp_ip_ecn),
    .m_udp_ip_length(m_udp_ip_length),
    .m_udp_ip_identification(m_udp_ip_identification),
    .m_udp_ip_flags(m_udp_ip_flags),
    .m_udp_ip_fragment_offset(m_udp_ip_fragment_offset),
    .m_udp_ip_ttl(m_udp_ip_ttl),
    .m_udp_ip_protocol(m_udp_ip_protocol),
    .m_udp_ip_header_checksum(m_udp_ip_header_checksum),
    .m_udp_ip_source_ip(m_udp_ip_source_ip),
    .m_udp_ip_dest_ip(m_udp_ip_dest_ip),
    .m_udp_source_port(m_udp_source_port),
    .m_udp_dest_port(m_udp_dest_port),
    .m_udp_length(m_udp_length),
    .m_udp_checksum(m_udp_checksum),
    .m_udp_payload_axis_tdata(m_udp_payload_axis_tdata),
    .m_udp_payload_axis_tkeep(m_udp_payload_axis_tkeep),
    .m_udp_payload_axis_tvalid(m_udp_payload_axis_tvalid),
    .m_udp_payload_axis_tready(m_udp_payload_axis_tready),
    .m_udp_payload_axis_tlast(m_udp_payload_axis_tlast),
    .m_udp_payload_axis_tuser(m_udp_payload_axis_tuser),
    .rx_error_bad_frame(rx_error_bad_frame),
    .rx_error_bad_fcs(rx_error_bad_fcs),
    .ip_rx_busy(ip_rx_busy),
    .ip_tx_busy(ip_tx_busy),
    .udp_rx_busy(udp_rx_busy),
    .udp_tx_busy(udp_tx_busy),
    .local_mac(local_mac),
    .local_ip(local_ip),
    .gateway_ip(gateway_ip),
    .subnet_mask(subnet_mask),
    .clear_arp_cache(clear_arp_cache)
  );
endmodule
