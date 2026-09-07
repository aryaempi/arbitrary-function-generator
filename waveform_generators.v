// Waveform Generators
// Phase 2 - AFG Project
//
// Waveform list:
//  1. Square
//  2. Triangle
//  3. Reciprocal
//  4. Rhomboid
//  5. Sine (DDS)
//  6. Full-wave rectified sine
//  7. Half-wave rectified sine


// 1. Square Wave
module wave_square (
    input  wire [7:0] cnt,    
    output reg  [7:0] out
);
    always @(*) begin
        if (cnt < 8'd128)
            out = 8'd255;
        else
            out = 8'd0;
    end
endmodule



// 2. Triangle Wave
module wave_triangle (
    input  wire [7:0] cnt,
    output reg  [7:0] out
);
    always @(*) begin
        if (cnt < 8'd128)
            out = cnt << 1;           
        else
            out = (~cnt << 1);        
    end
endmodule


// 3. Reciprocal Wave
module wave_reciprocal (
    input  wire [7:0] cnt,
    output wire [7:0] out
);
    reg [7:0] lut [0:255];
    integer i;
    integer val;
    initial begin
        for (i = 0; i < 255; i = i + 1) begin
            val = 255 / (255 - i);
            lut[i] = (val > 255) ? 255 : val;
        end
        lut[255] = 255; 
    end
    assign out = lut[cnt];
endmodule


// 4. Rhomboid Wave
module wave_rhomboid (
    input  wire [7:0] cnt,
    output reg  [7:0] out
);

    wire [6:0] idx = cnt[7:1];   
    reg  [7:0] amp;              

    always @(*) begin
        if (idx < 32)
            amp = (idx * 127) / 32;           
        else if (idx < 64)
            amp = ((63 - idx) * 127) / 32;     
        else if (idx < 96)
            amp = ((idx - 64) * 127) / 32;     
        else
            amp = ((127 - idx) * 127) / 32;    
    end

    always @(*) begin
        if (cnt[0] == 0)
            out = 128 - amp;  
        else
            out = 128 + amp; 
    end

endmodule


// 5. Sine Wave (DDS using ROM)
module wave_sine (
    input  wire       clk,
    input  wire [7:0] cnt,
    output wire [7:0] out 
);
    wire [5:0] rom_addr;
    wire [7:0] rom_data;
    reg  [7:0] cnt_reg;

    assign rom_addr = cnt[6] ? (6'd63 - cnt[5:0]) : cnt[5:0];

    sine_rom ROM (
        .clk  (clk),
        .cnt  (rom_addr),
        .out  (rom_data)
    );

    always @(posedge clk) begin
        cnt_reg <= cnt;
    end

    assign out = (cnt_reg[7]) ? (8'd255 - rom_data) : rom_data;
endmodule


// 6. Full-Wave Rectified Sine
module wave_fullwave (
    input  wire       clk,
    input  wire [7:0] cnt,
    output reg  [7:0] out
);
    wire [7:0] sine_out;

    wave_sine SINE (
        .clk(clk),
        .cnt(cnt),
        .out(sine_out)
    );

    always @(posedge clk) begin
        if (sine_out < 8'd128)
            out <= 8'd255 - sine_out;   // flip values below midpoint
        else
            out <= sine_out;
    end
endmodule


// 7. Half-Wave Rectified Sine
module wave_halfwave (
    input  wire       clk,
    input  wire [7:0] cnt,
    output reg  [7:0] out
);
    wire [7:0] sine_out;

    wave_sine SINE (
        .clk(clk),
        .cnt(cnt),
        .out(sine_out)
    );

    always @(posedge clk) begin
        if (sine_out < 8'd128)
            out <= 8'd128;              
        else
            out <= sine_out;
    end
endmodule
