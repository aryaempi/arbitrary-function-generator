// Testbench - PWM DAC
// Phase 4 - AFG Project
//
// Tests:
//  1. Reset check: pwm_out = 0 during reset
//  2. data = 0   -> duty cycle = 0%   
//  3. data = 128 -> duty cycle = 50% 
//  4. data = 255 -> duty cycle = 99.6% 
//  5. data = 64  -> duty cycle = 25%
//  6. data = 192 -> duty cycle = 75%
//  7. Dynamic data change: checks that PWM adjusts correctly mid-cycle

`timescale 1ns / 1ps

module tb_pwm_dac;

    reg        clk;
    reg        rst;
    reg  [7:0] data;
    wire       pwm_out;

    pwm_dac DUT (
        .clk    (clk),
        .rst    (rst),
        .data   (data),
        .pwm_out(pwm_out)
    );

// 50 MHz clock
    parameter CLK_PERIOD = 20;
    initial clk = 0;
    always #(CLK_PERIOD / 2) clk = ~clk;

    integer pass_count;
    integer fail_count;
    integer high_count;
    integer i;

// measure_duty: counts high cycles over one full PWM period (256 clocks). returns the number of high cycles
    task measure_duty;
        input  [7:0]  d;
        output integer highs;
        integer k;
        begin
            // wait for counter to roll over to 0 (sync to start of PWM period)
            // we detect this by watching the counter register directly
            // since we can't access it externally, we just measure 256 cycles
            // starting from the next clock edge
            highs = 0;
            @(posedge clk);
            for (k = 0; k < 256; k = k + 1) begin
                @(posedge clk);
                if (pwm_out === 1'b1)
                    highs = highs + 1;
            end
        end
    endtask

    task check_duty;
        input [127:0] label;
        input [7:0]   d;
        input integer  expected_high;
        input integer  tolerance;
        integer highs;
        begin
            data = d;
            measure_duty(d, highs);
            if (highs >= expected_high - tolerance && highs <= expected_high + tolerance) begin
                pass_count = pass_count + 1;
                $display("  PASS [%s] data=%0d | high=%0d/%0d | duty=%.2f%%",
                         label, d, highs, 256, highs * 100.0 / 256.0);
            end else begin
                fail_count = fail_count + 1;
                $display("  FAIL [%s] data=%0d | high=%0d | expected=%0d (tol=%0d)",
                         label, d, highs, expected_high, tolerance);
            end
        end
    endtask

    initial begin
        $dumpfile("tb_pwm_dac.vcd");
        $dumpvars(0, tb_pwm_dac);

        pass_count = 0;
        fail_count = 0;
        data = 8'd0;

        $display("--------------------------------------------------");
        $display("  PWM DAC Testbench  |  Phase 4");
        $display("--------------------------------------------------");


// TEST 1: Reset

        $display("\n[TEST 1] Async reset");
        rst = 1;
        data = 8'd200;
        #(CLK_PERIOD * 5);
        if (pwm_out === 1'b0) begin
            pass_count = pass_count + 1;
            $display("  PASS - pwm_out is 0 during reset");
        end else begin
            fail_count = fail_count + 1;
            $display("  FAIL - pwm_out should be 0 during reset");
        end
        rst = 0;
        #(CLK_PERIOD * 2);


// TEST 2: data = 0 -> always low (0 high cycles)

        $display("\n[TEST 2] data = 0 -> 0%% duty cycle");
        check_duty("data=0", 8'd0, 0, 1);


// TEST 3: data = 64 -> 25% duty cycle (64 high cycles)

        $display("\n[TEST 3] data = 64 -> 25%% duty cycle");
        check_duty("data=64", 8'd64, 64, 2);


// TEST 4: data = 128 -> 50% duty cycle (128 high cycles)

        $display("\n[TEST 4] data = 128 -> 50%% duty cycle");
        check_duty("data=128", 8'd128, 128, 2);


// TEST 5: data = 192 -> 75% duty cycle (192 high cycles)

        $display("\n[TEST 5] data = 192 -> 75%% duty cycle");
        check_duty("data=192", 8'd192, 192, 2);


// TEST 6: data = 255 -> 99.6% duty cycle (255 high cycles)

        $display("\n[TEST 6] data = 255 -> 99.6%% duty cycle");
        check_duty("data=255", 8'd255, 255, 2);


// TEST 7: dynamic data change mid-operation

        $display("\n[TEST 7] Dynamic data change (128 -> 64 -> 192)");
        check_duty("dynamic-128", 8'd128, 128, 2);
        check_duty("dynamic-64",  8'd64,   64, 2);
        check_duty("dynamic-192", 8'd192, 192, 2);


// Waveform capture: ramp data from 0 to 255. shows PWM duty cycle increasing with data

        $display("\n[SWEEP] Ramping data 0->255 for waveform capture...");
        rst = 1; #(CLK_PERIOD); rst = 0;
        for (i = 0; i < 256; i = i + 1) begin
            data = i;
            repeat(256) @(posedge clk);
        end

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
