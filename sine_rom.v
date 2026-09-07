// Sine ROM
// Stores 64 samples of the first quarter of a sine wave (with +128 offset).
// Used by the sine waveform generator to reconstruct a full sine cycle.

module sine_rom (
    input  wire       clk,
    input  wire [5:0] cnt,
    output reg  [7:0] out
);

    reg [7:0] rom_memory [0:63];

    initial begin
        $readmemb("Sin.mem", rom_memory);
    end

    always @(posedge clk) begin
        out <= rom_memory[cnt];
    end

endmodule
