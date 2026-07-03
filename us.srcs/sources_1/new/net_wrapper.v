`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 07/03/2026 11:15:59 PM
// Design Name:
// Module Name: net_wrapper
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//   Vivado "Module Reference" friendly wrapper around Alex Forencich's
//   udp_complete_64 UDP/IP stack (verilog-ethernet).  It bundles together:
//
//       XGMII <-> eth_mac_10g_fifo <-> eth_axis_rx/tx <-> udp_complete_64
//
//   and exposes only two things to the rest of the design:
//       * the 10G XGMII PHY interface (to the transceiver)
//       * the UDP frame input/output interface (application side)
//
//   The IP-frame side of udp_complete_64 is not exposed: the IP input is
//   tied off and the IP output is discarded, so all non-UDP traffic is
//   dropped.  Configuration (MAC/IP/gateway/subnet) is exposed as ports.
//
//   Standard AXI-Stream signal naming is kept so Vivado IP Integrator can
//   auto-infer the AXIS interfaces when this module is added by reference.
//
// Dependencies:
//   verilog-ethernet: eth_mac_10g_fifo, eth_axis_rx, eth_axis_tx,
//                     udp_complete_64 (+ their sub-modules)
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

module net_wrapper 
(
    /*
     * Application / logic clock domain
     */
    input  wire        logic_clk,
    input  wire        logic_rst,

    /*
     * XGMII 10G interface (transceiver clock domains)
     */
    input  wire        xgmii_rx_clk,
    input  wire        xgmii_rx_rst,
    input  wire        xgmii_tx_clk,
    input  wire        xgmii_tx_rst,
    input  wire [63:0] xgmii_rxd,
    input  wire [7:0]  xgmii_rxc,
    output wire [63:0] xgmii_txd,
    output wire [7:0]  xgmii_txc,

    /*
     * UDP frame input (application -> network), logic_clk domain
     */
    input  wire        s_udp_hdr_valid,
    output wire        s_udp_hdr_ready,
    input  wire [5:0]  s_udp_ip_dscp,
    input  wire [1:0]  s_udp_ip_ecn,
    input  wire [7:0]  s_udp_ip_ttl,
    input  wire [31:0] s_udp_ip_source_ip,
    input  wire [31:0] s_udp_ip_dest_ip,
    input  wire [15:0] s_udp_source_port,
    input  wire [15:0] s_udp_dest_port,
    input  wire [15:0] s_udp_length,
    input  wire [15:0] s_udp_checksum,
    input  wire [63:0] s_udp_payload_axis_tdata,
    input  wire [7:0]  s_udp_payload_axis_tkeep,
    input  wire        s_udp_payload_axis_tvalid,
    output wire        s_udp_payload_axis_tready,
    input  wire        s_udp_payload_axis_tlast,
    input  wire        s_udp_payload_axis_tuser,

    /*
     * UDP frame output (network -> application), logic_clk domain
     */
    output wire        m_udp_hdr_valid,
    input  wire        m_udp_hdr_ready,
    output wire [47:0] m_udp_eth_dest_mac,
    output wire [47:0] m_udp_eth_src_mac,
    output wire [15:0] m_udp_eth_type,
    output wire [3:0]  m_udp_ip_version,
    output wire [3:0]  m_udp_ip_ihl,
    output wire [5:0]  m_udp_ip_dscp,
    output wire [1:0]  m_udp_ip_ecn,
    output wire [15:0] m_udp_ip_length,
    output wire [15:0] m_udp_ip_identification,
    output wire [2:0]  m_udp_ip_flags,
    output wire [12:0] m_udp_ip_fragment_offset,
    output wire [7:0]  m_udp_ip_ttl,
    output wire [7:0]  m_udp_ip_protocol,
    output wire [15:0] m_udp_ip_header_checksum,
    output wire [31:0] m_udp_ip_source_ip,
    output wire [31:0] m_udp_ip_dest_ip,
    output wire [15:0] m_udp_source_port,
    output wire [15:0] m_udp_dest_port,
    output wire [15:0] m_udp_length,
    output wire [15:0] m_udp_checksum,
    output wire [63:0] m_udp_payload_axis_tdata,
    output wire [7:0]  m_udp_payload_axis_tkeep,
    output wire        m_udp_payload_axis_tvalid,
    input  wire        m_udp_payload_axis_tready,
    output wire        m_udp_payload_axis_tlast,
    output wire        m_udp_payload_axis_tuser,

    /*
     * Status
     */
    output wire        rx_error_bad_frame,
    output wire        rx_error_bad_fcs,
    output wire        ip_rx_busy,
    output wire        ip_tx_busy,
    output wire        udp_rx_busy,
    output wire        udp_tx_busy,

    /*
     * Configuration
     */
    input  wire [47:0] local_mac,
    input  wire [31:0] local_ip,
    input  wire [31:0] gateway_ip,
    input  wire [31:0] subnet_mask,
    input  wire        clear_arp_cache
);

// ---------------------------------------------------------------------------
// Internal nets
// ---------------------------------------------------------------------------

// AXI stream between MAC and eth_axis_rx/tx (logic_clk domain)
wire [63:0] mac_rx_axis_tdata;
wire [7:0]  mac_rx_axis_tkeep;
wire        mac_rx_axis_tvalid;
wire        mac_rx_axis_tready;
wire        mac_rx_axis_tlast;
wire        mac_rx_axis_tuser;

wire [63:0] mac_tx_axis_tdata;
wire [7:0]  mac_tx_axis_tkeep;
wire        mac_tx_axis_tvalid;
wire        mac_tx_axis_tready;
wire        mac_tx_axis_tlast;
wire        mac_tx_axis_tuser;

// Ethernet frame between eth_axis_rx/tx and udp_complete_64
wire        rx_eth_hdr_valid;
wire        rx_eth_hdr_ready;
wire [47:0] rx_eth_dest_mac;
wire [47:0] rx_eth_src_mac;
wire [15:0] rx_eth_type;
wire [63:0] rx_eth_payload_axis_tdata;
wire [7:0]  rx_eth_payload_axis_tkeep;
wire        rx_eth_payload_axis_tvalid;
wire        rx_eth_payload_axis_tready;
wire        rx_eth_payload_axis_tlast;
wire        rx_eth_payload_axis_tuser;

wire        tx_eth_hdr_valid;
wire        tx_eth_hdr_ready;
wire [47:0] tx_eth_dest_mac;
wire [47:0] tx_eth_src_mac;
wire [15:0] tx_eth_type;
wire [63:0] tx_eth_payload_axis_tdata;
wire [7:0]  tx_eth_payload_axis_tkeep;
wire        tx_eth_payload_axis_tvalid;
wire        tx_eth_payload_axis_tready;
wire        tx_eth_payload_axis_tlast;
wire        tx_eth_payload_axis_tuser;

// ---------------------------------------------------------------------------
// 10G Ethernet MAC with FIFOs (crosses XGMII rx/tx clocks -> logic_clk)
// ---------------------------------------------------------------------------
eth_mac_10g_fifo #(
)
eth_mac_10g_fifo_inst (
    .rx_clk(xgmii_rx_clk),
    .rx_rst(xgmii_rx_rst),
    .tx_clk(xgmii_tx_clk),
    .tx_rst(xgmii_tx_rst),
    .logic_clk(logic_clk),
    .logic_rst(logic_rst),
    .ptp_sample_clk(1'b0),

    // AXI input (TX)
    .tx_axis_tdata(mac_tx_axis_tdata),
    .tx_axis_tkeep(mac_tx_axis_tkeep),
    .tx_axis_tvalid(mac_tx_axis_tvalid),
    .tx_axis_tready(mac_tx_axis_tready),
    .tx_axis_tlast(mac_tx_axis_tlast),
    .tx_axis_tuser(mac_tx_axis_tuser),

    // Transmit timestamp (unused)
    .m_axis_tx_ptp_ts_96(),
    .m_axis_tx_ptp_ts_tag(),
    .m_axis_tx_ptp_ts_valid(),
    .m_axis_tx_ptp_ts_ready(1'b0),

    // AXI output (RX)
    .rx_axis_tdata(mac_rx_axis_tdata),
    .rx_axis_tkeep(mac_rx_axis_tkeep),
    .rx_axis_tvalid(mac_rx_axis_tvalid),
    .rx_axis_tready(mac_rx_axis_tready),
    .rx_axis_tlast(mac_rx_axis_tlast),
    .rx_axis_tuser(mac_rx_axis_tuser),

    // XGMII
    .xgmii_rxd(xgmii_rxd),
    .xgmii_rxc(xgmii_rxc),
    .xgmii_txd(xgmii_txd),
    .xgmii_txc(xgmii_txc),

    // Status
    .tx_error_underflow(),
    .tx_fifo_overflow(),
    .tx_fifo_bad_frame(),
    .tx_fifo_good_frame(),
    .rx_error_bad_frame(rx_error_bad_frame),
    .rx_error_bad_fcs(rx_error_bad_fcs),
    .rx_fifo_overflow(),
    .rx_fifo_bad_frame(),
    .rx_fifo_good_frame(),

    // PTP clock (unused)
    .ptp_ts_96(96'd0),
    .ptp_ts_step(1'b0),

    // Configuration
    .cfg_ifg(8'd12),
    .cfg_tx_enable(1'b1),
    .cfg_rx_enable(1'b1)
);

// ---------------------------------------------------------------------------
// AXI stream <-> Ethernet frame conversion
// ---------------------------------------------------------------------------
eth_axis_rx #(
    .DATA_WIDTH(64)
)
eth_axis_rx_inst (
    .clk(logic_clk),
    .rst(logic_rst),
    // AXI input
    .s_axis_tdata(mac_rx_axis_tdata),
    .s_axis_tkeep(mac_rx_axis_tkeep),
    .s_axis_tvalid(mac_rx_axis_tvalid),
    .s_axis_tready(mac_rx_axis_tready),
    .s_axis_tlast(mac_rx_axis_tlast),
    .s_axis_tuser(mac_rx_axis_tuser),
    // Ethernet frame output
    .m_eth_hdr_valid(rx_eth_hdr_valid),
    .m_eth_hdr_ready(rx_eth_hdr_ready),
    .m_eth_dest_mac(rx_eth_dest_mac),
    .m_eth_src_mac(rx_eth_src_mac),
    .m_eth_type(rx_eth_type),
    .m_eth_payload_axis_tdata(rx_eth_payload_axis_tdata),
    .m_eth_payload_axis_tkeep(rx_eth_payload_axis_tkeep),
    .m_eth_payload_axis_tvalid(rx_eth_payload_axis_tvalid),
    .m_eth_payload_axis_tready(rx_eth_payload_axis_tready),
    .m_eth_payload_axis_tlast(rx_eth_payload_axis_tlast),
    .m_eth_payload_axis_tuser(rx_eth_payload_axis_tuser),
    // Status
    .busy(),
    .error_header_early_termination()
);

eth_axis_tx #(
    .DATA_WIDTH(64)
)
eth_axis_tx_inst (
    .clk(logic_clk),
    .rst(logic_rst),
    // Ethernet frame input
    .s_eth_hdr_valid(tx_eth_hdr_valid),
    .s_eth_hdr_ready(tx_eth_hdr_ready),
    .s_eth_dest_mac(tx_eth_dest_mac),
    .s_eth_src_mac(tx_eth_src_mac),
    .s_eth_type(tx_eth_type),
    .s_eth_payload_axis_tdata(tx_eth_payload_axis_tdata),
    .s_eth_payload_axis_tkeep(tx_eth_payload_axis_tkeep),
    .s_eth_payload_axis_tvalid(tx_eth_payload_axis_tvalid),
    .s_eth_payload_axis_tready(tx_eth_payload_axis_tready),
    .s_eth_payload_axis_tlast(tx_eth_payload_axis_tlast),
    .s_eth_payload_axis_tuser(tx_eth_payload_axis_tuser),
    // AXI output
    .m_axis_tdata(mac_tx_axis_tdata),
    .m_axis_tkeep(mac_tx_axis_tkeep),
    .m_axis_tvalid(mac_tx_axis_tvalid),
    .m_axis_tready(mac_tx_axis_tready),
    .m_axis_tlast(mac_tx_axis_tlast),
    .m_axis_tuser(mac_tx_axis_tuser),
    // Status
    .busy()
);

// ---------------------------------------------------------------------------
// UDP/IP stack.  IP frame side is not exposed:
//   - IP input tied off (no raw IP injection)
//   - IP output discarded / ready held high (drop non-UDP IP traffic)
// ---------------------------------------------------------------------------
udp_complete_64 #(
//    .ARP_CACHE_ADDR_WIDTH(ARP_CACHE_ADDR_WIDTH),
//    .ARP_REQUEST_RETRY_COUNT(ARP_REQUEST_RETRY_COUNT),
//    .ARP_REQUEST_RETRY_INTERVAL(ARP_REQUEST_RETRY_INTERVAL),
//    .ARP_REQUEST_TIMEOUT(ARP_REQUEST_TIMEOUT),
//    .UDP_CHECKSUM_GEN_ENABLE(UDP_CHECKSUM_GEN_ENABLE)
)
udp_complete_inst (
    .clk(logic_clk),
    .rst(logic_rst),
    // Ethernet frame input (from eth_axis_rx)
    .s_eth_hdr_valid(rx_eth_hdr_valid),
    .s_eth_hdr_ready(rx_eth_hdr_ready),
    .s_eth_dest_mac(rx_eth_dest_mac),
    .s_eth_src_mac(rx_eth_src_mac),
    .s_eth_type(rx_eth_type),
    .s_eth_payload_axis_tdata(rx_eth_payload_axis_tdata),
    .s_eth_payload_axis_tkeep(rx_eth_payload_axis_tkeep),
    .s_eth_payload_axis_tvalid(rx_eth_payload_axis_tvalid),
    .s_eth_payload_axis_tready(rx_eth_payload_axis_tready),
    .s_eth_payload_axis_tlast(rx_eth_payload_axis_tlast),
    .s_eth_payload_axis_tuser(rx_eth_payload_axis_tuser),
    // Ethernet frame output (to eth_axis_tx)
    .m_eth_hdr_valid(tx_eth_hdr_valid),
    .m_eth_hdr_ready(tx_eth_hdr_ready),
    .m_eth_dest_mac(tx_eth_dest_mac),
    .m_eth_src_mac(tx_eth_src_mac),
    .m_eth_type(tx_eth_type),
    .m_eth_payload_axis_tdata(tx_eth_payload_axis_tdata),
    .m_eth_payload_axis_tkeep(tx_eth_payload_axis_tkeep),
    .m_eth_payload_axis_tvalid(tx_eth_payload_axis_tvalid),
    .m_eth_payload_axis_tready(tx_eth_payload_axis_tready),
    .m_eth_payload_axis_tlast(tx_eth_payload_axis_tlast),
    .m_eth_payload_axis_tuser(tx_eth_payload_axis_tuser),
    // IP frame input (unused - tied off)
    .s_ip_hdr_valid(1'b0),
    .s_ip_hdr_ready(),
    .s_ip_dscp(6'd0),
    .s_ip_ecn(2'd0),
    .s_ip_length(16'd0),
    .s_ip_ttl(8'd0),
    .s_ip_protocol(8'd0),
    .s_ip_source_ip(32'd0),
    .s_ip_dest_ip(32'd0),
    .s_ip_payload_axis_tdata(64'd0),
    .s_ip_payload_axis_tkeep(8'd0),
    .s_ip_payload_axis_tvalid(1'b0),
    .s_ip_payload_axis_tready(),
    .s_ip_payload_axis_tlast(1'b0),
    .s_ip_payload_axis_tuser(1'b0),
    // IP frame output (unused - discarded, ready held high)
    .m_ip_hdr_valid(),
    .m_ip_hdr_ready(1'b1),
    .m_ip_eth_dest_mac(),
    .m_ip_eth_src_mac(),
    .m_ip_eth_type(),
    .m_ip_version(),
    .m_ip_ihl(),
    .m_ip_dscp(),
    .m_ip_ecn(),
    .m_ip_length(),
    .m_ip_identification(),
    .m_ip_flags(),
    .m_ip_fragment_offset(),
    .m_ip_ttl(),
    .m_ip_protocol(),
    .m_ip_header_checksum(),
    .m_ip_source_ip(),
    .m_ip_dest_ip(),
    .m_ip_payload_axis_tdata(),
    .m_ip_payload_axis_tkeep(),
    .m_ip_payload_axis_tvalid(),
    .m_ip_payload_axis_tready(1'b1),
    .m_ip_payload_axis_tlast(),
    .m_ip_payload_axis_tuser(),
    // UDP frame input (application side)
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
    // UDP frame output (application side)
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
    // Status
    .ip_rx_busy(ip_rx_busy),
    .ip_tx_busy(ip_tx_busy),
    .udp_rx_busy(udp_rx_busy),
    .udp_tx_busy(udp_tx_busy),
    .ip_rx_error_header_early_termination(),
    .ip_rx_error_payload_early_termination(),
    .ip_rx_error_invalid_header(),
    .ip_rx_error_invalid_checksum(),
    .ip_tx_error_payload_early_termination(),
    .ip_tx_error_arp_failed(),
    .udp_rx_error_header_early_termination(),
    .udp_rx_error_payload_early_termination(),
    .udp_tx_error_payload_early_termination(),
    // Configuration
    .local_mac(local_mac),
    .local_ip(local_ip),
    .gateway_ip(gateway_ip),
    .subnet_mask(subnet_mask),
    .clear_arp_cache(clear_arp_cache)
);

endmodule
