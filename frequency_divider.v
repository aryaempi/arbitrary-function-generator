// Frequency Divider
// Phase 1 - AFG Project
//
// Takes the 50 MHz system clock and produces a slower clock (clk_out).
// The output frequency depends on div_value: f_out = f_clk / (2 * (div_value + 1))
//
// How it works:
//  - An 8-bit down counter loads div_value on reset or when it hits zero
//  - Every time it reaches zero, clk_out toggles and the counter reloads
//  -So each half-period of clk_out is (div_value + 1) main clock cycles

module frequency_divider (
    input  wire       clk,        // 50 MHz system clock
    input  wire       rst,        // async reset, active high
    input  wire [7:0] div_value,  // division factor from SW[7:0]
    output reg        clk_out     // divided clock output
);

    reg [7:0] counter;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            counter <= div_value;
            clk_out <= 1'b0;
        end
        else begin
            if (counter == 8'd0) begin
                clk_out <= ~clk_out;
                counter <= div_value;
            end
            else begin
                counter <= counter - 8'd1;
            end
        end
    end

endmodule
