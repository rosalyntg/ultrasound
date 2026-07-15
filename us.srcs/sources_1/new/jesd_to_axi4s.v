`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/15/2026 01:40:50 AM
// Design Name: 
// Module Name: jesd_to_axi4s
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

module jesd_to_axi4s #(
    parameter FRAMES_PER_PACKET = 160
) (
    input wire aclk,
    input wire aresetn,

    output wire [63:0] m_axis_tdata,
    input wire m_axis_tready,
    output wire m_axis_tlast,
    output wire [7:0] m_axis_tkeep,
    output wire m_axis_tvalid,

    output reg [31:0] dropped_packets,
    
    input [7:0] skip,
    
    input [63:0] rx_data,
    input rx_valid,

    input [3:0] rx_eof,
    input [3:0] rx_sof
);

assign m_axis_tdata = rx_data;
assign m_axis_tkeep = 8'hff;

reg [$clog2(FRAMES_PER_PACKET)-1:0] last_ctr;
reg [7:0] skip_ctr;

assign m_axis_tlast  = last_ctr == 0;
assign m_axis_tvalid = (skip_ctr == 0) & rx_valid;

always @(posedge aclk) begin
    if (!aresetn) begin
        dropped_packets <= 0;
        last_ctr <= FRAMES_PER_PACKET - 1;
        skip_ctr <= skip;
    end else begin
        if (rx_valid && ~m_axis_tready) begin
            dropped_packets <= dropped_packets + 1;
        end
        if (m_axis_tvalid) begin
            if (last_ctr == 0 && m_axis_tready)
                last_ctr <= FRAMES_PER_PACKET - 1;
            else if (last_ctr == 0)
                last_ctr <= 0;
            else
                last_ctr <= last_ctr - 1;
        end
        
        
        if (skip_ctr == 0)
            skip_ctr <= skip;
        else 
            skip_ctr <= skip_ctr - 1;
        
    end
end


endmodule
