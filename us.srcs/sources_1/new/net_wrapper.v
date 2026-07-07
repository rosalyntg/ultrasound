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

module net_wrapper #
(
    parameter C_M_AXI_ADDR_WIDTH = 32,
    parameter C_M_AXI_DATA_WIDTH = 32
)
(
    /*
     * Application / logic clock domain.
     * logic_clk also clocks the M_AXI interface; associate them so Vivado
     * IP Integrator ties M_AXI (and its reset) to this clock automatically.
     */
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 logic_clk CLK" *)
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF M_AXI, ASSOCIATED_RESET logic_rst" *)
    input  wire        logic_clk,
    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 logic_rst RST" *)
    (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_HIGH" *)
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
     * AXI-Lite master
     */
    output wire [C_M_AXI_ADDR_WIDTH-1 : 0]     m_axi_awaddr,
    output wire [2 : 0]                        m_axi_awprot,
    output wire                                m_axi_awvalid,
    input  wire                                m_axi_awready,
    output wire [C_M_AXI_DATA_WIDTH-1 : 0]     m_axi_wdata,
    output wire [(C_M_AXI_DATA_WIDTH/8)-1 : 0] m_axi_wstrb,
    output wire                                m_axi_wvalid,
    input  wire                                m_axi_wready,
    input  wire [1 : 0]                        m_axi_bresp,
    input  wire                                m_axi_bvalid,
    output wire                                m_axi_bready,
    output wire [C_M_AXI_ADDR_WIDTH-1 : 0]     m_axi_araddr,
    output wire [2 : 0]                        m_axi_arprot,
    output wire                                m_axi_arvalid,
    input  wire                                m_axi_arready,
    input  wire [C_M_AXI_DATA_WIDTH-1 : 0]     m_axi_rdata,
    input  wire [1 : 0]                        m_axi_rresp,
    input  wire                                m_axi_rvalid,
    output wire                                m_axi_rready,

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
    input  wire [31:0] remote_ip,
    input  wire [31:0] gateway_ip,
    input  wire [31:0] subnet_mask,
    input  wire        clear_arp_cache,

    output wire xfcp_rx_tvalid,
    output wire xfcp_rx_tready,
    output wire [7:0] xfcp_rx_tdata,
    output wire xfcp_rx_tlast,

    output wire xfcp_tx_tvalid,
    output wire xfcp_tx_tready,
    output wire [7:0] xfcp_tx_tdata,
    output wire xfcp_tx_tlast,

    output wire [63:0] udp_tx_tdata,
    output wire [7:0] udp_tx_tkeep,
    output wire udp_tx_tvalid,
    output wire udp_tx_tready,
    output wire udp_tx_tlast,

    output wire [63:0] udp_rx_tdata,
    output wire udp_rx_tready,
    output wire udp_rx_tlast,
    output wire [7:0] udp_rx_tkeep,
    output wire udp_rx_tvalid,

    output wire udp_header_valid,
    output wire [15:0] udp_header_dst_port
);

// ---------------------------------------------------------------------------
// Implementation lives in net.sv (SystemVerilog); this Verilog wrapper is the
// module-reference-friendly boundary for the Vivado block design.  Ports map
// 1:1 to the underlying net module.
// ---------------------------------------------------------------------------
net #(
    .C_M_AXI_ADDR_WIDTH(C_M_AXI_ADDR_WIDTH),
    .C_M_AXI_DATA_WIDTH(C_M_AXI_DATA_WIDTH)
)
net_inst (
    // Application / logic clock domain
    .logic_clk(logic_clk),
    .logic_rst(logic_rst),
    // XGMII 10G interface
    .xgmii_rx_clk(xgmii_rx_clk),
    .xgmii_rx_rst(xgmii_rx_rst),
    .xgmii_tx_clk(xgmii_tx_clk),
    .xgmii_tx_rst(xgmii_tx_rst),
    .xgmii_rxd(xgmii_rxd),
    .xgmii_rxc(xgmii_rxc),
    .xgmii_txd(xgmii_txd),
    .xgmii_txc(xgmii_txc),
    // AXI-Lite master
    .m_axi_awaddr(m_axi_awaddr),
    .m_axi_awprot(m_axi_awprot),
    .m_axi_awvalid(m_axi_awvalid),
    .m_axi_awready(m_axi_awready),
    .m_axi_wdata(m_axi_wdata),
    .m_axi_wstrb(m_axi_wstrb),
    .m_axi_wvalid(m_axi_wvalid),
    .m_axi_wready(m_axi_wready),
    .m_axi_bresp(m_axi_bresp),
    .m_axi_bvalid(m_axi_bvalid),
    .m_axi_bready(m_axi_bready),
    .m_axi_araddr(m_axi_araddr),
    .m_axi_arprot(m_axi_arprot),
    .m_axi_arvalid(m_axi_arvalid),
    .m_axi_arready(m_axi_arready),
    .m_axi_rdata(m_axi_rdata),
    .m_axi_rresp(m_axi_rresp),
    .m_axi_rvalid(m_axi_rvalid),
    .m_axi_rready(m_axi_rready),
    // Status
    .rx_error_bad_frame(rx_error_bad_frame),
    .rx_error_bad_fcs(rx_error_bad_fcs),
    .ip_rx_busy(ip_rx_busy),
    .ip_tx_busy(ip_tx_busy),
    .udp_rx_busy(udp_rx_busy),
    .udp_tx_busy(udp_tx_busy),
    // Configuration
    .local_mac(local_mac),
    .local_ip(local_ip),
    .remote_ip(remote_ip),
    .gateway_ip(gateway_ip),
    .subnet_mask(subnet_mask),
    .clear_arp_cache(clear_arp_cache),

    .xfcp_rx_tvalid(xfcp_rx_tvalid),
    .xfcp_rx_tready(xfcp_rx_tready),
    .xfcp_rx_tdata(xfcp_rx_tdata),
    .xfcp_rx_tlast(xfcp_rx_tlast),
    .xfcp_tx_tvalid(xfcp_tx_tvalid),
    .xfcp_tx_tready(xfcp_tx_tready),
    .xfcp_tx_tdata(xfcp_tx_tdata),
    .xfcp_tx_tlast(xfcp_tx_tlast),

    .udp_tx_tdata(udp_tx_tdata),
    .udp_tx_tkeep(udp_tx_tkeep),
    .udp_tx_tvalid(udp_tx_tvalid),
    .udp_tx_tready(udp_tx_tready),
    .udp_tx_tlast(udp_tx_tlast),

    .udp_rx_tdata(udp_rx_tdata),
    .udp_rx_tready(udp_rx_tready),
    .udp_rx_tlast(udp_rx_tlast),
    .udp_rx_tvalid(udp_rx_tvalid),
    .udp_rx_tkeep(udp_rx_tkeep),
    .udp_header_valid(udp_header_valid),
    .udp_header_dst_port(udp_header_dst_port)
);

endmodule
