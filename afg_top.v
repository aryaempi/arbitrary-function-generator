// Top-Level Module - AFG (Arbitrary Function Generator)
// Phase 5 - AFG Project
//
// Connects all phases together into a single working system:
//   Phase 1: Frequency Divider         -> slow clock for waveform counter
//   Phase 2: Waveform Generators       -> 7 wave shapes
//   Phase 3: MUX & Scaler              -> wave select + amplitude control
//   Phase 4: PWM DAC                   -> digital to analog conversion
//
// Inputs:
//   Clk                                - 50 MHz system clock
//   Rst                                - async reset, active high
//   SW[7:0]                            - frequency control (div_value for frequency divider)
//   SW[10:8]                           - waveform select (0=square ... 6=halfwave)
//   SW[12:11]                          - amplitude scale (00=full, 01=half, 10=quarter, 11=eighth)
//
// Outputs:
//   DigitalOut[7:0] - 8-bit digital waveform (before PWM)
//   PWMOut          - final PWM output (analog after LPF)

module afg_top (
    input  wire        Clk,
    input  wire        Rst,
    input  wire [12:0] SW,
    output wire [7:0]  DigitalOut,
    output wire        PWMOut
);


    wire        clk_divided;    // slow clock from frequency divider
    wire [7:0]  phase_cnt;      // 8-bit phase counter (0-255), one full wave cycle

    // outputs of all 7 waveform generators
    wire [7:0]  w_square;
    wire [7:0]  w_triangle;
    wire [7:0]  w_reciprocal;
    wire [7:0]  w_rhomboid;
    wire [7:0]  w_sine;
    wire [7:0]  w_fullwave;
    wire [7:0]  w_halfwave;

     // SW[7:0] sets the division factor
     // f_out = 50MHz / (2 * (SW[7:0] + 1))
    frequency_divider FREQ_DIV (
        .clk      (Clk),
        .rst      (Rst),
        .div_value(SW[7:0]),
        .clk_out  (clk_divided)
    );

    // Free-running 8-bit counter clocked by clk_divided.
    // One full count (0 to 255) = one complete waveform cycle.
    reg [7:0] cnt;
    always @(posedge clk_divided or posedge Rst) begin
        if (Rst)
            cnt <= 8'd0;
        else
            cnt <= cnt + 8'd1;
    end
    assign phase_cnt = cnt;

    wave_square      W1 (.cnt(phase_cnt), .out(w_square));
    wave_triangle    W2 (.cnt(phase_cnt), .out(w_triangle));
    wave_reciprocal  W3 (.cnt(phase_cnt), .out(w_reciprocal));
    wave_rhomboid    W4 (.cnt(phase_cnt), .out(w_rhomboid));
    wave_sine        W5 (.clk(clk_divided), .cnt(phase_cnt), .out(w_sine));
    wave_fullwave    W6 (.clk(clk_divided), .cnt(phase_cnt), .out(w_fullwave));
    wave_halfwave    W7 (.clk(clk_divided), .cnt(phase_cnt), .out(w_halfwave));

    // SW[10:8] selects waveform, SW[12:11] scales amplitude
    mux_scaler MUX_SCALE (
        .func_sel     (SW[10:8]),
        .amp_sel      (SW[12:11]),
        .in_square    (w_square),
        .in_triangle  (w_triangle),
        .in_reciprocal(w_reciprocal),
        .in_rhomboid  (w_rhomboid),
        .in_sine      (w_sine),
        .in_fullwave  (w_fullwave),
        .in_halfwave  (w_halfwave),
        .out          (DigitalOut)
    );

    // converts 8-bit DigitalOut to PWM using the main 50 MHz clock
    pwm_dac PWM (
        .clk    (Clk),
        .rst    (Rst),
        .data   (DigitalOut),
        .pwm_out(PWMOut)
    );

endmodule
