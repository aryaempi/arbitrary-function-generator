// Multiplexer & Scaler
// Phase 3 - AFG Project
//
// func_sel (SW[10:8]):
//   000 -> Square
//   001 -> Triangle
//   010 -> Reciprocal
//   011 -> Rhomboid
//   100 -> Sine
//   101 -> Full-wave rectified sine
//   110 -> Half-wave rectified sine
//   111 -> (defaults to square)
//
// amp_sel (SW[12:11]):
//   00 -> full amplitude  (divide by 1, >> 0)
//   01 -> half amplitude  (divide by 2, >> 1)
//   10 -> quarter         (divide by 4, >> 2)
//   11 -> eighth          (divide by 8, >> 3)

module mux_scaler (
    input  wire [2:0] func_sel,  
    input  wire [1:0] amp_sel,  
    input  wire [7:0] in_square,
    input  wire [7:0] in_triangle,
    input  wire [7:0] in_reciprocal,
    input  wire [7:0] in_rhomboid,
    input  wire [7:0] in_sine,
    input  wire [7:0] in_fullwave,
    input  wire [7:0] in_halfwave,
    output reg  [7:0] out
);

    reg [7:0] selected;

    // 7-to-1 MUX
    always @(*) begin
        case (func_sel)
            3'b000: selected = in_square;
            3'b001: selected = in_triangle;
            3'b010: selected = in_reciprocal;
            3'b011: selected = in_rhomboid;
            3'b100: selected = in_sine;
            3'b101: selected = in_fullwave;
            3'b110: selected = in_halfwave;
            default: selected = in_square;
        endcase
    end

    always @(*) begin
        case (amp_sel)
            2'b00: out = selected;
            2'b01: out = selected >> 1;
            2'b10: out = selected >> 2;
            2'b11: out = selected >> 3;
        endcase
    end

endmodule
