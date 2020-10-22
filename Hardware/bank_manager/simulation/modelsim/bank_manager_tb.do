vlib work
vlog +acc "quarter_sine.v"
vlog +acc "quarter_sine_lut.v"
vlog +acc "phase_bank.v"
vlog +acc "bank_manager.v"
vlog +acc "state_variable_filter_iir.v"
vlog +acc "lpm_multiplier.v"
vlog +acc "pipeline.v"
vlog +acc "bank_manager_tb.v"
vsim -novopt -t 1ps -lib work bank_manager_tb -L altera_mf_ver -L lpm_ver 
view objects
view wave
do {wave.do}
log -r *
run 2500ns
