vlib work
vlog +acc "quarter_sine.v"
vlog +acc "quarter_sine_lut.v"
vlog +acc "phase_bank.v"
vlog +acc "Synthesizer.v"
vlog +acc "Synthesizer_tb.v"
vsim -novopt -t 1ps -lib work Synthesizer_tb
view objects
view wave
do {wave.do}
log -r *
run 2500ns
