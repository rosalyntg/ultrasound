`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/05/2026 06:29:21 PM
// Design Name: 
// Module Name: xfcp_fanout
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module xfcp_fanout #
(
    parameter C_M_AXI_ADDR_WIDTH = 32,
    parameter C_M_AXI_DATA_WIDTH = 32
)
(
    input aclk,
    input aresetn,

    input logic xfcp_rx_tvalid,
    output logic xfcp_rx_tready,
    input logic [7:0] xfcp_rx_tdata,
    input logic xfcp_rx_tlast,

    output logic xfcp_tx_tvalid,
    input logic xfcp_tx_tready,
    output logic [7:0] xfcp_tx_tdata,
    output logic xfcp_tx_tlast,


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

    output wire i2c_sfp_scl_o,
    input wire i2c_sfp_scl_i,
    output wire i2c_sfp_sda_o,
    input wire i2c_sfp_sda_i,

    output wire i2c_hvplus_scl_o,
    input wire i2c_hvplus_scl_i,
    output wire i2c_hvplus_sda_o,
    input wire i2c_hvplus_sda_i,

    output wire i2c_hvminus_scl_o,
    input wire i2c_hvminus_scl_i,
    output wire i2c_hvminus_sda_o,
    input wire i2c_hvminus_sda_i,

    output wire i2c_clk_scl_o,
    input wire i2c_clk_scl_i,
    output wire i2c_clk_sda_o,
    input wire i2c_clk_sda_i,

    output wire i2c_ramp_scl_o,
    input wire i2c_ramp_scl_i,
    output wire i2c_ramp_sda_o,
    input wire i2c_ramp_sda_i
);


taxi_axis_if #(
    .DATA_W(8)
) xfcp_rx(), xfcp_tx();

assign xfcp_rx.tdata = xfcp_rx_tdata;
assign xfcp_rx.tvalid = xfcp_rx_tvalid;
assign xfcp_rx_tready = xfcp_rx.tready;
assign xfcp_rx.tlast = xfcp_rx_tlast;

assign xfcp_tx_tdata = xfcp_tx.tdata;
assign xfcp_tx_tvalid = xfcp_tx.tvalid;
assign xfcp_tx.tready = xfcp_tx_tready;
assign xfcp_tx_tlast = xfcp_tx.tlast;

wire rst;
assign rst = ~aresetn;

// port interfaces
taxi_axis_if #(
    .DATA_W(8)
) xfcp_port_ds[5:0](), xfcp_port_us[5:0]();

taxi_xfcp_switch #(
    .PORTS(6)
) xfcp_switch (
    .clk(aclk),
    .rst(rst),

    .xfcp_usp_ds(xfcp_rx),
    .xfcp_usp_us(xfcp_tx),

    .xfcp_dsp_ds(xfcp_port_ds),
    .xfcp_dsp_us(xfcp_port_us)
);


taxi_axil_if #(
    .DATA_W(C_M_AXI_DATA_WIDTH),
    .ADDR_W(C_M_AXI_ADDR_WIDTH)
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

taxi_xfcp_mod_axil xfcp_axil (
    .clk(aclk),
    .rst(rst),

    .xfcp_usp_ds(xfcp_port_ds[0]),
    .xfcp_usp_us(xfcp_port_us[0]),

    .m_axil_wr(m_axil),
    .m_axil_rd(m_axil)
);


taxi_xfcp_mod_i2c_master #(
    .XFCP_ID_STR("sfp")
) xfcp_i2c_sfp (
    .clk(aclk),
    .rst(rst),

    .xfcp_usp_ds(xfcp_port_ds[1]),
    .xfcp_usp_us(xfcp_port_us[1]),

    .i2c_scl_i(i2c_sfp_scl_i),
    .i2c_scl_o(i2c_sfp_scl_o),
    .i2c_sda_i(i2c_sfp_sda_i),
    .i2c_sda_o(i2c_sfp_sda_o)
);

taxi_xfcp_mod_i2c_master #(
    .XFCP_ID_STR("hvplus")
) xfcp_i2c_hvplus (
    .clk(aclk),
    .rst(rst),

    .xfcp_usp_ds(xfcp_port_ds[2]),
    .xfcp_usp_us(xfcp_port_us[2]),

    .i2c_scl_i(i2c_hvplus_scl_i),
    .i2c_scl_o(i2c_hvplus_scl_o),
    .i2c_sda_i(i2c_hvplus_sda_i),
    .i2c_sda_o(i2c_hvplus_sda_o)
);

taxi_xfcp_mod_i2c_master #(
    .XFCP_ID_STR("hvminus")
) xfcp_i2c_hvminus (
    .clk(aclk),
    .rst(rst),

    .xfcp_usp_ds(xfcp_port_ds[3]),
    .xfcp_usp_us(xfcp_port_us[3]),

    .i2c_scl_i(i2c_hvminus_scl_i),
    .i2c_scl_o(i2c_hvminus_scl_o),
    .i2c_sda_i(i2c_hvminus_sda_i),
    .i2c_sda_o(i2c_hvminus_sda_o)
);

taxi_xfcp_mod_i2c_master  #(
    .XFCP_ID_STR("clk")
) xfcp_i2c_clk (
    .clk(aclk),
    .rst(rst),

    .xfcp_usp_ds(xfcp_port_ds[4]),
    .xfcp_usp_us(xfcp_port_us[4]),

    .i2c_scl_i(i2c_clk_scl_i),
    .i2c_scl_o(i2c_clk_scl_o),
    .i2c_sda_i(i2c_clk_sda_i),
    .i2c_sda_o(i2c_clk_sda_o)
);

taxi_xfcp_mod_i2c_master #(
    .XFCP_ID_STR("ramp")
) xfcp_i2c_ramp (
    .clk(aclk),
    .rst(rst),

    .xfcp_usp_ds(xfcp_port_ds[5]),
    .xfcp_usp_us(xfcp_port_us[5]),

    .i2c_scl_i(i2c_ramp_scl_i),
    .i2c_scl_o(i2c_ramp_scl_o),
    .i2c_sda_i(i2c_ramp_sda_i),
    .i2c_sda_o(i2c_ramp_sda_o)
);

endmodule
