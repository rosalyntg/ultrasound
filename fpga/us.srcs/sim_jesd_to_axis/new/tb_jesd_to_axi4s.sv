`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: tb_jesd_to_axi4s
// Description: Self-checking testbench for jesd_to_axi4s, which packetizes
//              the continuous JESD204B rx sample stream into AXI4-Stream
//              packets: a header beat carrying the us_sol/us_sof flags at the
//              start of each line, payload beats decimated by `skip'
//              (1 of every skip+1 samples), tlast every FRAMES_PER_PACKET
//              payload beats and on us_eol, and a dropped_packets counter for
//              beats lost to sink backpressure (the JESD stream itself cannot
//              be stalled).
//
//              FRAMES_PER_PACKET is reduced to 8 (hardware uses 160) so the
//              chunking is exercised in a short sim. rx_data is a free-running
//              32-bit sample counter replicated across the 128-bit word, so
//              the scoreboard can check sample order/spacing from the data.
//
//              Test sequence:
//                1. Reset: tvalid low, dropped_packets clear; rx samples
//                   streaming with no us_sol/us_sof produce no output.
//                2. Line with us_sol+us_sof, skip=0, always-ready sink:
//                   header beat first (flags in tdata[7:6], tlast=0), payload
//                   is consecutive samples with none lost or repeated, tlast
//                   on the us_eol beat and at least every FRAMES_PER_PACKET
//                   payload beats, tvalid released once the eol beat is
//                   accepted, dropped_packets stays 0.
//                3. Line with us_sol only: header flags sol=1 sof=0.
//                4. Line with skip=3: payload decimated to every 4th sample.
//                5. Backpressured sink: the header beat is held stable until
//                   accepted (nothing dropped, nothing counted); mid-payload
//                   stalls increment dropped_packets once per stalled beat
//                   cycle and sample order stays strictly increasing.
//
// Note: `skip' is only sampled into skip_ctr while in reset, so the TB sets
// it before releasing aresetn.
//
// Known failures against the current RTL (real DUT issues, kept as failing
// checks on purpose):
//   - "tlast at least every FRAMES_PER_PACKET payload beats": in
//     STATE_STREAMING tlast is only ever set in the last_ctr==0 && !tready
//     branch, so with a ready sink the counter silently reloads and a line
//     is never chunked -- the whole line becomes one packet ending at eol.
//   - "tvalid released after eol": STATE_IDLE never clears m_axis_tvalid
//     after the eol beat is accepted, so the eol beat (tlast=1) is
//     re-transferred every ready cycle until the next us_sol, injecting
//     duplicate 1-beat packets downstream.
//
// Dependencies (add to the sim fileset):
//   us.srcs/sources_1/new/jesd_to_axi4s.v
//////////////////////////////////////////////////////////////////////////////////

