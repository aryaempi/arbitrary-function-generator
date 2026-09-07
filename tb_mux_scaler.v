// Testbench - Multiplexer & Scaler
// Phase 3 - AFG Project
//
// Tests:
//  1. MUX selection: each func_sel value routes the correct waveform to output
//  2. Scaler: all 4 amplitude levels (>> 0, >> 1, >> 2, >> 3)
//  3. Combined: MUX + scaler together with multiple waveforms

`timescale 1ns / 1ps

module tb_mux_scaler;

// control inputs
    reg [2:0] func_sel;
    reg [1:0] amp_sel;

// waveform inputs - driven manually in this testbench
    reg [7:0] in_square;
    reg [7:0] in_triangle;
    reg [7:0] in_reciprocal;
    reg [7:0] in_rhomboid;
    reg [7:0] in_sine;
    reg [7:0] in_fullwave;
    reg [7:0] in_halfwave;

    wire [7:0] out;

    mux_scaler DUT (
        .func_sel     (func_sel),
        .amp_sel      (amp_sel),
        .in_square    (in_square),
        .in_triangle  (in_triangle),
        .in_reciprocal(in_reciprocal),
        .in_rhomboid  (in_rhomboid),
        .in_sine      (in_sine),
        .in_fullwave  (in_fullwave),
        .in_halfwave  (in_halfwave),
        .out          (out)
    );

    integer pass_count;
    integer fail_count;

    task check;
        input [127:0] label;
        input integer got;
        input integer expected;
        input integer tolerance;
        begin
            if (got >= expected - tolerance && got <= expected + tolerance) begin
                pass_count = pass_count + 1;
            end else begin
                $display("  FAIL [%s] got=%0d | expected=%0d (tol=%0d)",
                         label, got, expected, tolerance);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        $dumpfile("tb_mux_scaler.vcd");
        $dumpvars(0, tb_mux_scaler);

        pass_count = 0;
        fail_count = 0;

// assign a unique recognizable value to each waveform input
        in_square     = 8'd200;
        in_triangle   = 8'd180;
        in_reciprocal = 8'd160;
        in_rhomboid   = 8'd140;
        in_sine       = 8'd120;
        in_fullwave   = 8'd100;
        in_halfwave   = 8'd80;

        $display("--------------------------------------------------");
        $display("  MUX & Scaler Testbench  |  Phase 3");
        $display("--------------------------------------------------");


// TEST 1: MUX selection (amp_sel=00, no scaling)

        $display("\n[TEST 1] MUX selection (amp_sel = 00, no scaling)");
        amp_sel = 2'b00;

        func_sel = 3'b000; #10; check("mux-square",     out, 200, 0);
        func_sel = 3'b001; #10; check("mux-triangle",   out, 180, 0);
        func_sel = 3'b010; #10; check("mux-reciprocal", out, 160, 0);
        func_sel = 3'b011; #10; check("mux-rhomboid",   out, 140, 0);
        func_sel = 3'b100; #10; check("mux-sine",       out, 120, 0);
        func_sel = 3'b101; #10; check("mux-fullwave",   out, 100, 0);
        func_sel = 3'b110; #10; check("mux-halfwave",   out,  80, 0);
        func_sel = 3'b111; #10; check("mux-default",    out, 200, 0);
        $display("  MUX selection: checked 8 cases");


// TEST 2: Scaler - all 4 levels on square (200)

        $display("\n[TEST 2] Amplitude scaler (func_sel=000, in_square=200)");
        func_sel = 3'b000;

        amp_sel = 2'b00; #10; check("scale-/1", out, 200,  0);  // 200 >> 0 = 200
        amp_sel = 2'b01; #10; check("scale-/2", out, 100,  0);  // 200 >> 1 = 100
        amp_sel = 2'b10; #10; check("scale-/4", out,  50,  0);  // 200 >> 2 = 50
        amp_sel = 2'b11; #10; check("scale-/8", out,  25,  0);  // 200 >> 3 = 25
        $display("  Scaler: checked 4 amplitude levels");


// TEST 3: Scaler on triangle (180)

        $display("\n[TEST 3] Amplitude scaler on triangle (in=180)");
        func_sel = 3'b001;

        amp_sel = 2'b00; #10; check("tri-scale-/1", out, 180, 0);  // 180 >> 0 = 180
        amp_sel = 2'b01; #10; check("tri-scale-/2", out,  90, 0);  // 180 >> 1 = 90
        amp_sel = 2'b10; #10; check("tri-scale-/4", out,  45, 0);  // 180 >> 2 = 45
        amp_sel = 2'b11; #10; check("tri-scale-/8", out,  22, 0);  // 180 >> 3 = 22
        $display("  Triangle scaler: checked 4 amplitude levels");


// TEST 4: Scaler on sine (120)

        $display("\n[TEST 4] Amplitude scaler on sine (in=120)");
        func_sel = 3'b100;

        amp_sel = 2'b00; #10; check("sine-scale-/1", out, 120, 0);
        amp_sel = 2'b01; #10; check("sine-scale-/2", out,  60, 0);
        amp_sel = 2'b10; #10; check("sine-scale-/4", out,  30, 0);
        amp_sel = 2'b11; #10; check("sine-scale-/8", out,  15, 0);
        $display("  Sine scaler: checked 4 amplitude levels");


// TEST 5: Edge case - input = 255 (max)

        $display("\n[TEST 5] Edge case: input = 255 (max value)");
        in_square = 8'd255;
        func_sel  = 3'b000;

        amp_sel = 2'b00; #10; check("max-/1", out, 255, 0);
        amp_sel = 2'b01; #10; check("max-/2", out, 127, 0);  // 255 >> 1 = 127
        amp_sel = 2'b10; #10; check("max-/4", out,  63, 0);  // 255 >> 2 = 63
        amp_sel = 2'b11; #10; check("max-/8", out,  31, 0);  // 255 >> 3 = 31
        $display("  Max value scaler: checked 4 levels");


// TEST 6: Edge case - input = 0 (min)

        $display("\n[TEST 6] Edge case: input = 0 (min value)");
        in_square = 8'd0;
        func_sel  = 3'b000;

        amp_sel = 2'b00; #10; check("zero-/1", out, 0, 0);
        amp_sel = 2'b01; #10; check("zero-/2", out, 0, 0);
        amp_sel = 2'b10; #10; check("zero-/4", out, 0, 0);
        amp_sel = 2'b11; #10; check("zero-/8", out, 0, 0);
        $display("  Zero value scaler: checked 4 levels");

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
