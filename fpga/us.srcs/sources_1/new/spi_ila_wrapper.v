`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/14/2026 05:01:56 PM
// Design Name: 
// Module Name: spi_ila_wrapper
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


module spi_ila_wrapper(
  input clk,

  (* X_INTERFACE_INFO = "xilinx.com:interface:spi:1.0 spi IO0_I" *) (* X_INTERFACE_MODE = "monitor" *) input spi_io0_i,
  (* X_INTERFACE_INFO = "xilinx.com:interface:spi:1.0 spi IO0_O" *) input spi_io0_o,
  (* X_INTERFACE_INFO = "xilinx.com:interface:spi:1.0 spi IO0_T" *) input spi_io0_t,
  (* X_INTERFACE_INFO = "xilinx.com:interface:spi:1.0 spi IO1_I" *) input spi_io1_i,
  (* X_INTERFACE_INFO = "xilinx.com:interface:spi:1.0 spi IO1_O" *) input spi_io1_o,
  (* X_INTERFACE_INFO = "xilinx.com:interface:spi:1.0 spi IO1_T" *) input spi_io1_t,
  (* X_INTERFACE_INFO = "xilinx.com:interface:spi:1.0 spi SCK_I" *) input spi_sck_i,
  (* X_INTERFACE_INFO = "xilinx.com:interface:spi:1.0 spi SCK_O" *) input spi_sck_o,
  (* X_INTERFACE_INFO = "xilinx.com:interface:spi:1.0 spi SCK_T" *) input spi_sck_t,
  (* X_INTERFACE_INFO = "xilinx.com:interface:spi:1.0 spi SS_I" *) input [0:0]spi_ss_i,
  (* X_INTERFACE_INFO = "xilinx.com:interface:spi:1.0 spi SS_O" *) input [0:0]spi_ss_o,
  (* X_INTERFACE_INFO = "xilinx.com:interface:spi:1.0 spi SS_T" *) input spi_ss_t
    );

ila_spi ila_inst (
  .clk(clk),
  .probe0(spi_io0_o),
  .probe1(spi_io0_t),
  .probe2(spi_io0_i),
  .probe3(spi_io1_o),
  .probe4(spi_io1_t),
  .probe5(spi_io1_i),
  .probe6(spi_sck_o),
  .probe7(spi_sck_t),
  .probe8(spi_sck_i),
  .probe9(spi_ss_o),
  .probe10(spi_ss_t),
  .probe11(spi_ss_i)
);

endmodule
