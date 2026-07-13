localparam REG_OFFSET_STATE = 0; // write 1 to arm, write 2 to start, read to get state, write 0 to disarm
localparam REG_OFFSET_PULSE_WIDTH_POS = 1;
localparam REG_OFFSET_PULSE_WIDTH_RTZ = 2;
localparam REG_OFFSET_PULSE_WIDTH_NEG = 3;
localparam REG_OFFSET_PULSE_WIDTH_DELAYRAMP = 4;
localparam REG_OFFSET_PULSE_WIDTH_RECV = 5;

typedef enum logic [2:0] {
	IDLE,
	ARMED,
	POS,
	RTZ,
	NEG,
	DELAYRAMP, // recv, but ramp not started yet
	RECV
} state_t;

module pulse_gen # (
    parameter integer C_S_AXI_DATA_WIDTH	= 32,
    parameter integer C_S_AXI_ADDR_WIDTH	= 6
)(
    input logic aclk,
    input logic aresetn,

    output logic [7:0] pulser_neg,
    output logic [7:0] pulser_pos,
    output logic pulser_oen,
	output logic ramp_rst,

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
	localparam integer OPT_MEM_ADDR_BITS = 3;
	//----------------------------------------------
	//-- Signals for user logic register space example
	//------------------------------------------------
	//-- Number of Slave Registers 4

	state_t state;
	logic [15:0] pulse_width_pos;
	logic [15:0] pulse_width_rtz;
	logic [15:0] pulse_width_neg;
	logic [15:0] pulse_width_delayramp;
	logic [15:0] pulse_width_recv;

	logic [15:0] counter;

	assign pulser_oen = state != IDLE;

	// pos+neg means recv
	assign pulser_pos = (state == POS || state == RECV || state == DELAYRAMP) ? 8'hFF : 8'h00;
	assign pulser_neg = (state == NEG || state == RECV || state == DELAYRAMP) ? 8'hFF : 8'h00;
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
	    end 
	  else begin
	    if (S_AXI_WVALID)
	      begin
	        case ( (S_AXI_AWVALID) ? S_AXI_AWADDR[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] : axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
	          3'h0:
	            // for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[0] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 0
	                // NOTE: status register is read-only
					if (state == IDLE && S_AXI_WDATA[(0*8) +: 8] == 1) begin
                        state <= ARMED;
					end else if (state == ARMED && S_AXI_WDATA[(0*8) +: 8] == 2) begin
						state <= POS;
						counter <= pulse_width_pos;
					end else if (S_AXI_WDATA[(0*8) +: 8] == 0) begin
						state <= IDLE;
					end
	              end  
	          3'h1:
	            for ( byte_index = 0; byte_index <= 1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 1
                    pulse_width_pos[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          3'h2:
	            for ( byte_index = 0; byte_index <= 1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 2
	                pulse_width_rtz[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          3'h3:
	            for ( byte_index = 0; byte_index <= 1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 3
	                pulse_width_neg[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          3'h4:
	            for ( byte_index = 0; byte_index <= 1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 4
	                pulse_width_delayramp[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          3'h5:
	            for ( byte_index = 0; byte_index <= 1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 5
	                pulse_width_recv[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          default : begin
                state <= state;
                pulse_width_pos <= pulse_width_pos;
                pulse_width_rtz <= pulse_width_rtz;
                pulse_width_neg <= pulse_width_neg;
				pulse_width_delayramp <= pulse_width_delayramp;
				pulse_width_recv <= pulse_width_recv;
              end
            endcase
	      end
		case (state)	
			IDLE: begin
			end
			ARMED: begin
			end
			POS: begin
				if (counter == 0) begin
					state <= RTZ;
					counter <= pulse_width_rtz;
				end else begin
					counter <= counter - 1;
				end
			end
			RTZ: begin
				if (counter == 0) begin
					state <= NEG;
					counter <= pulse_width_neg;
				end else begin
					counter <= counter - 1;
				end
			end
			NEG: begin
				if (counter == 0) begin
					state <= DELAYRAMP;
					counter <= pulse_width_delayramp;
				end else begin
					counter <= counter - 1;
				end
			end
			DELAYRAMP: begin
				if (counter == 0) begin
					state <= RECV;
					counter <= pulse_width_recv;
				end else begin
					counter <= counter - 1;
				end
			end
			RECV: begin
				if (counter == 0) begin
					state <= ARMED;
				end else begin
					counter <= counter - 1;
				end
			end
			default: begin
				state <= IDLE;
			end
		endcase
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
	  assign S_AXI_RDATA = 
	       (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == REG_OFFSET_STATE) ? {29'b0, state} : 
	       (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == REG_OFFSET_PULSE_WIDTH_POS) ? pulse_width_pos : 
	       (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == REG_OFFSET_PULSE_WIDTH_RTZ) ? pulse_width_rtz : 
	       (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == REG_OFFSET_PULSE_WIDTH_NEG) ? pulse_width_neg : 
	       (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == REG_OFFSET_PULSE_WIDTH_DELAYRAMP) ? pulse_width_delayramp : 
	       (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == REG_OFFSET_PULSE_WIDTH_RECV) ? pulse_width_recv : 
	       0; 
	// Add user logic here

    
	// User logic ends

endmodule
