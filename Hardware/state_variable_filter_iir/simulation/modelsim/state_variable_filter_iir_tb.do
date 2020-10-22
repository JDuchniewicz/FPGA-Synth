vlib work
vlog +acc "quarter_sine.v"
vlog +acc "quarter_sine_lut.v"
vlog +acc "phase_bank.v"
vlog +acc "bank_manager.v"
vlog +acc "state_variable_filter_iir.v"
vlog +acc "lpm_multiplier.v"
vlog +acc "state_variable_filter_iir_tb.v"
#-L altera_mf_ver is required for including the verilog libraries from cmdline
vsim -novopt -t 1ps -lib work state_variable_filter_iir_tb -L altera_mf_ver -L lpm_ver 
view objects
view wave
do {wave.do}
log -r *
run 2500ns
