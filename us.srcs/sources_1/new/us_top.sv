`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/11/2026 05:56:35 AM
// Design Name: 
// Module Name: us_top
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

module us_top(
    // Sysclk
    input wire osc200mhz_n,
    input wire osc200mhz_p,

    // Pulser Pins
    output wire [3:0] pulser0_neg,
    output wire [3:0] pulser0_pos,
    
    output wire [3:0] pulser1_neg,
    output wire [3:0] pulser1_pos,
    
    output wire pulser_clk,
    output wire pulser_oen,
    
    input wire pulser0_optn,
    input wire pulser1_optn,
    
    // DAC
    output wire ramp_scl,
    output wire ramp_sda,
    output wire ramp_rst,
    
    // SFP
    inout wire sfp_scl,
    inout wire sfp_sda,
    input wire eth_refclkn,
    input wire eth_refclkp,
    input wire sfp_rdn,
    input wire sfp_rdp,
    output wire sfp_txn,
    output wire sfp_txp,
    input wire sfp_mod_abs,
    
    // HV ctrl
    inout wire hvplus_scl,
    inout wire hvplus_sda,
    inout wire hvminus_scl,
    inout wire hvminus_sda,
    
    // UART
    input wire uart_rx,
    output wire uart_tx,
    
    // ADC -- Low speed interface
    input wire jesd_coreclkn,
    input wire jesd_coreclkp,
    
    output wire adc0_rst,
    inout wire adc0_sclk,
    inout wire adc0_mosi,
    inout wire adc0_miso,
    output wire adc0_cs,
    
    output wire adc1_rst,
    inout wire adc1_sclk,
    inout wire adc1_mosi,
    inout wire adc1_miso,
    output wire adc1_cs,
   
    output wire adc0_syncn,
    output wire adc0_syncp,
    
    output wire adc1_syncn,
    output wire adc1_syncp,
    
    // ADC -- JESD204B interface
    input wire jesd_refclkn,
    input wire jesd_refclkp,
    
    input wire adc0_dan,
    input wire adc0_dap,
    input wire adc0_ddn,
    input wire adc0_ddp,
    
    input wire adc1_dan,
    input wire adc1_dap,
    input wire adc1_ddn,
    input wire adc1_ddp,
    
    // CLK ctrl
    inout wire clk_sda,
    inout wire clk_scl,
    
    // mux interface
    output wire mux_le,
    output wire mux_clk,
    output wire mux_clr,
    output wire mux_din,
    output wire mux_aux0,
    output wire mux_aux1,
    output wire mux_aux2,
    
    // leds/test
    output wire [1:0] usrled,
    inout wire [6:0] test
);

wire [1:0] adc_sync;

wire syncoverride;

OBUFDS adc0_sync_buf (
    .I(~(adc_sync[0] | syncoverride)), // polarity swapped on board
    .O(adc0_syncp),
    .OB(adc0_syncn)
);


OBUFDS adc1_sync_buf (
    .I(~(adc_sync[1] | syncoverride)), // polarity swapped on board
    .O(adc1_syncp),
    .OB(adc1_syncn)
);

wire mhz10;
    
bd_wrapper bd (
    .eth_refclk_clk_n(eth_refclkn),
    .eth_refclk_clk_p(eth_refclkp),
    .jesd_coreclk_clk_n(jesd_coreclkn),
    .jesd_coreclk_clk_p(jesd_coreclkp),
    .jesd_refclk_clk_n(jesd_refclkn),
    .jesd_refclk_clk_p(jesd_refclkp),
    .jesd_rxn('{adc1_dan, adc1_ddn, adc0_dan, adc0_ddn}),
    .jesd_rxp('{adc1_dap, adc1_ddp, adc0_dap, adc0_ddp}),
//    .jesd_rxn('{adc0_dan, adc0_ddn}),
//    .jesd_rxp('{adc0_dap, adc0_ddp}),
    .osc_200mhz_clk_n(osc200mhz_n),
    .osc_200mhz_clk_p(osc200mhz_p),
    .sfp_rx_gt_port_0_n(sfp_rdn),
    .sfp_rx_gt_port_0_p(sfp_rdp),
    .sfp_tx_gt_port_1_n(sfp_txn),
    .sfp_tx_gt_port_1_p(sfp_txp),
    .sfp_mod_abs(sfp_mod_abs),
    .led(usrled),
    .i2c_clk_sda_io(clk_sda),
    .i2c_clk_scl_io(clk_scl),
    .i2c_hvminus_scl_io(hvminus_scl),
    .i2c_hvminus_sda_io(hvminus_sda),
    .i2c_hvplus_scl_io(hvplus_scl),
    .i2c_hvplus_sda_io(hvplus_sda),
    .i2c_ramp_scl_io(ramp_scl),
    .i2c_ramp_sda_io(ramp_sda),
    .i2c_sfp_scl_io(sfp_scl),
    .i2c_sfp_sda_io(sfp_sda),
    .ramp_rst(ramp_rst),
    .pulser_neg_0({pulser0_neg, pulser1_neg}),
    .pulser_pos_0({pulser0_pos, pulser1_pos}),
    .pulser_oen_0(pulser_oen),
    
    .spi_adc0_io0_io(adc0_mosi),
    .spi_adc0_io1_io(adc0_miso),
    .spi_adc0_sck_io(adc0_sclk),
    .spi_adc0_ss_io(adc0_cs),
    
    .spi_adc1_io0_io(adc1_mosi),
    .spi_adc1_io1_io(adc1_miso),
    .spi_adc1_sck_io(adc1_sclk),
    .spi_adc1_ss_io(adc1_cs),
    
    .adc_sync(adc_sync),
    
    .adc_rst('{adc1_rst, adc0_rst}),
    
    .syncoverride(syncoverride),
    
    .mhz10(mhz10)
);
    
    
endmodule
