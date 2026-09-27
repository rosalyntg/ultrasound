`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 07/06/2026
// Design Name:
// Module Name: xfcp_fanout_wrapper
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//   Vivado "Module Reference" friendly wrapper around xfcp_fanout (SystemVerilog).
//   Exposes:
//       * XFCP rx/tx byte streams as AXI-Stream interfaces (XFCP_RX / XFCP_TX)
//       * an AXI-Lite master (M_AXI)
//       * five I2C masters as standard IIC bus interfaces so IP Integrator
//         groups them and the board flow can hook up IOBUFs
//
//   The underlying I2C masters are open-drain: the _o outputs are 0 when the
//   line is driven low and 1 when released, so the IIC tristate controls
//   (SCL_T/SDA_T) are simply mirrors of the _o signals.
//
// Dependencies:
//   xfcp_fanout.sv (taxi_xfcp_switch, taxi_xfcp_mod_axil,
//                   taxi_xfcp_mod_i2c_master)
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

module xfcp_fanout_wrapper #
(
    parameter C_M_AXI_ADDR_WIDTH = 32,
    parameter C_M_AXI_DATA_WIDTH = 32
)
(
    /*
     * Clock / reset.  Everything in here is on aclk; associate the AXIS and
     * AXI-Lite interfaces (and the reset) so IP Integrator ties them to this
     * clock automatically.
     */
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 aclk CLK" *)
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF XFCP_RX:XFCP_TX:M_AXI, ASSOCIATED_RESET rst" *)
    input  wire aclk,
    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 rst RST" *)
    input  wire aresetn,

    /*
     * XFCP downstream (rx) / upstream (tx) byte streams
     */
    input  wire       xfcp_rx_tvalid,
    output wire       xfcp_rx_tready,
    input  wire [7:0] xfcp_rx_tdata,
    input  wire       xfcp_rx_tlast,

    output wire       xfcp_tx_tvalid,
    input  wire       xfcp_tx_tready,
    output wire [7:0] xfcp_tx_tdata,
    output wire       xfcp_tx_tlast,

    /*
     * AXI-Lite master (auto-inferred from the m_axi_ prefix as M_AXI)
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
     * I2C masters, exposed as standard IIC bus interfaces
     */
    (* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 IIC_SFP SCL_I" *)
    input  wire i2c_sfp_scl_i,
    (* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 IIC_SFP SCL_O" *)
    output wire i2c_sfp_scl_o,
    (* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 IIC_SFP SCL_T" *)
    output wire i2c_sfp_scl_t,
    (* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 IIC_SFP SDA_I" *)
    input  wire i2c_sfp_sda_i,
    (* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 IIC_SFP SDA_O" *)
    output wire i2c_sfp_sda_o,
    (* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 IIC_SFP SDA_T" *)
    output wire i2c_sfp_sda_t,

    (* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 IIC_HVPLUS SCL_I" *)
    input  wire i2c_hvplus_scl_i,
    (* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 IIC_HVPLUS SCL_O" *)
    output wire i2c_hvplus_scl_o,
    (* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 IIC_HVPLUS SCL_T" *)
    output wire i2c_hvplus_scl_t,
    (* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 IIC_HVPLUS SDA_I" *)
    input  wire i2c_hvplus_sda_i,
    (* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 IIC_HVPLUS SDA_O" *)
    output wire i2c_hvplus_sda_o,
    (* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 IIC_HVPLUS SDA_T" *)
    output wire i2c_hvplus_sda_t,

    (* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 IIC_HVMINUS SCL_I" *)
    input  wire i2c_hvminus_scl_i,
    (* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 IIC_HVMINUS SCL_O" *)
    output wire i2c_hvminus_scl_o,
    (* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 IIC_HVMINUS SCL_T" *)
    output wire i2c_hvminus_scl_t,
    (* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 IIC_HVMINUS SDA_I" *)
    input  wire i2c_hvminus_sda_i,
    (* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 IIC_HVMINUS SDA_O" *)
    output wire i2c_hvminus_sda_o,
    (* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 IIC_HVMINUS SDA_T" *)
    output wire i2c_hvminus_sda_t,

    (* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 IIC_CLK SCL_I" *)
    input  wire i2c_clk_scl_i,
    (* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 IIC_CLK SCL_O" *)
    output wire i2c_clk_scl_o,
    (* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 IIC_CLK SCL_T" *)
    output wire i2c_clk_scl_t,
    (* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 IIC_CLK SDA_I" *)
    input  wire i2c_clk_sda_i,
    (* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 IIC_CLK SDA_O" *)
    output wire i2c_clk_sda_o,
    (* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 IIC_CLK SDA_T" *)
    output wire i2c_clk_sda_t,

    (* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 IIC_RAMP SCL_I" *)
    input  wire i2c_ramp_scl_i,
    (* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 IIC_RAMP SCL_O" *)
    output wire i2c_ramp_scl_o,
    (* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 IIC_RAMP SCL_T" *)
    output wire i2c_ramp_scl_t,
    (* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 IIC_RAMP SDA_I" *)
    input  wire i2c_ramp_sda_i,
    (* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 IIC_RAMP SDA_O" *)
    output wire i2c_ramp_sda_o,
    (* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 IIC_RAMP SDA_T" *)
    output wire i2c_ramp_sda_t
);

// Open drain: _o is 1 when the line is released, so it doubles as the
// tristate control (T=1 -> high-Z at the IOBUF).
assign i2c_sfp_scl_t     = i2c_sfp_scl_o;
assign i2c_sfp_sda_t     = i2c_sfp_sda_o;
assign i2c_hvplus_scl_t  = i2c_hvplus_scl_o;
assign i2c_hvplus_sda_t  = i2c_hvplus_sda_o;
assign i2c_hvminus_scl_t = i2c_hvminus_scl_o;
assign i2c_hvminus_sda_t = i2c_hvminus_sda_o;
assign i2c_clk_scl_t     = i2c_clk_scl_o;
assign i2c_clk_sda_t     = i2c_clk_sda_o;
assign i2c_ramp_scl_t    = i2c_ramp_scl_o;
assign i2c_ramp_sda_t    = i2c_ramp_sda_o;

// ---------------------------------------------------------------------------
// Implementation lives in xfcp_fanout.sv (SystemVerilog); this Verilog wrapper
// is the module-reference-friendly boundary for the Vivado block design.
// Ports map 1:1 to the underlying xfcp_fanout module.
// ---------------------------------------------------------------------------
xfcp_fanout #(
    .C_M_AXI_ADDR_WIDTH(C_M_AXI_ADDR_WIDTH),
    .C_M_AXI_DATA_WIDTH(C_M_AXI_DATA_WIDTH)
)
xfcp_fanout_inst (
    .aclk(aclk),
    .aresetn(aresetn),

    .xfcp_rx_tvalid(xfcp_rx_tvalid),
    .xfcp_rx_tready(xfcp_rx_tready),
    .xfcp_rx_tdata(xfcp_rx_tdata),
    .xfcp_rx_tlast(xfcp_rx_tlast),

    .xfcp_tx_tvalid(xfcp_tx_tvalid),
    .xfcp_tx_tready(xfcp_tx_tready),
    .xfcp_tx_tdata(xfcp_tx_tdata),
    .xfcp_tx_tlast(xfcp_tx_tlast),

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

    // I2C busses
    .i2c_sfp_scl_o(i2c_sfp_scl_o),
    .i2c_sfp_scl_i(i2c_sfp_scl_i),
    .i2c_sfp_sda_o(i2c_sfp_sda_o),
    .i2c_sfp_sda_i(i2c_sfp_sda_i),

    .i2c_hvplus_scl_o(i2c_hvplus_scl_o),
    .i2c_hvplus_scl_i(i2c_hvplus_scl_i),
    .i2c_hvplus_sda_o(i2c_hvplus_sda_o),
    .i2c_hvplus_sda_i(i2c_hvplus_sda_i),

    .i2c_hvminus_scl_o(i2c_hvminus_scl_o),
    .i2c_hvminus_scl_i(i2c_hvminus_scl_i),
    .i2c_hvminus_sda_o(i2c_hvminus_sda_o),
    .i2c_hvminus_sda_i(i2c_hvminus_sda_i),

    .i2c_clk_scl_o(i2c_clk_scl_o),
    .i2c_clk_scl_i(i2c_clk_scl_i),
    .i2c_clk_sda_o(i2c_clk_sda_o),
    .i2c_clk_sda_i(i2c_clk_sda_i),

    .i2c_ramp_scl_o(i2c_ramp_scl_o),
    .i2c_ramp_scl_i(i2c_ramp_scl_i),
    .i2c_ramp_sda_o(i2c_ramp_sda_o),
    .i2c_ramp_sda_i(i2c_ramp_sda_i)
);

endmodule
