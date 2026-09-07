// PWM DAC
// Phase 2 - AFG Project
//
// Duty cycle = data / 256
// Example: data=128 -> 50% duty cycle -> ~Vcc/2 analog output

module pwm_dac (
    input  wire       clk,    // 50 MHz system clock
    input  wire       rst,    // async reset, active high
    input  wire [7:0] data,   // digital input (from mux_scaler output)
    output reg        pwm_out // PWM output signal
);

    reg [7:0] counter;  // free-running counter, 0 to 255

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            counter <= 8'd0;
            pwm_out <= 1'b0;
        end
        else begin
            counter <= counter + 8'd1;  // wraps from 255 back to 0 automatically
            pwm_out <= (data > counter) ? 1'b1 : 1'b0;
        end
    end

endmodule
