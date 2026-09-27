`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: tb_pulse_gen
// Description: Testbench for pulse_gen using the Xilinx AXI Verification IP
//              (AXI VIP) as an AXI4-Lite master.
//
//              Test sequence:
//                1. Program the pos/rtz/neg pulse width registers and read
//                   them back.
//                2. Verify pulser_oen stays low the whole time before arming.
//                3. Arm (write 1 to reg 0) and verify pulser_oen goes high.
//                4. Start (write 2 to reg 0) and measure the durations of the
//                   POS, RTZ, and NEG phases against the programmed widths.
//                5. Verify pulser_oen drops and state returns to IDLE.
//
// Requires an AXI VIP instance named axi_vip_0 in the project. Create it with:
//
//   create_ip -name axi_vip -vendor xilinx.com -library ip -version 1.1 \
//       -module_name axi_vip_0
//   set_property -dict [list \
//       CONFIG.PROTOCOL {AXI4LITE} \
//       CONFIG.INTERFACE_MODE {MASTER} \
//       CONFIG.ADDR_WIDTH {32} \
//       CONFIG.DATA_WIDTH {32} \
//   ] [get_ips axi_vip_0]
//   generate_target all [get_ips axi_vip_0]
//////////////////////////////////////////////////////////////////////////////////

import axi_vip_pkg::*;
import axi_vip_0_pkg::*;

module tb_pulse_gen;

    localparam CLK_PERIOD = 10.0; // 100 MHz

    // Byte addresses of the registers (word offset * 4)
    localparam bit [31:0] ADDR_STATE  = 32'h00;
    localparam bit [31:0] ADDR_PW_POS = 32'h04;
    localparam bit [31:0] ADDR_PW_RTZ = 32'h08;
    localparam bit [31:0] ADDR_PW_NEG = 32'h0C;
    localparam bit [31:0] ADDR_PW_WAIT= 32'h10;
    localparam bit [31:0] ADDR_PW_RECV= 32'h14;
    localparam bit [31:0] ADDR_PW_IDLE= 32'h18;
    localparam bit [31:0] ADDR_PW_NUM_SCANLINES= 32'h1c;
    localparam bit [31:0] ADDR_TABLE_START = 32'h400;

    localparam bit [31:0] TABLE_CH_LEN = 32'h400;

    // Commands / states in reg 0
    localparam bit [31:0] CMD_DISARM  = 32'd0;
    localparam bit [31:0] CMD_ARM     = 32'd1;
    localparam bit [31:0] CMD_START   = 32'd2;
    localparam bit [31:0] STATE_IDLE  = 32'd0;
    localparam bit [31:0] STATE_ARMED = 32'd1;

    // Programmed pulse widths (register value N gives a phase of N+1 clocks)
    localparam int PW_POS = 10;
    localparam int PW_RTZ = 4;
    localparam int PW_NEG = 12;
    localparam int PW_WAIT = 4;
    localparam int PW_RECV = 40;
    localparam int PW_IDLE = 8;
    localparam int NUM_SCANLINES = 4;

    logic aclk = 0;
    logic aresetn = 0;

    always #(CLK_PERIOD / 2) aclk = ~aclk;

    // DUT outputs
    logic [7:0] pulser_neg;
    logic [7:0] pulser_pos;
    logic       pulser_oen;
    logic       ramp_rst;

    // AXI4-Lite bus between VIP master and DUT
    logic [31:0] awaddr;
    logic [2:0]  awprot;
    logic        awvalid, awready;
    logic [31:0] wdata;
    logic [3:0]  wstrb;
    logic        wvalid, wready;
    logic [1:0]  bresp;
    logic        bvalid, bready;
    logic [31:0] araddr;
    logic [2:0]  arprot;
    logic        arvalid, arready;
    logic [31:0] rdata;
    logic [1:0]  rresp;
    logic        rvalid, rready;

    axi_vip_0 vip (
        .aclk          (aclk),
        .aresetn       (aresetn),
        .m_axi_awaddr  (awaddr),
        .m_axi_awprot  (awprot),
        .m_axi_awvalid (awvalid),
        .m_axi_awready (awready),
        .m_axi_wdata   (wdata),
        .m_axi_wstrb   (wstrb),
        .m_axi_wvalid  (wvalid),
        .m_axi_wready  (wready),
        .m_axi_bresp   (bresp),
        .m_axi_bvalid  (bvalid),
        .m_axi_bready  (bready),
        .m_axi_araddr  (araddr),
        .m_axi_arprot  (arprot),
        .m_axi_arvalid (arvalid),
        .m_axi_arready (arready),
        .m_axi_rdata   (rdata),
        .m_axi_rresp   (rresp),
        .m_axi_rvalid  (rvalid),
        .m_axi_rready  (rready)
    );

    pulse_gen #(
        .C_S_AXI_DATA_WIDTH (32)
    ) dut (
        .aclk          (aclk),
        .aresetn       (aresetn),
        .pulser_neg    (pulser_neg),
        .pulser_pos    (pulser_pos),
        .pulser_oen    (pulser_oen),
        .ramp_rst      (ramp_rst),
        .S_AXI_AWADDR  (awaddr[13:0]),
        .S_AXI_AWPROT  (awprot),
        .S_AXI_AWVALID (awvalid),
        .S_AXI_AWREADY (awready),
        .S_AXI_WDATA   (wdata),
        .S_AXI_WSTRB   (wstrb),
        .S_AXI_WVALID  (wvalid),
        .S_AXI_WREADY  (wready),
        .S_AXI_BRESP   (bresp),
        .S_AXI_BVALID  (bvalid),
        .S_AXI_BREADY  (bready),
        .S_AXI_ARADDR  (araddr[13:0]),
        .S_AXI_ARPROT  (arprot),
        .S_AXI_ARVALID (arvalid),
        .S_AXI_ARREADY (arready),
        .S_AXI_RDATA   (rdata),
        .S_AXI_RRESP   (rresp),
        .S_AXI_RVALID  (rvalid),
        .S_AXI_RREADY  (rready)
    );

    // ------------------------------------------------------------------
    // Checking helpers
    // ------------------------------------------------------------------
    int errors = 0;

    task automatic check(input bit cond, input string msg);
        if (cond)
            $display("[%0t] PASS: %s", $time, msg);
        else begin
            errors++;
            $error("[%0t] FAIL: %s", $time, msg);
        end
    endtask

    function automatic int cycles(input realtime dur);
        return int'(dur / CLK_PERIOD);
    endfunction

    // pulser_oen must never assert before the arm command has been sent
    bit arm_sent = 0;
    always @(posedge aclk) begin
        if (aresetn && !arm_sent && pulser_oen === 1'b1) begin
            errors++;
            $error("[%0t] FAIL: pulser_oen asserted before arm command", $time);
        end
    end

    // pos and neg drivers must never be on at the same time
    always @(posedge aclk) begin
        if (aresetn && pulser_pos[0] === 1'b1 && pulser_neg[0] === 1'b1) begin
            errors++;
            $error("[%0t] FAIL: pulser_pos and pulser_neg both asserted", $time);
        end
    end

    // ------------------------------------------------------------------
    // Stimulus
    // ------------------------------------------------------------------
    axi_vip_0_mst_t mst_agent;
    xil_axi_resp_t  resp;
    bit [31:0]      read_data;

    realtime t_pos_rise, t_pos_fall, t_neg_rise, t_neg_fall, t_oen_fall;

    integer sl;
    integer ch;

    initial begin
        mst_agent = new("pulse_gen_mst_agent", vip.inst.IF);
        mst_agent.start_master();

        // Reset
        aresetn = 0;
        repeat (16) @(posedge aclk);
        aresetn = 1;
        repeat (5) @(posedge aclk);

        check(pulser_oen === 1'b0, "pulser_oen low out of reset");

        // ------------------------------------------------------------
        // Program pulse widths and read them back
        // ------------------------------------------------------------
        mst_agent.AXI4LITE_WRITE_BURST(ADDR_PW_POS, 0, PW_POS, resp);
        mst_agent.AXI4LITE_WRITE_BURST(ADDR_PW_RTZ, 0, PW_RTZ, resp);
        mst_agent.AXI4LITE_WRITE_BURST(ADDR_PW_NEG, 0, PW_NEG, resp);
        mst_agent.AXI4LITE_WRITE_BURST(ADDR_PW_WAIT, 0, PW_WAIT, resp);
        mst_agent.AXI4LITE_WRITE_BURST(ADDR_PW_RECV, 0, PW_RECV, resp);
        mst_agent.AXI4LITE_WRITE_BURST(ADDR_PW_IDLE, 0, PW_IDLE, resp);
        mst_agent.AXI4LITE_WRITE_BURST(ADDR_PW_NUM_SCANLINES, 0, NUM_SCANLINES, resp);

        for (sl = 0; sl < NUM_SCANLINES; sl = sl + 1) begin
            for (ch = 0; ch < 8; ch = ch + 1) begin
                mst_agent.AXI4LITE_WRITE_BURST(ADDR_TABLE_START + ch * TABLE_CH_LEN + sl * 4, 0, sl*CHANNELS+ch, resp);
            end
        end

        mst_agent.AXI4LITE_READ_BURST(ADDR_PW_POS, 0, read_data, resp);
        check(read_data[15:0] == PW_POS[15:0], "pulse_width_pos readback");
        mst_agent.AXI4LITE_READ_BURST(ADDR_PW_RTZ, 0, read_data, resp);
        check(read_data[15:0] == PW_RTZ[15:0], "pulse_width_rtz readback");
        mst_agent.AXI4LITE_READ_BURST(ADDR_PW_NEG, 0, read_data, resp);
        check(read_data[15:0] == PW_NEG[15:0], "pulse_width_neg readback");

        mst_agent.AXI4LITE_READ_BURST(ADDR_STATE, 0, read_data, resp);
        check(read_data == STATE_IDLE, "state is IDLE before arm");
        check(pulser_oen === 1'b0, "pulser_oen still low after programming widths");

        // ------------------------------------------------------------
        // Arm: oen must go high only now
        // ------------------------------------------------------------
        arm_sent = 1;
        mst_agent.AXI4LITE_WRITE_BURST(ADDR_STATE, 0, CMD_ARM, resp);
        repeat (2) @(posedge aclk);

        check(pulser_oen === 1'b1, "pulser_oen high after arm");
        check(pulser_pos == 8'h00 && pulser_neg == 8'h00,
              "no drive while armed");

        mst_agent.AXI4LITE_READ_BURST(ADDR_STATE, 0, read_data, resp);
        check(read_data == STATE_ARMED, "state reads ARMED after arm");

        // ------------------------------------------------------------
        // Start: measure one full pulse cycle
        // ------------------------------------------------------------
        fork
            begin : measure_pulse
                @(posedge pulser_pos[0]); t_pos_rise = $realtime;
                @(negedge pulser_pos[0]); t_pos_fall = $realtime;
                @(posedge pulser_neg[0]); t_neg_rise = $realtime;
                @(negedge pulser_neg[0]); t_neg_fall = $realtime;
            end
        join_none

        mst_agent.AXI4LITE_WRITE_BURST(ADDR_STATE, 0, CMD_START, resp);

        @(negedge pulser_oen);
        t_oen_fall = $realtime;
        @(posedge aclk);

        // Each phase holds for (register value + 1) clocks: the counter is
        // loaded with N and the state advances on the cycle it reaches 0.
        check(cycles(t_pos_fall - t_pos_rise) == PW_POS + 1,
              $sformatf("POS phase width: got %0d cycles, expected %0d",
                        cycles(t_pos_fall - t_pos_rise), PW_POS + 1));
        check(cycles(t_neg_rise - t_pos_fall) == PW_RTZ + 1,
              $sformatf("RTZ phase width: got %0d cycles, expected %0d",
                        cycles(t_neg_rise - t_pos_fall), PW_RTZ + 1));
        check(cycles(t_neg_fall - t_neg_rise) == PW_NEG + 1,
              $sformatf("NEG phase width: got %0d cycles, expected %0d",
                        cycles(t_neg_fall - t_neg_rise), PW_NEG + 1));
        check(t_oen_fall == t_neg_fall,
              "pulser_oen deasserts when NEG phase ends");

        // ------------------------------------------------------------
        // Back to idle
        // ------------------------------------------------------------
        check(pulser_oen === 1'b0, "pulser_oen low after pulse cycle");
        check(pulser_pos == 8'h00 && pulser_neg == 8'h00,
              "no drive after pulse cycle");

        mst_agent.AXI4LITE_READ_BURST(ADDR_STATE, 0, read_data, resp);
        check(read_data == STATE_IDLE, "state back to IDLE after pulse cycle");

        repeat (10) @(posedge aclk);

        if (errors == 0)
            $display("[%0t] TEST PASSED", $time);
        else
            $display("[%0t] TEST FAILED: %0d errors", $time, errors);
        $finish;
    end

    // Watchdog
    initial begin
        #200us;
        $error("[%0t] FAIL: testbench timeout", $time);
        $finish;
    end

endmodule
