// Testbench - AFG Top-Level Module
// Phase 5 - AFG Project
//
// SW mapping:
//   SW[7:0]   = div_value       (frequency)
//   SW[10:8]  = func_sel        (waveform)
//   SW[12:11] = amp_sel         (amplitude)
//   
// This file has two parts:
//   PART 1 (around line 110): automated PASS/FAIL checks - no editing needed.
//   PART 2 (around line 210):  waveform display section - this is the part
//                               you edit to control what gets shown in Wave.
//
// ============================================================
//  HOW TO CHANGE FREQUENCY / WAVEFORM / AMPLITUDE FOR DISPLAY
// ============================================================
//  Scroll down to the "WAVEFORM DISPLAY SECTION" near the bottom.
//  Every wave shown there is set with one line like this:
//
//      show_wave(FUNC, AMP, DIV, CYCLES);
//
//  FUNC   (waveform shape) - 3 bits:
//      3'd0 = square       3'd1 = triangle     3'd2 = reciprocal
//      3'd3 = rhomboid      3'd4 = sine          3'd5 = fullwave
//      3'd6 = halfwave
//
//  AMP    (amplitude / scale) - 2 bits:
//      2'b00 = full amplitude   2'b01 = half
//      2'b10 = quarter          2'b11 = eighth
//
//  DIV    (frequency) - 8 bits, 0 to 255:
//      f_out = 50MHz / (2*(DIV+1))   -> bigger DIV = slower / lower frequency
//      DIV=0  -> fastest (25 MHz wave clock)
//      DIV=4  -> medium  (5 MHz wave clock)
//      DIV=24 -> slower  (1 MHz wave clock)
//
//  CYCLES (just for display) - how many full wave repeats to show.
//      More cycles = easier to see repeating pattern, but longer sim time.
//
//  Example: to show a triangle wave, half amplitude, at div=9:
//      show_wave(3'd1, 2'b01, 8'd9, 4);
//
//  Each call to show_wave is followed by a short reset pulse, so every
//  waveform in the Wave window starts from a clean zero baseline and
//  the boundary between waveforms is easy to spot (look for the flat
//  zero line right before each new shape starts).
// ============================================================

