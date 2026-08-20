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
    parameter IN_WIDTH = 128,
    parameter FRAMES_PER_PACKET = 160
) (
    input wire aclk,
    input wire aresetn,

    output reg [IN_WIDTH-1:0] m_axis_tdata,
    input wire m_axis_tready,
    output reg m_axis_tlast,
    output reg m_axis_tvalid,

    output reg [31:0] dropped_packets,
    
    input [7:0] skip,
    
    input [IN_WIDTH-1:0] rx_data,
    input rx_valid,
    
    input us_sol,
    input us_eol,
    input us_sof
);

assign m_axis_tkeep = 8'hff;

reg [IN_WIDTH-1:0] next_m_axis_tdata;
reg next_m_axis_tvalid;
reg next_m_axis_tlast;

reg [$clog2(FRAMES_PER_PACKET)-1:0] last_ctr, next_last_ctr;
reg [7:0] skip_ctr, next_skip_ctr;

reg [1:0] state, next_state;
reg [31:0] next_dropped_packets;

localparam STATE_IDLE = 0;
localparam STATE_HDR = 1;
localparam STATE_STREAMING = 2;

always @(posedge aclk) begin
    if (!aresetn) begin
        dropped_packets <= 0;
        last_ctr <= FRAMES_PER_PACKET - 2;
        skip_ctr <= skip;
        state <= STATE_IDLE;
        m_axis_tvalid <= 0;
    end else begin
        dropped_packets <= next_dropped_packets;
        last_ctr <= next_last_ctr;
        skip_ctr <= next_skip_ctr;
        state <= next_state;
        m_axis_tdata <= next_m_axis_tdata;
        m_axis_tvalid <= next_m_axis_tvalid;
        m_axis_tlast <= next_m_axis_tlast;
        
    end
end

always @* begin
    next_dropped_packets = dropped_packets;
    next_last_ctr = last_ctr;
    next_skip_ctr = skip_ctr;
    next_state = state;
    next_m_axis_tdata = m_axis_tdata;
    next_m_axis_tvalid = m_axis_tvalid;
    next_m_axis_tlast = m_axis_tlast;
    
    case (state)
        STATE_IDLE: begin
            if (m_axis_tvalid & m_axis_tready) begin
                next_m_axis_tvalid = 0;
                next_m_axis_tlast = 1'bx;
                next_m_axis_tdata = 1'bx;
            end
            if (us_sol | us_sof) begin
                next_state = STATE_HDR;
                next_m_axis_tdata = {
                    120'b0,
                    us_sol,
                    us_sof,
                    6'b0
                };
                next_m_axis_tvalid = 1;
                next_m_axis_tlast = 0;
            end
        end 
        STATE_HDR: begin
            if (m_axis_tready) begin
                next_m_axis_tdata = rx_data;
                next_m_axis_tvalid = 1;
                next_state = STATE_STREAMING;
            end
        end
        STATE_STREAMING: begin       
            if (m_axis_tvalid && ~m_axis_tready) begin
                next_dropped_packets = dropped_packets + 1;
            end
            if (m_axis_tvalid) begin
                next_m_axis_tvalid = 0; 
                next_m_axis_tlast = 1'b0;
                next_m_axis_tdata = 1'bx;
                if (last_ctr == 0 && m_axis_tready) begin
                    next_last_ctr = FRAMES_PER_PACKET - 2;
                    next_m_axis_tlast = 1;
                end else if (last_ctr == 0) begin
                    next_last_ctr = 0;
                end else begin
                    next_last_ctr = last_ctr - 1;
                end
            end
            
            if (rx_valid) begin
                if (skip_ctr == 0) begin
                    next_skip_ctr = skip;
                    next_m_axis_tvalid = 1;
                    next_m_axis_tdata = rx_data;
                end else begin
                    next_skip_ctr = skip_ctr - 1;
                end
            end

            if (us_eol) begin
                next_state = STATE_IDLE;
                next_m_axis_tlast = 1;
                next_m_axis_tvalid = 1;
            end 
        end
    endcase
end


endmodule
