# wave_display.do
# Run this after loading tb_wave_display to automatically set up
# a clean Analog/Step view of DigitalOut, plus the digital signals.
#
# Usage in ModelSim Transcript:
#   do wave_display.do

add wave -divider "Control Signals"
add wave /tb_wave_display/Clk
add wave /tb_wave_display/Rst
add wave /tb_wave_display/SW

add wave -divider "Digital Output (analog step view)"
add wave -format analog -height 100 -max 260 -min 0 /tb_wave_display/DigitalOut

add wave -divider "PWM Output"
add wave /tb_wave_display/PWMOut

run -all

# zoom to fit the entire run in the window
wave zoom full