`timescale 1ns / 1ps

module tb_afg_top;

    reg         Clk;
    reg         Rst;
    reg  [12:0] SW;
    wire [7:0]  DigitalOut;
    wire        PWMOut;

    afg_top DUT (
        .Clk       (Clk),
        .Rst       (Rst),
        .SW        (SW),
        .DigitalOut(DigitalOut),
        .PWMOut    (PWMOut)
    );

    parameter CLK_PERIOD = 20;
    initial Clk = 0;
    always #(CLK_PERIOD / 2) Clk = ~Clk;

    integer pass_count;
    integer fail_count;
    integer i;

    function [79:0] wave_name;
        input [2:0] sel;
        case (sel)
            3'd0: wave_name = "square    ";
            3'd1: wave_name = "triangle  ";
            3'd2: wave_name = "reciprocal";
            3'd3: wave_name = "rhomboid  ";
            3'd4: wave_name = "sine      ";
            3'd5: wave_name = "fullwave  ";
            3'd6: wave_name = "halfwave  ";
            default: wave_name = "unknown   ";
        endcase
    endfunction

    task run_cycle;
        input [2:0]  func;
        input [1:0]  amp;
        input [7:0]  div;
        input integer expected_max;
        integer pwm_high;
        integer pwm_low;
        integer out_ok;
        begin
            SW       = {amp, func, div};
            pwm_high = 0;
            pwm_low  = 0;
            out_ok   = 1;
            repeat(256 * 2 * (div + 1)) begin
                @(posedge Clk);
                if (DigitalOut > expected_max) out_ok = 0;
                if (PWMOut === 1'b1) pwm_high = pwm_high + 1;
                else                  pwm_low  = pwm_low  + 1;
            end
            if (out_ok && (pwm_high > 0 || expected_max == 0)) begin
                pass_count = pass_count + 1;
                $display("  PASS  wave=%-10s  amp_sel=%0d  div=%0d  max_out=%0d  pwm_hi=%0d pwm_lo=%0d",
                         wave_name(func), amp, div, expected_max, pwm_high, pwm_low);
            end else begin
                fail_count = fail_count + 1;
                $display("  FAIL  wave=%-10s  amp_sel=%0d  div=%0d  out_ok=%0d  pwm_hi=%0d pwm_lo=%0d",
                         wave_name(func), amp, div, out_ok, pwm_high, pwm_low);
            end
        end
    endtask

    // show_wave: holds SW at one fixed setting for CYCLES full wave periods,
    // then drops into a short reset so the next waveform starts from a
    // clean zero line. This is what makes each shape easy to pick out
    // when you scroll through the Wave window.
    task show_wave;
        input [2:0]  func;
        input [1:0]  amp;
        input [7:0]  div;
        input integer cycles;
        begin
            $display("  showing: wave=%s  amp_sel=%b  div=%0d  cycles=%0d",
                      wave_name(func), amp, div, cycles);
            SW = {amp, func, div};
            repeat(cycles * 256 * 2 * (div + 1)) @(posedge Clk);

            // short reset gap so the next wave starts clean and the
            // boundary between two waveforms is visible as a flat line
            Rst = 1;
            repeat(4) @(posedge Clk);
            Rst = 0;
            repeat(4) @(posedge Clk);
        end
    endtask

    initial begin
        $dumpfile("tb_afg_top.vcd");
        $dumpvars(0, tb_afg_top);

        pass_count = 0;
        fail_count = 0;
        SW = 13'd0;

        $display("==================================================");
        $display("  AFG Top-Level Testbench  |  Phase 5");
        $display("==================================================");

        Rst = 1;
        repeat(10) @(posedge Clk);
        Rst = 0;
        repeat(5)  @(posedge Clk);


// PART 1: AUTOMATED PASS/FAIL CHECKS

        $display("\n[TEST 1] All 7 waveforms  |  amp_sel=00  |  div=4");
        run_cycle(3'd0, 2'b00, 8'd4, 255);
        run_cycle(3'd1, 2'b00, 8'd4, 255);
        run_cycle(3'd2, 2'b00, 8'd4, 255);
        run_cycle(3'd3, 2'b00, 8'd4, 255);
        run_cycle(3'd4, 2'b00, 8'd4, 255);
        run_cycle(3'd5, 2'b00, 8'd4, 255);
        run_cycle(3'd6, 2'b00, 8'd4, 255);

        $display("\n[TEST 2] Square wave  |  all amplitude levels  |  div=4");
        run_cycle(3'd0, 2'b00, 8'd4, 255);
        run_cycle(3'd0, 2'b01, 8'd4, 127);
        run_cycle(3'd0, 2'b10, 8'd4,  63);
        run_cycle(3'd0, 2'b11, 8'd4,  31);

        $display("\n[TEST 3] Sine wave  |  all amplitude levels  |  div=4");
        run_cycle(3'd4, 2'b00, 8'd4, 255);
        run_cycle(3'd4, 2'b01, 8'd4, 127);
        run_cycle(3'd4, 2'b10, 8'd4,  63);
        run_cycle(3'd4, 2'b11, 8'd4,  31);

        $display("\n[TEST 4] Triangle wave  |  all amplitude levels  |  div=4");
        run_cycle(3'd1, 2'b00, 8'd4, 255);
        run_cycle(3'd1, 2'b01, 8'd4, 127);
        run_cycle(3'd1, 2'b10, 8'd4,  63);
        run_cycle(3'd1, 2'b11, 8'd4,  31);

        $display("\n[TEST 5] Frequency sweep  |  square  |  amp_sel=00");
        run_cycle(3'd0, 2'b00, 8'd0,  255);
        run_cycle(3'd0, 2'b00, 8'd1,  255);
        run_cycle(3'd0, 2'b00, 8'd4,  255);
        run_cycle(3'd0, 2'b00, 8'd24, 255);

        $display("\n[TEST 6] Frequency sweep  |  sine  |  amp_sel=00");
        run_cycle(3'd4, 2'b00, 8'd0,  255);
        run_cycle(3'd4, 2'b00, 8'd4,  255);
        run_cycle(3'd4, 2'b00, 8'd24, 255);

        $display("\n[TEST 7] Reset during operation");
        SW  = {2'b00, 3'b100, 8'd4};
        repeat(100) @(posedge Clk);
        Rst = 1;
        repeat(5) @(posedge Clk);
        if (PWMOut === 1'b0) begin
            pass_count = pass_count + 1;
            $display("  PASS - PWMOut=0 during reset");
        end else begin
            fail_count = fail_count + 1;
            $display("  FAIL - PWMOut should be 0 during reset");
        end
        Rst = 0;
        repeat(5) @(posedge Clk);

        $display("\n==================================================");
        $display("  PASS/FAIL Results:  PASS = %0d  |  FAIL = %0d", pass_count, fail_count);
        $display("==================================================");


// PART 2: WAVEFORM DISPLAY SECTION

        $display("\n==================================================");
        $display("  WAVEFORM DISPLAY  -  set DigitalOut to Analog/Step");
        $display("==================================================");

        Rst = 1; repeat(4) @(posedge Clk); Rst = 0; repeat(4) @(posedge Clk);

// ---- 1. all 7 waveforms, one after another, same amp/freq ----
        $display("\n[1/3] All 7 waveform shapes  (amp=full, div=4)");
        show_wave(3'd0, 2'b00, 8'd4, 4);   // square
        show_wave(3'd1, 2'b00, 8'd4, 4);   // triangle
        show_wave(3'd2, 2'b00, 8'd4, 4);   // reciprocal
        show_wave(3'd3, 2'b00, 8'd4, 4);   // rhomboid
        show_wave(3'd4, 2'b00, 8'd4, 4);   // sine
        show_wave(3'd5, 2'b00, 8'd4, 4);   // fullwave
        show_wave(3'd6, 2'b00, 8'd4, 4);   // halfwave

// ---- 2. one waveform (sine), all 4 amplitude levels ----
        $display("\n[2/3] Sine wave  -  all 4 amplitude levels  (div=4)");
        show_wave(3'd4, 2'b00, 8'd4, 4);   // full
        show_wave(3'd4, 2'b01, 8'd4, 4);   // half
        show_wave(3'd4, 2'b10, 8'd4, 4);   // quarter
        show_wave(3'd4, 2'b11, 8'd4, 4);   // eighth

// ---- 3. one waveform (square), 3 different frequencies ----
        $display("\n[3/3] Square wave  -  3 frequencies  (amp=full)");
        show_wave(3'd0, 2'b00, 8'd0,  4);   // div=0  -> fastest
        show_wave(3'd0, 2'b00, 8'd4,  4);   // div=4  -> medium
        show_wave(3'd0, 2'b00, 8'd24, 4);   // div=24 -> slower

        $display("\n==================================================");
        $display("  Final Results:  PASS = %0d  |  FAIL = %0d", pass_count, fail_count);
        if (fail_count == 0)
            $display("  All tests passed.");
        else
            $display("  Some tests failed - check output above.");
        $display("==================================================");
        $finish;
    end

endmodule
