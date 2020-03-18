vlib work
vlog +acc "synthesizer_top.v"
vlog +acc "synthesizer_top_tb.v"
vlog +acc "bank_manager.v"
vlog +acc "quarter_sine.v"
vlog +acc "quarter_sine_lut.v"
vlog +acc "phase_bank.v"
vsim -novopt -t 1ps -lib work synthesizer_top_tb
view objects
view wave
do {wave.do}
log -r *
run 2500ns
