localparam REG_OFFSET_STATE = 0; // write 1 to arm, write 2 to start, read to get state, write 0 to disarm
localparam REG_OFFSET_PULSE_WIDTH_POS = 1;
localparam REG_OFFSET_PULSE_WIDTH_RTZ = 2;
localparam REG_OFFSET_PULSE_WIDTH_NEG = 3;
localparam REG_OFFSET_PULSE_WIDTH_DELAYRAMP = 4;
localparam REG_OFFSET_PULSE_WIDTH_RECV = 5;
localparam REG_OFFSET_PULSE_WIDTH_IDLE = 6;
localparam REG_OFFSET_NUM_SCANLINES = 7;


localparam CHANNELS = 8;
localparam MAX_SCANLINES = 256;
localparam BYTES_PER_DELAY = 2;

localparam REG_OFFSET_TABLE = MAX_SCANLINES;

localparam ADDR_BITS_SCANLINES = $clog2(MAX_SCANLINES);
localparam ADDR_BITS_CHANNELS = $clog2(CHANNELS);

// 1 word per delay, even if backing storage is not 32-bit
localparam TABLE_LEN_WORDS = MAX_SCANLINES  * CHANNELS;


module pulse_gen # (
    parameter integer C_S_AXI_DATA_WIDTH	= 32,
    parameter integer C_S_AXI_ADDR_WIDTH	= 14
)(
    input logic aclk,
    input logic aresetn,

    output logic [7:0] pulser_neg,
    output logic [7:0] pulser_pos,
    output logic pulser_oen,
    output logic ramp_rst,

    output logic sol_pulse,
    output logic eol_pulse,
    output logic sof_pulse,

    // Ports of Axi Slave Bus Interface S_AXI
    input logic [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
    input logic [2 : 0] S_AXI_AWPROT,
    input logic  S_AXI_AWVALID,
    output logic  S_AXI_AWREADY,
    input logic [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA,
    input logic [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
    input logic  S_AXI_WVALID,
    output logic  S_AXI_WREADY,
    output logic [1 : 0] S_AXI_BRESP,
    output logic  S_AXI_BVALID,
    input logic  S_AXI_BREADY,
    input logic [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
    input logic [2 : 0] S_AXI_ARPROT,
    input logic  S_AXI_ARVALID,
    output logic  S_AXI_ARREADY,
    output logic [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA,
    output logic [1 : 0] S_AXI_RRESP,
    output logic  S_AXI_RVALID,
    input logic  S_AXI_RREADY
);

typedef enum logic [2:0] {
    IDLE,
    ARMED,
    TRIGGER, // dummy state so all table read ops happen at the same place
    PULSING,
    DELAYRAMP, // recv, but ramp not started yet
    RECV,
    WAIT_FOR_NEXT_LINE // don't send next pulse yet, waiting for stuff to quiet down
} state_t;

typedef enum logic [2:0] {
    CH_DELAY,
    CH_POS,
    CH_RTZ,
    CH_NEG,
    CH_RECV
} channel_state_t;

    // AXI4LITE signals
    reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_awaddr;
    reg  	axi_awready;
    reg  	axi_wready;
    reg [1 : 0] 	axi_bresp;
    reg  	axi_bvalid;
    reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_araddr;
    reg  	axi_arready;
    reg [1 : 0] 	axi_rresp;
    reg  	axi_rvalid;

    // Example-specific design signals
    // local parameter for addressing 32 bit / 64 bit C_S_AXI_DATA_WIDTH
    // ADDR_LSB is used for addressing 32/64 bit registers/memories
    // ADDR_LSB = 2 for 32 bits (n downto 2)
    // ADDR_LSB = 3 for 64 bits (n downto 3)
    localparam integer ADDR_LSB = (C_S_AXI_DATA_WIDTH/32) + 1;
    localparam integer OPT_MEM_ADDR_BITS = 11;
    //----------------------------------------------
    //-- Signals for user logic register space example
    //------------------------------------------------
    //-- Number of Slave Registers 4

    state_t state;
    channel_state_t ch_state [CHANNELS-1:0];
    logic [15:0] pulse_width_pos;
    logic [15:0] pulse_width_rtz;
    logic [15:0] pulse_width_neg;
    logic [15:0] pulse_width_delayramp;
    logic [31:0] pulse_width_recv;
    logic [31:0] pulse_width_idle;
    logic [15:0] num_scanlines;

    logic [15:0] scanline_idx;
    logic [31:0] state_counter;
    logic [15:0] ch_counter [CHANNELS-1:0];

    assign pulser_oen = state != IDLE;

    reg [BYTES_PER_DELAY*8-1:0] pulse_delay_data [CHANNELS-1:0] [MAX_SCANLINES-1:0];
    integer ch;
    integer sl;
    initial begin
        for (ch = 0; ch < CHANNELS; ch = ch + 1) begin
            for (int sl = 0; sl < MAX_SCANLINES; sl = sl + 1) begin
                pulse_delay_data[ch][sl] = '0;
            end
        end
    end

    always_comb begin
        for (ch = 0; ch < CHANNELS; ch = ch + 1) begin
            // pos+neg means recv
            if (state == PULSING) begin
                pulser_pos[ch] = (ch_state[ch] == CH_POS) | (ch_state[ch] == CH_RECV);
                pulser_neg[ch] = (ch_state[ch] == CH_NEG) | (ch_state[ch] == CH_RECV);
            end else if (state == DELAYRAMP || state == RECV) begin
                // recv
                pulser_pos[ch] = 1'b1;
                pulser_neg[ch] = 1'b1;
            end else begin
                // rtz
                pulser_pos[ch] = 1'b0;
                pulser_neg[ch] = 1'b0;
            end
        end
    end
    assign ramp_rst = (state == RECV) ? 1'b0 : 1'b1;

    integer	 byte_index;

    // I/O Connections assignments

    assign S_AXI_AWREADY	= axi_awready;
    assign S_AXI_WREADY	= axi_wready;
    assign S_AXI_BRESP	= axi_bresp;
    assign S_AXI_BVALID	= axi_bvalid;
    assign S_AXI_ARREADY	= axi_arready;
    assign S_AXI_RRESP	= axi_rresp;
    assign S_AXI_RVALID	= axi_rvalid;
     //state machine varibles
     reg [1:0] state_write;
     reg [1:0] state_read;
     //State machine local parameters
     localparam Idle = 2'b00,Raddr = 2'b10,Rdata = 2'b11 ,Waddr = 2'b10,Wdata = 2'b11;
    // Implement Write state machine
    // Outstanding write transactions are not supported by the slave i.e., master should assert bready to receive response on or before it starts sending the new transaction
    always_ff @(posedge aclk)
      begin
         if (aresetn == 1'b0)
           begin
             axi_awready <= 0;
             axi_wready <= 0;
             axi_bvalid <= 0;
             axi_bresp <= 0;
             axi_awaddr <= 0;
             state_write <= Idle;
           end
         else
           begin
             case(state_write)
               Idle:
                 begin
                   if(aresetn == 1'b1)
                     begin
                       axi_awready <= 1'b1;
                       axi_wready <= 1'b1;
                       state_write <= Waddr;
                     end
                   else state_write <= state_write;
                 end
               Waddr:        //At this state, slave is ready to receive address along with corresponding control signals and first data packet. Response valid is also handled at this state
                 begin
                   if (S_AXI_AWVALID && S_AXI_AWREADY)
                      begin
                        axi_awaddr <= S_AXI_AWADDR;
                        if(S_AXI_WVALID)
                          begin
                            axi_awready <= 1'b1;
                            state_write <= Waddr;
                            axi_bvalid <= 1'b1;
                          end
                        else
                          begin
                            axi_awready <= 1'b0;
                            state_write <= Wdata;
                            if (S_AXI_BREADY && axi_bvalid) axi_bvalid <= 1'b0;
                          end
                      end
                   else
                      begin
                        state_write <= state_write;
                        if (S_AXI_BREADY && axi_bvalid) axi_bvalid <= 1'b0;
                       end
                 end
              Wdata:        //At this state, slave is ready to receive the data packets until the number of transfers is equal to burst length
                 begin
                   if (S_AXI_WVALID)
                     begin
                       state_write <= Waddr;
                       axi_bvalid <= 1'b1;
                       axi_awready <= 1'b1;
                     end
                    else
                     begin
                       state_write <= state_write;
                       if (S_AXI_BREADY && axi_bvalid) axi_bvalid <= 1'b0;
                     end
                 end
              endcase
            end
          end

    // Implement memory mapped register select and write logic generation
    // The write data is accepted and written to memory mapped registers when
    // axi_awready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted. Write strobes are used to
    // select byte enables of slave registers while writing.
    // These registers are cleared when reset (active low) is applied.
    // Slave register write enable is asserted when valid address and data are available
    // and the slave is ready to accept the write address and write data.

    logic [C_S_AXI_ADDR_WIDTH-ADDR_LSB:0] effective_addr;
    logic all_channel_done;

    always_ff @( posedge aclk )
    begin
      if ( aresetn == 1'b0 )
        begin
            state <= IDLE;
            pulse_width_pos <= 0;
            pulse_width_rtz <= 0;
            pulse_width_neg <= 0;
            pulse_width_delayramp <= 0;
            pulse_width_recv <= 0;
            pulse_width_idle <= 0;
            num_scanlines <= 256;

            scanline_idx <= 0;
        end
      else begin
        if (S_AXI_WVALID)
          begin
            effective_addr = (S_AXI_AWVALID) ? S_AXI_AWADDR[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] : axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB];
            case ( effective_addr )
              11'h0:
                // for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                  if ( S_AXI_WSTRB[0] == 1 ) begin
                    // Respective byte enables are asserted as per write strobes
                    if (state == IDLE && S_AXI_WDATA[(0*8) +: 8] == 1) begin
                        state <= ARMED;
                    end else if (state == ARMED && S_AXI_WDATA[(0*8) +: 8] == 2) begin
                        state <= TRIGGER;
                    end else if (S_AXI_WDATA[(0*8) +: 8] == 0) begin
                        state <= IDLE;
                    end
                  end
              11'h1:
                for ( byte_index = 0; byte_index <= 1; byte_index = byte_index+1 )
                  if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                    // Respective byte enables are asserted as per write strobes
                    pulse_width_pos[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                  end
              11'h2:
                for ( byte_index = 0; byte_index <= 1; byte_index = byte_index+1 )
                  if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                    // Respective byte enables are asserted as per write strobes
                    pulse_width_rtz[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                  end
              11'h3:
                for ( byte_index = 0; byte_index <= 1; byte_index = byte_index+1 )
                  if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                    // Respective byte enables are asserted as per write strobes
                    pulse_width_neg[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                  end
              11'h4:
                for ( byte_index = 0; byte_index <= 1; byte_index = byte_index+1 )
                  if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                    // Respective byte enables are asserted as per write strobes
                    pulse_width_delayramp[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                  end
              11'h5:
                for ( byte_index = 0; byte_index <= 3; byte_index = byte_index+1 )
                  if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                    // Respective byte enables are asserted as per write strobes
                    pulse_width_recv[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                  end
              11'h6:
                for ( byte_index = 0; byte_index <= 3; byte_index = byte_index+1 )
                  if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                    // Respective byte enables are asserted as per write strobes
                    pulse_width_idle[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                  end
              11'h7:
                for ( byte_index = 0; byte_index <= 1; byte_index = byte_index+1 )
                  if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                    // Respective byte enables are asserted as per write strobes
                    num_scanlines[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                  end
              default : begin
                // handle table writes
                if (effective_addr >= REG_OFFSET_TABLE && effective_addr < REG_OFFSET_TABLE+TABLE_LEN_WORDS) begin
                    for ( byte_index = 0; byte_index < BYTES_PER_DELAY; byte_index = byte_index+1 ) begin
                        if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                            pulse_delay_data
                                [effective_addr[ADDR_BITS_SCANLINES+ADDR_BITS_CHANNELS-1:ADDR_BITS_SCANLINES]- 1] // - 1 because first block is "normal" regs
                                [effective_addr[ADDR_BITS_SCANLINES-1:0]]
                                [(byte_index*8) +: 8]
                                <= S_AXI_WDATA[(byte_index*8) +: 8];
                        end
                    end
                end else begin
                    state <= state;
                    pulse_width_pos <= pulse_width_pos;
                    pulse_width_rtz <= pulse_width_rtz;
                    pulse_width_neg <= pulse_width_neg;
                    pulse_width_delayramp <= pulse_width_delayramp;
                    pulse_width_recv <= pulse_width_recv;
                    pulse_width_idle <= pulse_width_idle;
                    num_scanlines <= num_scanlines;
                end
              end
            endcase
          end

        sol_pulse <= 0;
        eol_pulse <= 0;
        sof_pulse <= 0;
        case (state)
            IDLE: begin
            end
            ARMED: begin
            end
            TRIGGER: begin
                for (ch = 0; ch < CHANNELS; ch = ch + 1) begin
                    if (pulse_delay_data[ch][scanline_idx] == '1) begin  // if all 1's, skip pulse on this channel entirely
                      ch_state[ch] <= CH_RECV;
                    end else begin
                      ch_counter[ch] <= pulse_delay_data[ch][scanline_idx];
                      ch_state[ch] <= CH_DELAY;
                    end
                end
                state <= PULSING;
                if (scanline_idx == 0)
                    sof_pulse <= 1;
                else
                    sol_pulse <= 1;
            end
            PULSING: begin
                all_channel_done = 1'b1;
                for (ch = 0; ch < CHANNELS; ch = ch + 1) begin
                    if (ch_state[ch] != CH_RECV) begin
                        all_channel_done = 1'b0;
                    end
                end
                if (all_channel_done) begin
                    state <= DELAYRAMP;
                    state_counter <= pulse_width_delayramp;
                end
            end
            DELAYRAMP: begin
                if (state_counter == 0) begin
                    state <= RECV;
                    state_counter <= pulse_width_recv;
                end else begin
                    state_counter <= state_counter - 1;
                end
            end
            RECV: begin
                if (state_counter == 0) begin
                    state <= WAIT_FOR_NEXT_LINE;
                    state_counter <= pulse_width_idle;
                    eol_pulse <= 1;

                    if (scanline_idx >= num_scanlines - 1)
                        scanline_idx <= 0;
                    else
                        scanline_idx <= scanline_idx + 1;
                end else begin
                    state_counter <= state_counter - 1;
                end
            end
            WAIT_FOR_NEXT_LINE: begin
                if (state_counter == 0) begin
                    state <= TRIGGER;
                end else begin
                    state_counter <= state_counter - 1;
                end
            end
            default: begin
                state <= IDLE;
            end
        endcase
        for (ch = 0; ch < CHANNELS; ch = ch + 1) begin
            case (ch_state[ch])
                CH_DELAY: begin
                    if (ch_counter[ch] == 0) begin
                        ch_state[ch] <= CH_POS;
                        ch_counter[ch] <= pulse_width_pos;
                    end else begin
                        ch_counter[ch] <= ch_counter[ch] - 1;
                    end
                end
                CH_POS: begin
                    if (ch_counter[ch] == 0) begin
                        ch_state[ch] <= CH_RTZ;
                        ch_counter[ch] <= pulse_width_rtz;
                    end else begin
                        ch_counter[ch] <= ch_counter[ch] - 1;
                    end
                end
                CH_RTZ: begin
                    if (ch_counter[ch] == 0) begin
                        ch_state[ch] <= CH_NEG;
                        ch_counter[ch] <= pulse_width_neg;
                    end else begin
                        ch_counter[ch] <= ch_counter[ch] - 1;
                    end
                end
                CH_NEG: begin
                    if (ch_counter[ch] == 0) begin
                        ch_state[ch] <= CH_RECV;
                    end else begin
                        ch_counter[ch] <= ch_counter[ch] - 1;
                    end
                end
                CH_RECV: begin
                end
                default: begin
                    ch_state[ch] <= CH_RECV;
                end
            endcase
        end
      end
    end

    // Implement read state machine
      always_ff @(posedge aclk)
        begin
          if (aresetn == 1'b0)
            begin
             //asserting initial values to all 0's during reset
             axi_arready <= 1'b0;
             axi_rvalid <= 1'b0;
             axi_rresp <= 1'b0;
             state_read <= Idle;
            end
          else
            begin
              case(state_read)
                Idle:     //Initial state inidicating reset is done and ready to receive read/write transactions
                  begin
                    if (aresetn == 1'b1)
                      begin
                        state_read <= Raddr;
                        axi_arready <= 1'b1;
                      end
                    else state_read <= state_read;
                  end
                Raddr:        //At this state, slave is ready to receive address along with corresponding control signals
                  begin
                    if (S_AXI_ARVALID && S_AXI_ARREADY)
                      begin
                        state_read <= Rdata;
                        axi_araddr <= S_AXI_ARADDR;
                        axi_rvalid <= 1'b1;
                        axi_arready <= 1'b0;
                      end
                    else state_read <= state_read;
                  end
                Rdata:        //At this state, slave is ready to send the data packets until the number of transfers is equal to burst length
                  begin
                    if (S_AXI_RVALID && S_AXI_RREADY)
                      begin
                        axi_rvalid <= 1'b0;
                        axi_arready <= 1'b1;
                        state_read <= Raddr;
                      end
                    else state_read <= state_read;
                  end
               endcase
              end
            end
    // Implement memory mapped register select and read logic generation
      logic [OPT_MEM_ADDR_BITS-1:0] rd_effective_addr;
      always_comb begin
        S_AXI_RDATA = 0;
        rd_effective_addr = axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB];
        case (rd_effective_addr)
            REG_OFFSET_STATE:                S_AXI_RDATA = {29'b0, state};
           REG_OFFSET_PULSE_WIDTH_POS:       S_AXI_RDATA = pulse_width_pos;
           REG_OFFSET_PULSE_WIDTH_RTZ:       S_AXI_RDATA = pulse_width_rtz;
           REG_OFFSET_PULSE_WIDTH_NEG:       S_AXI_RDATA = pulse_width_neg;
           REG_OFFSET_PULSE_WIDTH_DELAYRAMP: S_AXI_RDATA = pulse_width_delayramp;
           REG_OFFSET_PULSE_WIDTH_RECV:      S_AXI_RDATA = pulse_width_recv;
           REG_OFFSET_PULSE_WIDTH_IDLE:      S_AXI_RDATA = pulse_width_idle;
           REG_OFFSET_NUM_SCANLINES:         S_AXI_RDATA = num_scanlines;
        endcase
      end
    // Add user logic here


    // User logic ends

endmodule
