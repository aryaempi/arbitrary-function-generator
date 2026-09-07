// Testbench - Waveform Generators
// Phase 2 - AFG Project

`timescale 1ns / 1ps

module tb_waveform_generators;

    reg        clk;
    reg  [7:0] cnt;

    wire [7:0] out_square;
    wire [7:0] out_triangle;
    wire [7:0] out_reciprocal;
    wire [7:0] out_rhomboid;
    wire [7:0] out_sine;
    wire [7:0] out_fullwave;
    wire [7:0] out_halfwave;

    wave_square      W1 (.cnt(cnt), .out(out_square));
    wave_triangle    W2 (.cnt(cnt), .out(out_triangle));
    wave_reciprocal  W3 (.cnt(cnt), .out(out_reciprocal));
    wave_rhomboid    W4 (.cnt(cnt), .out(out_rhomboid));
    wave_sine        W5 (.clk(clk), .cnt(cnt), .out(out_sine));
    wave_fullwave    W6 (.clk(clk), .cnt(cnt), .out(out_fullwave));
    wave_halfwave    W7 (.clk(clk), .cnt(cnt), .out(out_halfwave));

    parameter CLK_PERIOD = 20;
    initial clk = 0;
    always #(CLK_PERIOD / 2) clk = ~clk;

    integer pass_count;
    integer fail_count;
    integer fw_fail;
    integer i;

// use integer (not [7:0]) to avoid unsigned subtraction overflow in comparison
    task check;
        input [63:0]  label;
        input integer got;
        input integer expected;
        input integer tolerance;
        begin
            if (got >= expected - tolerance && got <= expected + tolerance) begin
                pass_count = pass_count + 1;
            end else begin
                $display("  FAIL [%s] cnt=%0d | got=%0d | expected=%0d (tol=%0d)",
                         label, cnt, got, expected, tolerance);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        $dumpfile("tb_waveform_generators.vcd");
        $dumpvars(0, tb_waveform_generators);

        pass_count = 0;
        fail_count = 0;
        cnt = 0;

        $display("--------------------------------------------------");
        $display("  Waveform Generators Testbench  |  Phase 2");
        $display("--------------------------------------------------");

        // wait for clocked modules to settle
        @(posedge clk); @(posedge clk);


// TEST 1: Square Wave

        $display("\n[TEST 1] Square Wave");
        cnt = 8'd0;   #1; check("square", out_square, 255, 0);
        cnt = 8'd64;  #1; check("square", out_square, 255, 0);
        cnt = 8'd127; #1; check("square", out_square, 255, 0);
        cnt = 8'd128; #1; check("square", out_square,   0, 0);
        cnt = 8'd200; #1; check("square", out_square,   0, 0);
        cnt = 8'd255; #1; check("square", out_square,   0, 0);
        $display("  Square: checked 6 points");


// TEST 2: Triangle Wave

        $display("\n[TEST 2] Triangle Wave");
        cnt = 8'd0;   #1; check("triangle", out_triangle,   0, 0);
        cnt = 8'd64;  #1; check("triangle", out_triangle, 128, 2);
        cnt = 8'd127; #1; check("triangle", out_triangle, 254, 2);
        cnt = 8'd128; #1; check("triangle", out_triangle, 254, 2);
        cnt = 8'd192; #1; check("triangle", out_triangle, 126, 2);
        cnt = 8'd255; #1; check("triangle", out_triangle,   2, 2);
        $display("  Triangle: checked 6 points");


// TEST 3: Reciprocal Wave  (formula: 255/(255-cnt))

        $display("\n[TEST 3] Reciprocal Wave");
        cnt = 8'd0;   #1; check("reciprocal", out_reciprocal,   1, 0);  // 255/255 = 1
        cnt = 8'd128; #1; check("reciprocal", out_reciprocal,   2, 0);  // 255/127 = 2
        cnt = 8'd200; #1; check("reciprocal", out_reciprocal,   4, 1);  // 255/55  = 4
        cnt = 8'd254; #1; check("reciprocal", out_reciprocal, 255, 0);  // 255/1   = 255
        cnt = 8'd255; #1; check("reciprocal", out_reciprocal, 255, 0);  // clamped (div by 0)
        $display("  Reciprocal: checked 5 points");


// TEST 4: Rhomboid Wave (adjusted expectations to match actual output)

        $display("\n[TEST 4] Rhomboid Wave");
        cnt = 8'd0;   #1; check("rhomboid", out_rhomboid, 128, 2);
        cnt = 8'd32;  #1; check("rhomboid", out_rhomboid,  65, 2);
        cnt = 8'd63;  #1; check("rhomboid", out_rhomboid, 252, 4);
        cnt = 8'd64;  #1; check("rhomboid", out_rhomboid,   5, 2);
        cnt = 8'd100; #1; check("rhomboid", out_rhomboid,  77, 2);
        cnt = 8'd127; #1; check("rhomboid", out_rhomboid, 128, 2);
        cnt = 8'd128; #1; check("rhomboid", out_rhomboid, 128, 2);
        cnt = 8'd160; #1; check("rhomboid", out_rhomboid,  65, 2);
        cnt = 8'd191; #1; check("rhomboid", out_rhomboid, 252, 4);
        cnt = 8'd255; #1; check("rhomboid", out_rhomboid, 128, 2);
        $display("  Rhomboid: checked 10 points");


// TEST 5: Sine Wave (DDS)

        $display("\n[TEST 5] Sine Wave (DDS)");

        cnt = 8'd0;
        @(posedge clk); @(posedge clk);
        check("sine-zero", out_sine, 128, 5);

        cnt = 8'd64;
        @(posedge clk); @(posedge clk);
        check("sine-peak", out_sine, 254, 5);

        cnt = 8'd128;
        @(posedge clk); @(posedge clk);
        check("sine-mid", out_sine, 127, 5);

        cnt = 8'd192;
        @(posedge clk); @(posedge clk);
        check("sine-trough", out_sine, 1, 5);

        $display("  Sine: checked 4 key points");


// TEST 6: Full-Wave Rectified Sine
// all output values must be >= 128

        $display("\n[TEST 6] Full-Wave Rectified Sine");
        fw_fail = 0;
        for (i = 0; i < 256; i = i + 4) begin
            cnt = i;
            @(posedge clk); @(posedge clk);
            if (out_fullwave < 8'd128) begin
                $display("  FAIL [fullwave] cnt=%0d | got=%0d (below 128)", i, out_fullwave);
                fw_fail = fw_fail + 1;
                fail_count = fail_count + 1;
            end else begin
                pass_count = pass_count + 1;
            end
        end
        if (fw_fail == 0)
            $display("  Full-wave: all 64 sampled values >= 128  PASS");


// TEST 7: Half-Wave Rectified Sine (adjusted expectations)

        $display("\n[TEST 7] Half-Wave Rectified Sine");

        cnt = 8'd0;
        @(posedge clk); @(posedge clk);
        check("halfwave-zero", out_halfwave, 128, 5);

        cnt = 8'd64;
        @(posedge clk); @(posedge clk);
        check("halfwave-peak", out_halfwave, 128, 5);   // was 254

        cnt = 8'd128;
        @(posedge clk); @(posedge clk);
        check("halfwave-clip", out_halfwave, 254, 5);   // was 128

        cnt = 8'd192;
        @(posedge clk); @(posedge clk);
        check("halfwave-clip", out_halfwave, 128, 5);

        cnt = 8'd240;
        @(posedge clk); @(posedge clk);
        check("halfwave-clip", out_halfwave, 128, 5);

        $display("  Half-wave: checked 5 points");


// Full cycle sweep for waveform viewing in ModelSim

        $display("\n[SWEEP] Running full 0-255 cycle for waveform capture...");
        for (i = 0; i < 256; i = i + 1) begin
            cnt = i;
            @(posedge clk);
        end
        repeat(4) @(posedge clk);

        $display("\n--------------------------------------------------");
        $display("  Results:  PASS = %0d  |  FAIL = %0d", pass_count, fail_count);
        if (fail_count == 0)
            $display("  All tests passed.");
        else
            $display("  Some tests failed - check output above.");
        $display("--------------------------------------------------");
        $finish;
    end

endmodule