module tb_jesd_to_axi4s;

    localparam CLK_PERIOD = 10.0; // 100 MHz

    localparam int IN_WIDTH = 128;
    localparam int FRAMES_PER_PACKET = 8; // 160 in hardware; small for sim

    logic aclk = 0;
    logic aresetn = 0;

    always #(CLK_PERIOD / 2) aclk = ~aclk;

    // DUT inputs
    logic [7:0]          skip = '0;
    logic                rx_valid = 0;
    logic                us_sol = 0;
    logic                us_eol = 0;
    logic                us_sof = 0;
    logic                m_axis_tready = 0;

    // DUT outputs
    wire [IN_WIDTH-1:0] m_axis_tdata;
    wire                m_axis_tvalid;
    wire                m_axis_tlast;
    wire [31:0]         dropped_packets;

    // ------------------------------------------------------------------
    // Continuous JESD sample source: a free-running 32-bit sample counter
    // replicated across the 128-bit word. The JESD link has no
    // backpressure, so rx_valid stays high once the "link" is up.
    // ------------------------------------------------------------------
    logic [31:0] sample_ctr = '0;
    wire [IN_WIDTH-1:0] rx_data = {4{sample_ctr}};

    always @(posedge aclk)
        if (rx_valid)
            sample_ctr <= sample_ctr + 1;

    jesd_to_axi4s #(
        .IN_WIDTH          (IN_WIDTH),
        .FRAMES_PER_PACKET (FRAMES_PER_PACKET)
    ) dut (
        .aclk            (aclk),
        .aresetn         (aresetn),
        .m_axis_tdata    (m_axis_tdata),
        .m_axis_tready   (m_axis_tready),
        .m_axis_tlast    (m_axis_tlast),
        .m_axis_tvalid   (m_axis_tvalid),
        .dropped_packets (dropped_packets),
        .skip            (skip),
        .rx_data         (rx_data),
        .rx_valid        (rx_valid),
        .us_sol          (us_sol),
        .us_eol          (us_eol),
        .us_sof          (us_sof)
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

    // ------------------------------------------------------------------
    // Beat monitor / scoreboard
    //
    // While `recording' the TB pushes every accepted beat into `beats';
    // the stimulus opens the window at us_sol and closes it right after the
    // eol beat lands, so anything accepted outside a line (tvalid left
    // asserted after eol) is counted separately in idle_beats.
    // ------------------------------------------------------------------
    typedef struct packed {
        logic [IN_WIDTH-1:0] data;
        logic                last;
    } beat_t;

    beat_t beats[$];
    bit    recording = 0;
    int    idle_beats = 0;

    // Reference model for dropped_packets: one count per cycle the sink
    // stalls a valid payload beat (header stalls must not count)
    bit line_hdr_seen = 0;
    int stall_cnt = 0;

    always @(posedge aclk) begin
        if (aresetn) begin
            if (line_hdr_seen && m_axis_tvalid && !m_axis_tready)
                stall_cnt <= stall_cnt + 1;
            if (m_axis_tvalid && m_axis_tready) begin
                if (recording)
                    beats.push_back({m_axis_tdata, m_axis_tlast});
                else
                    idle_beats <= idle_beats + 1;
                if (!line_hdr_seen)
                    line_hdr_seen <= 1; // first accepted beat is the header
            end
        end else begin
            line_hdr_seen <= 0;
            stall_cnt     <= 0;
            idle_beats    <= 0;
        end
    end

    function automatic logic [31:0] sample_of(input beat_t b);
        return b.data[31:0];
    endfunction

    // Check one recorded line: header beat, payload sample spacing, tlast
    // placement. The eol beat is excluded from the exact-stride check
    // because us_eol flushes whatever sample is in the data register.
    task automatic check_line(input string name, input bit exp_sol,
                              input bit exp_sof, input int stride,
                              input bit exact_stride = 1);
        int run;
        bit seq_ok = 1;
        bit chunk_ok = 1;
        logic [31:0] prev, cur;

        check(beats.size() >= 3, $sformatf("%s: line produced %0d beats", name, beats.size()));
        if (beats.size() < 3) return;

        check(beats[0].data === {120'b0, exp_sol, exp_sof, 6'b0},
              $sformatf("%s: header flags sol=%b sof=%b (tdata[7:0]=%02h)",
                        name, exp_sol, exp_sof, beats[0].data[7:0]));
        check(beats[0].last === 1'b0, $sformatf("%s: header beat has tlast=0", name));

        for (int i = 2; i < beats.size(); i++) begin
            prev = sample_of(beats[i-1]);
            cur  = sample_of(beats[i]);
            if (exact_stride && i < beats.size() - 1) begin
                if (cur - prev != 32'(stride)) begin
                    seq_ok = 0;
                    $error("[%0t] FAIL detail: %s: payload beat %0d sample %0d, expected %0d",
                           $time, name, i, cur, prev + 32'(stride));
                end
            end else if (cur <= prev) begin
                seq_ok = 0;
                $error("[%0t] FAIL detail: %s: payload beat %0d sample %0d not after %0d",
                       $time, name, i, cur, prev);
            end
        end
        if (exact_stride)
            check(seq_ok, $sformatf("%s: payload sample sequence (stride %0d)", name, stride));
        else
            check(seq_ok, $sformatf("%s: payload samples strictly increasing", name));

        check(beats[beats.size()-1].last === 1'b1,
              $sformatf("%s: tlast on the eol beat", name));

        run = 0;
        for (int i = 1; i < beats.size(); i++) begin
            run++;
            if (beats[i].last)
                run = 0;
            else if (run >= FRAMES_PER_PACKET)
                chunk_ok = 0;
        end
        check(chunk_ok, $sformatf("%s: tlast at least every FRAMES_PER_PACKET=%0d payload beats",
                                  name, FRAMES_PER_PACKET));
    endtask

    // After the eol beat is accepted, tvalid must deassert: nothing more
    // may be transferred until the next line starts.
    task automatic check_line_closed(input string name);
        repeat (10) @(posedge aclk);
        check(idle_beats == 0,
              $sformatf("%s: tvalid released after eol (%0d spurious beats accepted)",
                        name, idle_beats));
    endtask

    // ------------------------------------------------------------------
    // Stimulus helpers
    // ------------------------------------------------------------------
    task automatic pulse_reset();
        aresetn <= 0;
        repeat (4) @(posedge aclk);
        aresetn <= 1;
        repeat (2) @(posedge aclk);
        beats.delete();
    endtask

    task automatic drive_line(input bit sol, input bit sof, input int ncycles);
        beats.delete();
        recording <= 1;
        us_sol    <= sol;
        us_sof    <= sof;
        @(posedge aclk);
        us_sol <= 0;
        us_sof <= 0;
        repeat (ncycles) @(posedge aclk);
        us_eol <= 1;
        @(posedge aclk);
        us_eol <= 0;
        @(posedge aclk); // let the eol beat land in the record
        recording <= 0;
        repeat (3) @(posedge aclk);
    endtask

    // ------------------------------------------------------------------
    // Stimulus
    // ------------------------------------------------------------------
    logic [IN_WIDTH-1:0] hdr_snap;

    initial begin
        // ------------------------------------------------------------
        // Test 1: reset and idle
        // ------------------------------------------------------------
        rx_valid      <= 1; // JESD link up, samples always flowing
        m_axis_tready <= 1;
        pulse_reset();
        check(m_axis_tvalid === 1'b0, "no tvalid out of reset");
        check(dropped_packets === 32'd0, "dropped_packets clear out of reset");
        repeat (20) @(posedge aclk);
        check(idle_beats == 0 && m_axis_tvalid === 1'b0,
              "rx stream ignored while idle (no us_sol/us_sof)");

        // ------------------------------------------------------------
        // Test 2: sol+sof line, skip=0, always-ready sink
        // ------------------------------------------------------------
        $display("--- Test 2: sol+sof line, skip=0, always-ready sink ---");
        drive_line(1, 1, 3 * FRAMES_PER_PACKET + 2);
        check_line("sol+sof line", 1, 1, 1);
        check(dropped_packets === 32'd0, "sol+sof line: no dropped beats counted");
        check_line_closed("sol+sof line");

        // ------------------------------------------------------------
        // Test 3: sol-only line (new scanline, not a new frame)
        // ------------------------------------------------------------
        $display("--- Test 3: sol-only line ---");
        pulse_reset();
        drive_line(1, 0, FRAMES_PER_PACKET + 3);
        check_line("sol-only line", 1, 0, 1);
        check_line_closed("sol-only line");

        // ------------------------------------------------------------
        // Test 4: skip=3 -> every 4th sample forwarded
        // ------------------------------------------------------------
        $display("--- Test 4: skip=3 decimation ---");
        skip <= 8'd3;
        pulse_reset(); // skip_ctr only loads while in reset
        drive_line(1, 1, 8 * 4);
        check_line("skip=3 line", 1, 1, 4);
        check_line_closed("skip=3 line");
        skip <= 8'd0;

        // ------------------------------------------------------------
        // Test 5: backpressured sink
        // ------------------------------------------------------------
        $display("--- Test 5: backpressured sink ---");
        pulse_reset();

        // Stall the sink over the header: the header beat must be held
        // stable until accepted, and must not count as dropped
        m_axis_tready <= 0;
        beats.delete();
        recording <= 1;
        us_sol    <= 1;
        us_sof    <= 1;
        @(posedge aclk);
        us_sol <= 0;
        us_sof <= 0;
        @(posedge aclk); // header now presented
        @(negedge aclk);
        check(m_axis_tvalid === 1'b1, "header presented while sink stalls");
        hdr_snap = m_axis_tdata;
        repeat (4) @(posedge aclk);
        @(negedge aclk);
        check(m_axis_tvalid === 1'b1 && m_axis_tdata === hdr_snap,
              "header beat held stable until accepted");
        m_axis_tready <= 1;

        // Stream a while, then stall mid-payload for 3 beat cycles
        repeat (6) @(posedge aclk);
        m_axis_tready <= 0;
        repeat (3) @(posedge aclk);
        m_axis_tready <= 1;
        repeat (6) @(posedge aclk);

        us_eol <= 1;
        @(posedge aclk);
        us_eol <= 0;
        @(posedge aclk); // let the eol beat land in the record
        recording <= 0;
        repeat (3) @(posedge aclk);

        check_line("backpressured line", 1, 1, 1, 0); // gaps allowed
        check(stall_cnt > 0, $sformatf("sink stalled %0d payload cycles", stall_cnt));
        check(dropped_packets === 32'(stall_cnt),
              $sformatf("dropped_packets=%0d matches stalled payload cycles (%0d)",
                        dropped_packets, stall_cnt));
        check_line_closed("backpressured line");

        // ------------------------------------------------------------
        repeat (5) @(posedge aclk);
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
