`timescale 1ns / 1ps

typedef enum logic [1:0] {
	IDLE,
    PENDING,
    HDR_SENT
} state_t;

// Generates one hdr_valid pulse per packet for udp_arb_mux, and gates the
// payload stream so no beat reaches the mux before the header handshake
// completes. Without the gate the mux asserts payload tready one cycle
// before its hdr_ready pulse, so a short packet's tlast can transfer in the
// same cycle as the mux's start-of-frame; the mux frame state sticks open,
// the still-asserted hdr_valid re-requests the arbiter, and the next packet
// is muxed out without a header.
module udp_hdr_valid_gen(
    input logic clk,
    input logic rst,

    // payload stream from the source
    input logic s_axis_tvalid,
    output logic s_axis_tready,
    input logic s_axis_tlast,

    // payload stream to the mux (tdata/tkeep/tlast pass through outside)
    output logic m_axis_tvalid,
    input logic m_axis_tready,

    input logic hdr_ready,
    output logic hdr_valid
);
    state_t state;

    assign hdr_valid = state == PENDING;

    assign m_axis_tvalid = s_axis_tvalid & (state == HDR_SENT);
    assign s_axis_tready = m_axis_tready & (state == HDR_SENT);

    always_ff @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
        end else begin
            case (state)
                IDLE: begin
                    if (s_axis_tvalid) begin
                        state <= PENDING;
                    end
                end
                PENDING: begin
                    if (hdr_ready) begin
                        state <= HDR_SENT;
                    end
                end
                HDR_SENT: begin
                    if (s_axis_tready & s_axis_tlast & s_axis_tvalid) begin
                        state <= IDLE;
                    end
                end
                default: state <= IDLE;
            endcase
        end
    end


endmodule
