vlib work
vlog +acc "quarter_sine.v"
vlog +acc "quarter_sine_lut.v"
vlog +acc "phase_bank.v"
vlog +acc "bank_manager.v"
vlog +acc "bank_manager_tb.v"
vsim -novopt -t 1ps -lib work bank_manager_tb
view objects
view wave
do {wave.do}
log -r *
run 2500ns
