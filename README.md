# Arbitrary Function Generator (AFG)

A digital Arbitrary Function Generator (AFG) written in Verilog HDL. The design generates seven 8-bit waveform types with configurable frequency and amplitude. It also produces a PWM output that can drive a low-pass filter to create an analog signal.

This project was developed for the Computer-Aided Design of Digital Systems course at the University of Tehran, Fouman Faculty of Engineering.

## Features

- Seven selectable waveform types:
  - Square
  - Triangle
  - Reciprocal
  - Rhomboid
  - Sine, using a quarter-wave ROM and DDS symmetry
  - Full-wave rectified sine
  - Half-wave rectified sine
- 8-bit frequency divider control
- Four amplitude levels: full, half, quarter, and eighth
- 8-bit digital waveform output (`DigitalOut`)
- 8-bit PWM digital-to-analog conversion output (`PWMOut`)
- Testbenches for each main block and for the complete system

## Block Diagram

```text
50 MHz clock
     |
     v
Frequency Divider --> Phase Counter --> Waveform Generators --> MUX and Scaler --> PWM DAC
                                                                                       |
                                                                                       v
                                                                                    PWMOut
```

## Top-Level Interface

The top-level module is `afg_top`.

| Signal | Direction | Width | Description |
| --- | --- | ---: | --- |
| `Clk` | Input | 1 | 50 MHz system clock |
| `Rst` | Input | 1 | Asynchronous active-high reset |
| `SW[7:0]` | Input | 8 | Frequency-divider value |
| `SW[10:8]` | Input | 3 | Waveform selection |
| `SW[12:11]` | Input | 2 | Amplitude selection |
| `DigitalOut[7:0]` | Output | 8 | Selected and scaled digital waveform |
| `PWMOut` | Output | 1 | PWM output for a low-pass filter |

## Control Settings

### Waveform selection: `SW[10:8]`

| Value | Waveform |
| --- | --- |
| `000` | Square |
| `001` | Triangle |
| `010` | Reciprocal |
| `011` | Rhomboid |
| `100` | Sine |
| `101` | Full-wave rectified sine |
| `110` | Half-wave rectified sine |
| `111` | Defaults to square |

### Amplitude selection: `SW[12:11]`

| Value | Scale | Operation |
| --- | --- | --- |
| `00` | Full | `sample >> 0` |
| `01` | Half | `sample >> 1` |
| `10` | Quarter | `sample >> 2` |
| `11` | Eighth | `sample >> 3` |

### Frequency selection: `SW[7:0]`

The divided clock frequency is:

```text
f_divided = 50 MHz / (2 * (SW[7:0] + 1))
```

The 8-bit phase counter advances on this divided clock. A complete waveform contains 256 phase samples.

## Repository Layout

```text
.
├── afg_top.v                  # Top-level design
├── frequency_divider.v        # Configurable clock divider
├── waveform_generators.v      # Seven waveform generators
├── sine_rom.v                 # Sine lookup-table ROM
├── Sin.mem                    # Binary samples for the sine ROM
├── mux_scaler.v               # Waveform MUX and amplitude scaler
├── pwm_dac.v                  # 8-bit PWM DAC
├── tb_afg_top.v               # Full-system testbench
├── tb_frequency_divider.v     # Frequency-divider testbench
├── tb_waveform_generators.v   # Waveform-generator testbench
├── tb_mux_scaler.v            # MUX and scaler testbench
├── tb_pwm_dac.v               # PWM DAC testbench
└── wave_display.do            # Optional ModelSim waveform setup script
```

## Simulation

The project was tested with ModelSim. Compile the design files with their testbench, then simulate one testbench at a time.

Example for the complete system:

```tcl
vlib work
vlog frequency_divider.v sine_rom.v waveform_generators.v mux_scaler.v pwm_dac.v afg_top.v tb_afg_top.v
vsim tb_afg_top
run -all
```

`Sin.mem` must be in the simulator working directory because `sine_rom.v` loads it with `$readmemb`.

The individual testbenches check the frequency divider, waveform generators, MUX and scaler, and PWM DAC. The complete-system testbench verifies all seven waveforms, the four amplitude levels, frequency changes, and reset behavior.

## PWM Output

`PWMOut` has an 8-bit resolution. Its duty cycle is approximately:

```text
duty_cycle = DigitalOut / 256
```

Connect `PWMOut` to a suitable low-pass filter, such as an RC filter, to obtain a corresponding analog voltage.

## License

This repository uses the MIT License. See [LICENSE](LICENSE).
