`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/16/2026 07:08:38 PM
// Design Name: 
// Module Name: pulse_sync
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


module pulse_sync (
    input in_clk,
    input wire in_pulse,
    
    input out_clk,
    output reg out_pulse
);

reg level = 0;
wire level_outclk;
reg last_level_outclk = 0;
    
xpm_cdc_single #(
    .DEST_SYNC_FF(4),
    .INIT_SYNC_FF(1),
    .SRC_INPUT_REG(0),
    .SIM_ASSERT_CHK(1)     // optional: warns on CDC violations in sim   
) sync_req (
    .src_clk(in_clk),
    .dest_clk(out_clk),
    .src_in(level),
    .dest_out(level_outclk)
);

always @(posedge in_clk) begin
    if (in_pulse) begin
        level <= ~level;
    end
end


always @(posedge out_clk) begin
    out_pulse <= 0;
    last_level_outclk <= level_outclk;
    if (last_level_outclk != level_outclk) begin
        out_pulse <= 1;
    end
end
    
endmodule
