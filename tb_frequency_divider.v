// Testbench - Frequency Divider
// Phase 1 - AFG Project
//
// Tests covered:
//   1. Async reset check
//   2. div_value = 0   -> f_out = 25.0000 MHz
//   3. div_value = 1   -> f_out = 12.5000 MHz
//   4. div_value = 4   -> f_out =  5.0000 MHz
//   5. div_value = 9   -> f_out =  2.5000 MHz
//   6. div_value = 24  -> f_out =  1.0000 MHz
//   7. div_value = 249 -> f_out =  0.1000 MHz (100 kHz)
//   8. Changing div_value on the fly (no reset between changes)

`timescale 1ns / 1ps

module tb_frequency_divider;

    // DUT signals
    reg        clk;
    reg        rst;
    reg  [7:0] div_value;
    wire       clk_out;

    // instantiate the module under test
    frequency_divider DUT (
        .clk      (clk),
        .rst      (rst),
        .div_value(div_value),
        .clk_out  (clk_out)
    );

// 50 MHz clock -> period = 20 ns
    parameter CLK_PERIOD = 20;
    initial clk = 0;
    always #(CLK_PERIOD / 2) clk = ~clk;

// variables used for frequency measurement
    real    period_ns;
    real    freq_MHz;
    integer edge_count;
    time    t_rise1, t_rise2;

    // measure_freq: catches two consecutive rising edges on clk_out and prints the measured frequency vs. the expected value
    task measure_freq;
        input [7:0] dv;
        begin
            edge_count = 0;
            @(posedge clk_out) t_rise1 = $time;
            @(posedge clk_out) t_rise2 = $time;
            period_ns = t_rise2 - t_rise1;
            freq_MHz  = 1000.0 / period_ns;
            $display("  div_value = %0d | period = %0.1f ns | measured = %0.4f MHz | expected = %0.4f MHz",
                     dv, period_ns, freq_MHz,
                     1000.0 / (2.0 * (dv + 1) * CLK_PERIOD));
        end
    endtask

    initial begin
        $dumpfile("tb_frequency_divider.vcd");
        $dumpvars(0, tb_frequency_divider);

        $display("--------------------------------------------------");
        $display("  Frequency Divider Testbench  |  clk = 50 MHz  |  Phase 2");
        $display("--------------------------------------------------");

// Test 1: async reset
        $display("\n[TEST 1] Async reset");
        rst       = 1;
        div_value = 8'd4;
        #(CLK_PERIOD * 3);
        if (clk_out === 1'b0)
            $display("  PASS - clk_out is 0 during reset");
        else
            $display("  FAIL - clk_out should be 0 during reset");
        rst = 0;
        #(CLK_PERIOD);

// Test 2: div_value = 0 -> 25 MHz
        $display("\n[TEST 2] div_value = 0  ->  expected 25.0000 MHz");
        rst = 1; #(CLK_PERIOD); rst = 0;
        div_value = 8'd0;
        measure_freq(div_value);

// Test 3: div_value = 1 -> 12.5 MHz
        $display("\n[TEST 3] div_value = 1  ->  expected 12.5000 MHz");
        rst = 1; #(CLK_PERIOD); rst = 0;
        div_value = 8'd1;
        measure_freq(div_value);

// Test 4: div_value = 4 -> 5 MHz
        $display("\n[TEST 4] div_value = 4  ->  expected 5.0000 MHz");
        rst = 1; #(CLK_PERIOD); rst = 0;
        div_value = 8'd4;
        measure_freq(div_value);

// Test 5: div_value = 9 -> 2.5 MHz
        $display("\n[TEST 5] div_value = 9  ->  expected 2.5000 MHz");
        rst = 1; #(CLK_PERIOD); rst = 0;
        div_value = 8'd9;
        measure_freq(div_value);

// Test 6: div_value = 24 -> 1 MHz
        $display("\n[TEST 6] div_value = 24  ->  expected 1.0000 MHz");
        rst = 1; #(CLK_PERIOD); rst = 0;
        div_value = 8'd24;
        measure_freq(div_value);

// Test 7: div_value = 249 -> 100 kHz
        $display("\n[TEST 7] div_value = 249  ->  expected 0.1000 MHz (100 kHz)");
        rst = 1; #(CLK_PERIOD); rst = 0;
        div_value = 8'd249;
        measure_freq(div_value);

// Test 8: change div_value without reset
        $display("\n[TEST 8] Changing div_value on the fly (4 -> 9, no reset)");
        rst = 1; #(CLK_PERIOD); rst = 0;
        div_value = 8'd4;
        #(CLK_PERIOD * 20);
        div_value = 8'd9;
        measure_freq(div_value);

// a few extra cycles so the waveform is easy to read
        rst = 1; #(CLK_PERIOD); rst = 0;
        div_value = 8'd4;
        #(CLK_PERIOD * 60);

        $display("\n--------------------------------------------------");
        $display("  All tests done.");
        $display("--------------------------------------------------");
        $finish;
    end

endmodule
