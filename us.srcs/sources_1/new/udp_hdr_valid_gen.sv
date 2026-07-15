
typedef enum logic [1:0] {
	IDLE,
    PENDING,
    HDR_SENT
} state_t;

module udp_hdr_valid_gen(
    input logic clk,
    input logic rst,

    input logic axis_tvalid,
    input logic axis_tready,
    input logic axis_tlast,

    input logic hdr_ready,
    output logic hdr_valid
);
    state_t state;
    
    assign hdr_valid = state == PENDING;

    always_ff @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
        end else begin
            case (state)
                IDLE: begin
                    if (axis_tvalid) begin
                        state <= PENDING;
                    end
                end
                PENDING: begin
                    if (hdr_ready) begin
                        if (axis_tready & axis_tlast & axis_tvalid)
                            state <= IDLE;
                        else
                            state <= HDR_SENT;
                    end
                end
                HDR_SENT: begin
                    if (axis_tready & axis_tlast & axis_tvalid) begin
                        state <= IDLE;
                    end
                end
            endcase
        end
    end


endmodule