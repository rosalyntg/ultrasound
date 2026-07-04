//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//Copyright 2022-2026 Advanced Micro Devices, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2025.2.1 (lin64) Build 6403652 Thu Mar 19 13:47:00 MDT 2026
//Date        : Fri Jul  3 18:44:00 2026
//Host        : russell-shotover-arch running 64-bit Ubuntu 22.04.5 LTS
//Command     : generate_target bd_wrapper.bd
//Design      : bd_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module bd_wrapper
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
    sfp_i2c_scl_io,
    sfp_i2c_sda_io,
    sfp_mod_abs,
    sfp_rx_gt_port_0_n,
    sfp_rx_gt_port_0_p,
    sfp_tx_gt_port_0_n,
    sfp_tx_gt_port_0_p);
  input eth_refclk_clk_n;
  input eth_refclk_clk_p;
  input [0:0]jesd_coreclk_clk_n;
  input [0:0]jesd_coreclk_clk_p;
  input [0:0]jesd_refclk_clk_n;
  input [0:0]jesd_refclk_clk_p;
  input [3:0]jesd_rxn;
  input [3:0]jesd_rxp;
  output [1:0]led;
  input osc_200mhz_clk_n;
  input osc_200mhz_clk_p;
  inout sfp_i2c_scl_io;
  inout sfp_i2c_sda_io;
  input [0:0]sfp_mod_abs;
  input sfp_rx_gt_port_0_n;
  input sfp_rx_gt_port_0_p;
  output sfp_tx_gt_port_0_n;
  output sfp_tx_gt_port_0_p;

  wire eth_refclk_clk_n;
  wire eth_refclk_clk_p;
  wire [0:0]jesd_coreclk_clk_n;
  wire [0:0]jesd_coreclk_clk_p;
  wire [0:0]jesd_refclk_clk_n;
  wire [0:0]jesd_refclk_clk_p;
  wire [3:0]jesd_rxn;
  wire [3:0]jesd_rxp;
  wire [1:0]led;
  wire osc_200mhz_clk_n;
  wire osc_200mhz_clk_p;
  wire sfp_i2c_scl_i;
  wire sfp_i2c_scl_io;
  wire sfp_i2c_scl_o;
  wire sfp_i2c_scl_t;
  wire sfp_i2c_sda_i;
  wire sfp_i2c_sda_io;
  wire sfp_i2c_sda_o;
  wire sfp_i2c_sda_t;
  wire [0:0]sfp_mod_abs;
  wire sfp_rx_gt_port_0_n;
  wire sfp_rx_gt_port_0_p;
  wire sfp_tx_gt_port_0_n;
  wire sfp_tx_gt_port_0_p;

  bd bd_i
       (.eth_refclk_clk_n(eth_refclk_clk_n),
        .eth_refclk_clk_p(eth_refclk_clk_p),
        .jesd_coreclk_clk_n(jesd_coreclk_clk_n),
        .jesd_coreclk_clk_p(jesd_coreclk_clk_p),
        .jesd_refclk_clk_n(jesd_refclk_clk_n),
        .jesd_refclk_clk_p(jesd_refclk_clk_p),
        .jesd_rxn(jesd_rxn),
        .jesd_rxp(jesd_rxp),
        .led(led),
        .osc_200mhz_clk_n(osc_200mhz_clk_n),
        .osc_200mhz_clk_p(osc_200mhz_clk_p),
        .sfp_i2c_scl_i(sfp_i2c_scl_i),
        .sfp_i2c_scl_o(sfp_i2c_scl_o),
        .sfp_i2c_scl_t(sfp_i2c_scl_t),
        .sfp_i2c_sda_i(sfp_i2c_sda_i),
        .sfp_i2c_sda_o(sfp_i2c_sda_o),
        .sfp_i2c_sda_t(sfp_i2c_sda_t),
        .sfp_mod_abs(sfp_mod_abs),
        .sfp_rx_gt_port_0_n(sfp_rx_gt_port_0_n),
        .sfp_rx_gt_port_0_p(sfp_rx_gt_port_0_p),
        .sfp_tx_gt_port_0_n(sfp_tx_gt_port_0_n),
        .sfp_tx_gt_port_0_p(sfp_tx_gt_port_0_p));
  IOBUF sfp_i2c_scl_iobuf
       (.I(sfp_i2c_scl_o),
        .IO(sfp_i2c_scl_io),
        .O(sfp_i2c_scl_i),
        .T(sfp_i2c_scl_t));
  IOBUF sfp_i2c_sda_iobuf
       (.I(sfp_i2c_sda_o),
        .IO(sfp_i2c_sda_io),
        .O(sfp_i2c_sda_i),
        .T(sfp_i2c_sda_t));
endmodule
