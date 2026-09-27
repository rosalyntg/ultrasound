`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/20/2026 06:46:53 AM
// Design Name: 
// Module Name: adc_data_framing
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


module adc_data_framing #(
    parameter FRAMES_PER_PACKET = 160,
    parameter IN_WIDTH = 64
) (
    input wire aclk,
    input wire aresetn,

    output reg [IN_WIDTH-1:0] m_axis_tdata,
    input wire m_axis_tready,
    output reg m_axis_tlast,
    output reg m_axis_tvalid,

    input wire [IN_WIDTH-1:0] s_axis_tdata,
    output wire s_axis_tready,
    input wire s_axis_tvalid,

    input us_sol,
    input us_eol,
    input us_sof
);

reg [IN_WIDTH-1:0] next_m_axis_tdata;
reg next_m_axis_tvalid;
reg next_m_axis_tlast;

reg [IN_WIDTH-1:0] reg_data, next_reg_data;
reg reg_data_valid, next_reg_data_valid;

reg [$clog2(FRAMES_PER_PACKET)-1:0] last_ctr, next_last_ctr;
reg [1:0] state, next_state;

localparam STATE_IDLE = 0;
localparam STATE_HDR = 1;
localparam STATE_STREAMING = 2;

always @(posedge aclk) begin
    if (!aresetn) begin
        last_ctr <= FRAMES_PER_PACKET - 2;
        state <= STATE_IDLE;
        m_axis_tvalid <= 0;
        reg_data_valid <= 0;
    end else begin
        last_ctr <= next_last_ctr;
        state <= next_state;
        m_axis_tdata <= next_m_axis_tdata;
        m_axis_tvalid <= next_m_axis_tvalid;
        m_axis_tlast <= next_m_axis_tlast;
        reg_data <= next_reg_data;
        reg_data_valid <= next_reg_data_valid;
    end
end

always @* begin
    next_last_ctr = last_ctr;
    next_state = state;
    next_m_axis_tdata = m_axis_tdata;
    next_m_axis_tvalid = m_axis_tvalid;
    next_m_axis_tlast = m_axis_tlast;
    next_reg_data = reg_data;
    next_reg_data_valid = reg_data_valid;
    
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
                next_s_axis_tready = 0;
            end
        end 
        STATE_HDR: begin
            if (m_axis_tready) begin
                next_m_axis_tvalid = 0;
                next_m_axis_tdata = 64'hx;
                next_m_axis_tlast = 1'bx;
                next_s_axis_tready = 1;
                next_state = STATE_STREAMING;
            end
        end
        STATE_STREAMING: begin       
            if (m_axis_tvalid & m_axis_tready) begin
                next_m_axis_tvalid = 0;
                next_m_axis_tlast = 1'b0;
                next_m_axis_tdata = 64'bx;

                if (m_axis_tlast) begin
                    next_state = STATE_HDR;
                    next_m_axis_tdata = 0;
                    next_m_axis_tvalid = 1;
                    next_s_axis_tready = 0;
                end

                if (last_ctr == 0) begin
                    next_last_ctr = FRAMES_PER_PACKET - 2;
                    next_m_axis_tlast = 1;
                end else if (last_ctr == 0) begin
                    next_last_ctr = 0;
                end else begin
                    next_last_ctr = last_ctr - 1;
                end
            end
            if (reg_data_valid & ~next_m_axis_tvalid) begin
                next_m_axis_tvalid = 1;
                next_m_axis_tdata = reg_data;
                next_reg_data = 64'hx;
                next_reg_data_valid = 0;
            end
            if (s_axis_tvalid & s_axis_tready) begin
                next_reg_data = s_axis_tdata;
                next_reg_data_valid = 1;
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
