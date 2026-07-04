`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 07/03/2026 11:56:36 PM
// Design Name:
// Module Name: net
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//   SystemVerilog implementation of the 10G UDP/IP network stack.  Bundles:
//
//       XGMII <-> eth_mac_10g_fifo <-> eth_axis_rx/tx <-> udp_complete_64
//
//   and exposes:
//       * the 10G XGMII PHY interface (to the transceiver)
//       * the UDP frame input/output interface (application side)
//
//   The IP-frame side of udp_complete_64 is not exposed: the IP input is
//   tied off and the IP output is discarded, so all non-UDP traffic is
//   dropped.  Configuration (MAC/IP/gateway/subnet) is exposed as ports.
//
//   net_wrapper.v is a thin Verilog wrapper around this module intended for
//   instantiation in a Vivado block design (Module Reference).
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

interface udpaux_if;
    logic        hdr_valid;
    logic        hdr_ready;
    logic        [5:0]  ip_dscp;
    logic        [1:0]  ip_ecn;
    logic        [7:0]  ip_ttl;
    logic        [31:0] ip_source_ip;
    logic        [31:0] ip_dest_ip;
    logic        [15:0] source_port;
    logic        [15:0] dest_port;
    logic        [15:0] length;
    logic        [15:0] checksum;
endinterface

module net #
(
    parameter C_M_AXI_ADDR_WIDTH = 32,
    parameter C_M_AXI_DATA_WIDTH = 32
)
(
    /*
     * Application / logic clock domain
     */
    input  logic        logic_clk,
    input  logic        logic_rst,

    /*
     * XGMII 10G interface (transceiver clock domains)
     */
    input  logic        xgmii_rx_clk,
    input  logic        xgmii_rx_rst,
    input  logic        xgmii_tx_clk,
    input  logic        xgmii_tx_rst,
    input  logic [63:0] xgmii_rxd,
    input  logic [7:0]  xgmii_rxc,
    output logic [63:0] xgmii_txd,
    output logic [7:0]  xgmii_txc,

    // AXI-Lite master
    output wire [C_M_AXI_ADDR_WIDTH-1 : 0] m_axi_awaddr,
    output wire [2 : 0] m_axi_awprot,
    output wire  m_axi_awvalid,
    input wire  m_axi_awready,
    output wire [C_M_AXI_DATA_WIDTH-1 : 0] m_axi_wdata,
    output wire [(C_M_AXI_DATA_WIDTH/8)-1 : 0] m_axi_wstrb,
    output wire  m_axi_wvalid,
    input wire  m_axi_wready,
    input wire [1 : 0] m_axi_bresp,
    input wire  m_axi_bvalid,
    output wire  m_axi_bready,
    output wire [C_M_AXI_ADDR_WIDTH-1 : 0] m_axi_araddr,
    output wire [2 : 0] m_axi_arprot,
    output wire  m_axi_arvalid,
    input wire  m_axi_arready,
    input wire [C_M_AXI_DATA_WIDTH-1 : 0] m_axi_rdata,
    input wire [1 : 0] m_axi_rresp,
    input wire  m_axi_rvalid,
    output wire  m_axi_rready,

    /*
     * Status
     */
    output logic        rx_error_bad_frame,
    output logic        rx_error_bad_fcs,
    output logic        ip_rx_busy,
    output logic        ip_tx_busy,
    output logic        udp_rx_busy,
    output logic        udp_tx_busy,

    /*
     * Configuration
     */
    input  logic [47:0] local_mac,
    input  logic [31:0] local_ip,
    input  logic [31:0] gateway_ip,
    input  logic [31:0] subnet_mask,
    input  logic        clear_arp_cache,

    input  logic        tx_test
);

// ---------------------------------------------------------------------------
// Internal nets
// ---------------------------------------------------------------------------

// AXI stream between MAC and eth_axis_rx/tx (logic_clk domain)
logic [63:0] mac_rx_axis_tdata;
logic [7:0]  mac_rx_axis_tkeep;
logic        mac_rx_axis_tvalid;
logic        mac_rx_axis_tready;
logic        mac_rx_axis_tlast;
logic        mac_rx_axis_tuser;

logic [63:0] mac_tx_axis_tdata;
logic [7:0]  mac_tx_axis_tkeep;
logic        mac_tx_axis_tvalid;
logic        mac_tx_axis_tready;
logic        mac_tx_axis_tlast;
logic        mac_tx_axis_tuser;

// Ethernet frame between eth_axis_rx/tx and udp_complete_64
logic        rx_eth_hdr_valid;
logic        rx_eth_hdr_ready;
logic [47:0] rx_eth_dest_mac;
logic [47:0] rx_eth_src_mac;
logic [15:0] rx_eth_type;
logic [63:0] rx_eth_payload_axis_tdata;
logic [7:0]  rx_eth_payload_axis_tkeep;
logic        rx_eth_payload_axis_tvalid;
logic        rx_eth_payload_axis_tready;
logic        rx_eth_payload_axis_tlast;
logic        rx_eth_payload_axis_tuser;

logic        tx_eth_hdr_valid;
logic        tx_eth_hdr_ready;
logic [47:0] tx_eth_dest_mac;
logic [47:0] tx_eth_src_mac;
logic [15:0] tx_eth_type;
logic [63:0] tx_eth_payload_axis_tdata;
logic [7:0]  tx_eth_payload_axis_tkeep;
logic        tx_eth_payload_axis_tvalid;
logic        tx_eth_payload_axis_tready;
logic        tx_eth_payload_axis_tlast;
logic        tx_eth_payload_axis_tuser;

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


taxi_axis_if #(.DATA_W(8), .LAST_EN(1), .USER_EN(1), .USER_W(1)) xfcp_rx(), xfcp_tx(), xfcp_tx_checksum();
assign xfcp_rx.tvalid = m_udp_payload_axis_tvalid && m_udp_dest_port == 16'd8001;

udpaux_if udp_tx_checksum();

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
    .s_udp_hdr_valid(udp_tx_checksum.hdr_valid),
    .s_udp_hdr_ready(udp_tx_checksum.hdr_ready),
    .s_udp_ip_dscp(udp_tx_checksum.ip_dscp),
    .s_udp_ip_ecn(udp_tx_checksum.ip_ecn),
    .s_udp_ip_ttl(udp_tx_checksum.ip_ttl),
    .s_udp_ip_source_ip(udp_tx_checksum.ip_source_ip),
    .s_udp_ip_dest_ip(udp_tx_checksum.ip_dest_ip),
    .s_udp_source_port(udp_tx_checksum.source_port),
    .s_udp_dest_port(udp_tx_checksum.dest_port),
    .s_udp_length(udp_tx_checksum.length),
    .s_udp_checksum(udp_tx_checksum.checksum),
    .s_udp_payload_axis_tdata(xfcp_tx_checksum.tdata),
    .s_udp_payload_axis_tkeep(xfcp_tx_checksum.tkeep),
    .s_udp_payload_axis_tvalid(xfcp_tx_checksum.tvalid),
    .s_udp_payload_axis_tready(xfcp_tx_checksum.tready),
    .s_udp_payload_axis_tlast(xfcp_tx_checksum.tlast),
    .s_udp_payload_axis_tuser(xfcp_tx_checksum.tuser),
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
    .m_udp_payload_axis_tdata(xfcp_rx.tdata),
    .m_udp_payload_axis_tkeep(xfcp_rx.tkeep),
    .m_udp_payload_axis_tvalid(m_udp_payload_axis_tvalid),
    .m_udp_payload_axis_tready(xfcp_rx.tready),
    .m_udp_payload_axis_tlast(xfcp_rx.tlast),
    .m_udp_payload_axis_tuser(xfcp_rx.tuser),
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

udp_checksum_gen_64 udp_checksum_gen_inst (
    .clk(logic_clk),
    .rst(logic_rst),
    // AXI input
    .s_udp_payload_axis_tdata(xfcp_tx.tdata),
    .s_udp_payload_axis_tkeep(xfcp_tx.tkeep),
    .s_udp_payload_axis_tvalid(xfcp_tx.tvalid),
    .s_udp_payload_axis_tready(xfcp_tx.tready | tx_test),
    .s_udp_payload_axis_tlast(xfcp_tx.tlast),
    .s_udp_payload_axis_tuser(xfcp_tx.tuser),


    .s_udp_hdr_valid(1'b1),
    .s_udp_hdr_ready(1'b1),
    .s_ip_source_ip({8'd10, 8'd80, 8'd4, 8'd1}),
    .s_ip_dest_ip({8'd10, 8'd80, 8'd4, 8'd2}),
    .s_udp_source_port(16'd8001),
    .s_udp_dest_port(16'd8001),

    // AXI output
    .m_udp_payload_axis_tdata(xfcp_tx_checksum.tdata),
    .m_udp_payload_axis_tkeep(xfcp_tx_checksum.tkeep),
    .m_udp_payload_axis_tvalid(xfcp_tx_checksum.tvalid),
    .m_udp_payload_axis_tready(xfcp_tx_checksum.tready),
    .m_udp_payload_axis_tlast(xfcp_tx_checksum.tlast),
    .m_udp_payload_axis_tuser(xfcp_tx_checksum.tuser),

    .m_udp_hdr_valid(udp_tx_checksum.hdr_valid),
    .m_udp_hdr_ready(udp_tx_checksum.hdr_ready),
    .m_ip_dscp(udp_tx_checksum.ip_dscp),
    .m_ip_ecn(udp_tx_checksum.ip_ecn),
    .m_ip_ttl(udp_tx_checksum.ip_ttl),
    .m_ip_source_ip(udp_tx_checksum.ip_source_ip),
    .m_ip_dest_ip(udp_tx_checksum.ip_dest_ip),
    .m_udp_source_port(udp_tx_checksum.source_port),
    .m_udp_dest_port(udp_tx_checksum.dest_port),
    .m_udp_length(udp_tx_checksum.length),
    .m_udp_checksum(udp_tx_checksum.checksum)
);

taxi_axil_if #(
    .DATA_W(C_M_AXI_DATA_WIDTH),
    .ADDR_W(C_M_AXI_ADDR_WIDTH),
    .STRB_W(C_M_AXI_DATA_WIDTH/8)
) m_axil();

assign m_axi_awaddr = m_axil.awaddr;
assign m_axi_awprot = m_axil.awprot;
assign m_axi_awvalid = m_axil.awvalid;
assign m_axil.awready = m_axi_awready;
assign m_axi_wdata = m_axil.wdata;
assign m_axi_wstrb = m_axil.wstrb;
assign m_axi_wvalid = m_axil.wvalid;
assign m_axil.wready = m_axi_wready;
assign m_axil.bresp = m_axi_bresp;
assign m_axil.bvalid = m_axi_bvalid;
assign m_axi_bready = m_axil.bready;
assign m_axi_araddr = m_axil.araddr;
assign m_axi_arprot = m_axil.arprot;
assign m_axi_arvalid = m_axil.arvalid;
assign m_axil.arready = m_axi_arready;
assign m_axil.rdata = m_axi_rdata;
assign m_axil.rresp = m_axi_rresp;
assign m_axil.rvalid = m_axi_rvalid;
assign m_axi_rready = m_axil.rready;

taxi_xfcp_mod_axil xfcp (
    .clk(logic_clk),
    .rst(logic_rst),

    .xfcp_usp_ds(xfcp_rx),
    .xfcp_usp_us(xfcp_tx),

    .m_axil_wr(m_axil),
    .m_axil_rd(m_axil)
);

endmodule
