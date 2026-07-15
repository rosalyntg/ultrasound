`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: tb_udp_hdr_valid_gen
// Description: Self-checking testbench for two udp_hdr_valid_gen instances
//              feeding a 2-input udp_arb_mux, mirroring the integration in
//              net.sv: input 0 = "adc" (port 8002), input 1 = "xfcp"
//              (port 8001), ARB_LSB_HIGH_PRIORITY(0) so xfcp has priority.
//              Each generator watches its own payload stream and requests a
//              header from the mux; the mux's s_udp_hdr_ready closes the loop.
//
//              The TB drives AXI-Stream packets into both mux inputs and
//              scoreboards the mux output (header dest port, payload data,
//              beat count, packet order).
//
//              Test sequence:
//                1. Reset: no hdr_valid from either generator, no mux header.
//                2. Single packet on adc input -> header with port 8002.
//                3. Single packet on xfcp input -> header with port 8001.
//                4. Two back-to-back packets on adc (tvalid held across the
//                   boundary): one header each.
//                5. Simultaneous packets on both inputs: both generators
//                   pend at once; xfcp packet wins arbitration and is output
//                   first, adc packet follows.
//                6. Simultaneous packets with a throttled sink (hdr_ready
//                   1-in-4 cycles, payload tready 1-in-2 cycles).
//                7. Single-beat packet, then a normal packet on the same
//                   input. Regression test: before udp_hdr_valid_gen gated
//                   the payload stream, the mux asserted payload tready one
//                   cycle ahead of its hdr_ready pulse, so a 1-beat packet's
//                   tlast transferred in the same cycle as the mux's
//                   start-of-frame; the mux frame state stuck open, the
//                   still-asserted hdr_valid re-requested the arbiter, and
//                   the next packet went out with no UDP header.
//                8. Same trigger as seen in hardware with both streams
//                   active: a 1-beat xfcp packet queued behind an adc
//                   packet, then another xfcp packet.
//
//              Passive monitors check per generator that hdr_valid never
//              drops without a handshake and that there is at most one
//              header handshake per packet.
//
// Dependencies (add to the sim fileset):
//   us.srcs/sources_1/new/udp_hdr_valid_gen.sv
//   verilog-ethernet/rtl/udp_arb_mux.v
//   verilog-ethernet/lib/axis/rtl/arbiter.v
//   verilog-ethernet/lib/axis/rtl/priority_encoder.v
//////////////////////////////////////////////////////////////////////////////////

module tb_udp_hdr_valid_gen;

    localparam CLK_PERIOD = 10.0; // 100 MHz

    localparam logic [15:0] PORT_XFCP = 16'd8001; // mux input 1
    localparam logic [15:0] PORT_ADC  = 16'd8002; // mux input 0
    localparam logic [31:0] LOCAL_IP  = 32'hC0A8_0164;
    localparam logic [31:0] REMOTE_IP = 32'hC0A8_0101;

    logic clk = 0;
    logic rst = 1;

    always #(CLK_PERIOD / 2) clk = ~clk;

    // Source payload streams (index 0 = adc, index 1 = xfcp); the
    // generators gate tvalid/tready between the sources and the mux
    logic [1:0]  src_tvalid = '0;
    logic [1:0]  src_tlast  = '0;
    logic [63:0] src_tdata [2];
    wire  [1:0]  src_tready;  // driven by the generators
    wire  [1:0]  mux_tvalid;
    wire  [1:0]  mux_tready;

    // Header handshakes between the generators and the mux
    wire [1:0] gen_hdr_valid;
    wire [1:0] gen_hdr_ready;

    // Mux master side (TB is the sink)
    wire         m_hdr_valid;
    logic        m_hdr_ready = 0;
    wire  [15:0] m_dest_port;
    wire  [63:0] m_pl_tdata;
    wire         m_pl_tvalid;
    logic        m_pl_tready = 0;
    wire         m_pl_tlast;

    // ------------------------------------------------------------------
    // DUTs: two header-valid generators + arbitrated mux, as in net.sv
    // ------------------------------------------------------------------
    udp_hdr_valid_gen udp_hdr_valid_gen_adc (
        .clk           (clk),
        .rst           (rst),
        .s_axis_tvalid (src_tvalid[0]),
        .s_axis_tready (src_tready[0]),
        .s_axis_tlast  (src_tlast[0]),
        .m_axis_tvalid (mux_tvalid[0]),
        .m_axis_tready (mux_tready[0]),
        .hdr_ready     (gen_hdr_ready[0]),
        .hdr_valid     (gen_hdr_valid[0])
    );

    udp_hdr_valid_gen udp_hdr_valid_gen_xfcp (
        .clk           (clk),
        .rst           (rst),
        .s_axis_tvalid (src_tvalid[1]),
        .s_axis_tready (src_tready[1]),
        .s_axis_tlast  (src_tlast[1]),
        .m_axis_tvalid (mux_tvalid[1]),
        .m_axis_tready (mux_tready[1]),
        .hdr_ready     (gen_hdr_ready[1]),
        .hdr_valid     (gen_hdr_valid[1])
    );

    udp_arb_mux #(
        .S_COUNT(2),
        .DATA_WIDTH(64),
        .ARB_LSB_HIGH_PRIORITY(0) // xfcp (input 1) should be priority
    ) udp_mux_inst (
        .clk(clk),
        .rst(rst),

        .s_udp_hdr_valid(gen_hdr_valid),
        .s_udp_hdr_ready(gen_hdr_ready),
        .s_eth_dest_mac('0),
        .s_eth_src_mac('0),
        .s_eth_type('0),
        .s_ip_version('0),
        .s_ip_ihl('0),
        .s_ip_dscp('0),
        .s_ip_ecn('0),
        .s_ip_length('0),
        .s_ip_identification('0),
        .s_ip_flags('0),
        .s_ip_fragment_offset('0),
        .s_ip_ttl({8'd64, 8'd64}),
        .s_ip_protocol('0),
        .s_ip_header_checksum('0),
        .s_ip_source_ip({2{LOCAL_IP}}),
        .s_ip_dest_ip({2{REMOTE_IP}}),
        .s_udp_source_port({PORT_XFCP, PORT_ADC}),
        .s_udp_dest_port({PORT_XFCP, PORT_ADC}),
        .s_udp_length('0),
        .s_udp_checksum('0),
        .s_udp_payload_axis_tdata({src_tdata[1], src_tdata[0]}),
        .s_udp_payload_axis_tkeep({8'hFF, 8'hFF}),
        .s_udp_payload_axis_tvalid(mux_tvalid),
        .s_udp_payload_axis_tready(mux_tready),
        .s_udp_payload_axis_tlast(src_tlast),
        .s_udp_payload_axis_tid('0),
        .s_udp_payload_axis_tdest('0),
        .s_udp_payload_axis_tuser('0),

        .m_udp_hdr_valid(m_hdr_valid),
        .m_udp_hdr_ready(m_hdr_ready),
        .m_eth_dest_mac(),
        .m_eth_src_mac(),
        .m_eth_type(),
        .m_ip_version(),
        .m_ip_ihl(),
        .m_ip_dscp(),
        .m_ip_ecn(),
        .m_ip_length(),
        .m_ip_identification(),
        .m_ip_flags(),
        .m_ip_fragment_offset(),
        .m_ip_ttl(),
        .m_ip_protocol(),
        .m_ip_header_checksum(),
        .m_ip_source_ip(),
        .m_ip_dest_ip(),
        .m_udp_source_port(),
        .m_udp_dest_port(m_dest_port),
        .m_udp_length(),
        .m_udp_checksum(),
        .m_udp_payload_axis_tdata(m_pl_tdata),
        .m_udp_payload_axis_tkeep(),
        .m_udp_payload_axis_tvalid(m_pl_tvalid),
        .m_udp_payload_axis_tready(m_pl_tready),
        .m_udp_payload_axis_tlast(m_pl_tlast),
        .m_udp_payload_axis_tid(),
        .m_udp_payload_axis_tdest(),
        .m_udp_payload_axis_tuser()
    );

    // ------------------------------------------------------------------
    // Checking helpers and scoreboard
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

    function automatic logic [63:0] beat_data(input logic [7:0] seed, input int j);
        return {seed, j[7:0], seed, j[7:0], seed, j[7:0], seed, j[7:0]};
    endfunction

    typedef struct packed {
        logic [15:0] dest_port;
        logic [7:0]  seed;
        logic [15:0] nbeats;
    } exp_pkt_t;

    exp_pkt_t exp_hdr_q[$]; // popped by the header monitor
    exp_pkt_t exp_pl_q[$];  // popped by the payload monitor

    // Push a packet expectation in arbitration order before sending it
    task automatic queue_expected(input int src, input int nbeats, input logic [7:0] seed);
        exp_pkt_t e;
        e.dest_port = (src == 0) ? PORT_ADC : PORT_XFCP;
        e.seed      = seed;
        e.nbeats    = 16'(nbeats);
        exp_hdr_q.push_back(e);
        exp_pl_q.push_back(e);
    endtask

    // Header monitor: every accepted mux header must match the next expected one
    always @(posedge clk) begin : hdr_mon
        exp_pkt_t e;
        if (!rst && m_hdr_valid && m_hdr_ready) begin
            if (exp_hdr_q.size() == 0) begin
                errors++;
                $error("[%0t] FAIL: unexpected header (port %0d)", $time, m_dest_port);
            end else begin
                e = exp_hdr_q.pop_front();
                check(m_dest_port === e.dest_port,
                      $sformatf("header dest_port %0d (expected %0d)", m_dest_port, e.dest_port));
            end
        end
    end

    // Payload monitor: data pattern, beat count, packet order
    int pl_beat_cnt = 0;
    always @(posedge clk) begin : pl_mon
        if (!rst && m_pl_tvalid && m_pl_tready) begin
            if (exp_pl_q.size() == 0) begin
                errors++;
                $error("[%0t] FAIL: unexpected payload beat %h", $time, m_pl_tdata);
            end else begin
                if (m_pl_tdata !== beat_data(exp_pl_q[0].seed, pl_beat_cnt)) begin
                    errors++;
                    $error("[%0t] FAIL: payload mismatch on beat %0d (port %0d): got %h, expected %h",
                           $time, pl_beat_cnt, exp_pl_q[0].dest_port,
                           m_pl_tdata, beat_data(exp_pl_q[0].seed, pl_beat_cnt));
                end
                pl_beat_cnt++;
                if (m_pl_tlast) begin
                    check(16'(pl_beat_cnt) == exp_pl_q[0].nbeats,
                          $sformatf("packet for port %0d: %0d beats received",
                                    exp_pl_q[0].dest_port, pl_beat_cnt));
                    void'(exp_pl_q.pop_front());
                    pl_beat_cnt = 0;
                end
            end
        end
    end

    // ------------------------------------------------------------------
    // Per-generator invariant monitors
    // ------------------------------------------------------------------
    logic rst_q = 1;
    always @(posedge clk) rst_q <= rst;

    for (genvar gi = 0; gi < 2; gi++) begin : g_gen_mon
        logic hv_q = 0, hr_q = 0;
        bit hdr_done = 0;
        always @(posedge clk) begin
            if (!rst && !rst_q) begin
                // hdr_valid must stay asserted until hdr_ready
                if (hv_q && !gen_hdr_valid[gi] && !hr_q) begin
                    errors++;
                    $error("[%0t] FAIL: gen[%0d] hdr_valid dropped without a handshake", $time, gi);
                end
                // at most one header handshake per packet
                if (gen_hdr_valid[gi] && gen_hdr_ready[gi]) begin
                    if (hdr_done) begin
                        errors++;
                        $error("[%0t] FAIL: gen[%0d] second header handshake in one packet", $time, gi);
                    end
                    hdr_done <= 1;
                end
                if (src_tvalid[gi] && src_tready[gi] && src_tlast[gi])
                    hdr_done <= 0; // packet boundary (wins on a coincident handshake)
            end else begin
                hdr_done <= 0;
            end
            hv_q <= gen_hdr_valid[gi] & ~rst;
            hr_q <= gen_hdr_ready[gi];
        end
    end

    // ------------------------------------------------------------------
    // Output sink: full speed, or throttled (hdr 1-in-4, payload 1-in-2)
    // ------------------------------------------------------------------
    logic sink_throttle = 0;
    logic [1:0] thr_cnt = 0;
    always @(posedge clk) begin
        if (sink_throttle) begin
            m_hdr_ready <= (thr_cnt == 2'd0);
            m_pl_tready <= thr_cnt[0];
            thr_cnt     <= thr_cnt + 1;
        end else begin
            m_hdr_ready <= 1'b1;
            m_pl_tready <= 1'b1;
        end
    end

    // ------------------------------------------------------------------
    // Packet drivers
    // ------------------------------------------------------------------
    // Inputs are driven with nonblocking assignments; sampling src_tready
    // right after a posedge sees the value the DUT used at that edge.
    task automatic send_beat(input int src, input logic [63:0] data, input bit last);
        src_tdata[src]  <= data;
        src_tlast[src]  <= last;
        src_tvalid[src] <= 1'b1;
        forever begin
            @(posedge clk);
            if (src_tready[src]) break;
        end
    endtask

    task automatic send_packet(input int src, input int nbeats, input logic [7:0] seed);
        for (int j = 0; j < nbeats; j++)
            send_beat(src, beat_data(seed, j), j == nbeats - 1);
        src_tvalid[src] <= 1'b0;
        src_tlast[src]  <= 1'b0;
    endtask

    // Wait until the scoreboard has drained (or give up after max_cycles)
    task automatic wait_drain(input string what, input int max_cycles = 1000);
        int n = 0;
        while ((exp_hdr_q.size() != 0 || exp_pl_q.size() != 0) && n < max_cycles) begin
            @(posedge clk);
            n++;
        end
        check(exp_hdr_q.size() == 0 && exp_pl_q.size() == 0, what);
        repeat (5) @(posedge clk);
    endtask

    // ------------------------------------------------------------------
    // Stimulus
    // ------------------------------------------------------------------
    bit t7_done = 0;
    bit t8_done = 0;

    initial begin
        src_tdata[0] = '0;
        src_tdata[1] = '0;

        // ------------------------------------------------------------
        // Test 1: reset
        // ------------------------------------------------------------
        repeat (5) @(posedge clk);
        rst <= 0;
        @(negedge clk);
        check(gen_hdr_valid === 2'b00, "no hdr_valid out of reset");
        check(m_hdr_valid === 1'b0, "no mux header out of reset");

        // ------------------------------------------------------------
        // Test 2: single 4-beat packet on adc (input 0)
        // ------------------------------------------------------------
        $display("--- Test 2: single packet on adc ---");
        queue_expected(0, 4, 8'hA1);
        send_packet(0, 4, 8'hA1);
        wait_drain("adc packet delivered with header");

        // ------------------------------------------------------------
        // Test 3: single 3-beat packet on xfcp (input 1)
        // ------------------------------------------------------------
        $display("--- Test 3: single packet on xfcp ---");
        queue_expected(1, 3, 8'hB2);
        send_packet(1, 3, 8'hB2);
        wait_drain("xfcp packet delivered with header");

        // ------------------------------------------------------------
        // Test 4: back-to-back packets on adc, tvalid held high across
        //         the packet boundary
        // ------------------------------------------------------------
        $display("--- Test 4: back-to-back packets on adc ---");
        queue_expected(0, 3, 8'hC3);
        queue_expected(0, 4, 8'hC4);
        send_packet(0, 3, 8'hC3);
        send_packet(0, 4, 8'hC4);
        wait_drain("back-to-back adc packets each got a header");

        // ------------------------------------------------------------
        // Test 5: simultaneous packets; xfcp (input 1) has priority
        // ------------------------------------------------------------
        $display("--- Test 5: simultaneous packets, xfcp priority ---");
        queue_expected(1, 4, 8'hD5); // xfcp must be output first
        queue_expected(0, 4, 8'hE6);
        fork
            send_packet(1, 4, 8'hD5);
            send_packet(0, 4, 8'hE6);
            begin
                @(posedge clk);
                @(negedge clk);
                check(gen_hdr_valid === 2'b11, "both generators pending simultaneously");
            end
        join
        wait_drain("simultaneous packets delivered in priority order");

        // ------------------------------------------------------------
        // Test 6: simultaneous packets with throttled sink
        // ------------------------------------------------------------
        $display("--- Test 6: simultaneous packets, throttled sink ---");
        sink_throttle <= 1;
        repeat (2) @(posedge clk);
        queue_expected(1, 5, 8'h3A);
        queue_expected(0, 5, 8'h4B);
        fork
            send_packet(1, 5, 8'h3A);
            send_packet(0, 5, 8'h4B);
        join
        wait_drain("throttled simultaneous packets delivered");
        sink_throttle <= 0;
        repeat (2) @(posedge clk);

        // ------------------------------------------------------------
        // Test 7: single-beat packet, then a normal packet on the same
        //         input. Regression for the short-packet bug: without the
        //         payload gate the 1-beat tlast transferred in the same
        //         cycle as the mux's start-of-frame, wedging the mux frame
        //         state, and the follow-up packet went out header-less.
        // ------------------------------------------------------------
        $display("--- Test 7: single-beat packet corner case ---");
        queue_expected(1, 1, 8'h77);
        send_packet(1, 1, 8'h77);
        wait_drain("single-beat xfcp packet delivered", 200);

        queue_expected(1, 2, 8'h88);
        fork
            begin
                send_packet(1, 2, 8'h88);
                t7_done = 1;
            end
            repeat (200) @(posedge clk);
        join_any
        disable fork;
        src_tvalid[1] <= 0;
        src_tlast[1]  <= 0;
        check(t7_done, "follow-up xfcp packet accepted by the mux");
        wait_drain("packet after single-beat packet delivered with a header", 200);

        // discard anything left behind so the next test starts clean
        exp_hdr_q.delete();
        exp_pl_q.delete();
        repeat (5) @(posedge clk);

        // ------------------------------------------------------------
        // Test 8: both streams active (the hardware failure scenario). A
        //         1-beat xfcp packet arrives while adc is streaming and is
        //         granted at the packet switch; the following xfcp packet
        //         must still get its own header.
        // ------------------------------------------------------------
        $display("--- Test 8: short xfcp packet while adc streams ---");
        queue_expected(0, 8, 8'h91);
        queue_expected(1, 1, 8'h92); // granted right after the adc packet
        fork
            send_packet(0, 8, 8'h91);
            begin
                repeat (3) @(posedge clk);
                send_packet(1, 1, 8'h92);
            end
        join
        wait_drain("adc + interleaved 1-beat xfcp packet delivered", 300);

        queue_expected(1, 3, 8'h93);
        fork
            begin
                send_packet(1, 3, 8'h93);
                t8_done = 1;
            end
            repeat (200) @(posedge clk);
        join_any
        disable fork;
        src_tvalid[1] <= 0;
        src_tlast[1]  <= 0;
        check(t8_done, "xfcp accepts a packet after the interleaved short one");
        wait_drain("xfcp packet after short packet delivered with a header", 200);

        // discard anything left behind by the known-failing tests
        exp_hdr_q.delete();
        exp_pl_q.delete();

        repeat (5) @(posedge clk);
        if (errors == 0)
            $display("[%0t] TEST PASSED", $time);
        else
            $display("[%0t] TEST FAILED: %0d errors", $time, errors);
        $finish;
    end

    // Watchdog
    initial begin
        #100us;
        $error("[%0t] FAIL: testbench timeout", $time);
        $finish;
    end

endmodule
