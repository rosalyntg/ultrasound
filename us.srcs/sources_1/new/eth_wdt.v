`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/14/2026 05:59:34 AM
// Design Name: 
// Module Name: eth_wdt
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


module eth_wdt(
    input dclk,
    
   (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_HIGH" *)
    input user_rx_reset,
    input tx_reset_done,
    
   (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_HIGH" *)
    output reset_rx_datapath
);
    
    wire rx_reset_done_sync;
    wire rx_reset_done_sync;
    
    
    localparam [28:0] MASTER_WATCHDOG_TIMER_RESET = (750000000 / (1000 / 25.00));
    
    reg [28:0] ctr = MASTER_WATCHDOG_TIMER_RESET;
    
    always @(posedge dclk) begin
        if ((tx_reset_done && ~user_rx_reset) || ctr == 0) begin
            ctr <= MASTER_WATCHDOG_TIMER_RESET;
        end else begin
            ctr <= ctr - 1;
        end
    end
    
    assign reset_rx_datapath = ctr <= 50;

endmodule
