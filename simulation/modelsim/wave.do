onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /state_variable_filter_iir_tb/pb/clk
add wave -noupdate -radix binary /state_variable_filter_iir_tb/r_midi
add wave -noupdate /state_variable_filter_iir_tb/w_filtered
add wave -noupdate -radix hexadecimal /state_variable_filter_iir_tb/w_phase
add wave -noupdate -radix hexadecimal /state_variable_filter_iir_tb/w_sine
add wave -noupdate -radix hexadecimal /state_variable_filter_iir_tb/SVF/rst
add wave -noupdate -radix hexadecimal /state_variable_filter_iir_tb/SVF/ena
add wave -noupdate -radix hexadecimal -childformat {{{/state_variable_filter_iir_tb/slut/o_val[15]} -radix hexadecimal} {{/state_variable_filter_iir_tb/slut/o_val[14]} -radix hexadecimal} {{/state_variable_filter_iir_tb/slut/o_val[13]} -radix hexadecimal} {{/state_variable_filter_iir_tb/slut/o_val[12]} -radix hexadecimal} {{/state_variable_filter_iir_tb/slut/o_val[11]} -radix hexadecimal} {{/state_variable_filter_iir_tb/slut/o_val[10]} -radix hexadecimal} {{/state_variable_filter_iir_tb/slut/o_val[9]} -radix hexadecimal} {{/state_variable_filter_iir_tb/slut/o_val[8]} -radix hexadecimal} {{/state_variable_filter_iir_tb/slut/o_val[7]} -radix hexadecimal} {{/state_variable_filter_iir_tb/slut/o_val[6]} -radix hexadecimal} {{/state_variable_filter_iir_tb/slut/o_val[5]} -radix hexadecimal} {{/state_variable_filter_iir_tb/slut/o_val[4]} -radix hexadecimal} {{/state_variable_filter_iir_tb/slut/o_val[3]} -radix hexadecimal} {{/state_variable_filter_iir_tb/slut/o_val[2]} -radix hexadecimal} {{/state_variable_filter_iir_tb/slut/o_val[1]} -radix hexadecimal} {{/state_variable_filter_iir_tb/slut/o_val[0]} -radix hexadecimal}} -subitemconfig {{/state_variable_filter_iir_tb/slut/o_val[15]} {-radix hexadecimal} {/state_variable_filter_iir_tb/slut/o_val[14]} {-radix hexadecimal} {/state_variable_filter_iir_tb/slut/o_val[13]} {-radix hexadecimal} {/state_variable_filter_iir_tb/slut/o_val[12]} {-radix hexadecimal} {/state_variable_filter_iir_tb/slut/o_val[11]} {-radix hexadecimal} {/state_variable_filter_iir_tb/slut/o_val[10]} {-radix hexadecimal} {/state_variable_filter_iir_tb/slut/o_val[9]} {-radix hexadecimal} {/state_variable_filter_iir_tb/slut/o_val[8]} {-radix hexadecimal} {/state_variable_filter_iir_tb/slut/o_val[7]} {-radix hexadecimal} {/state_variable_filter_iir_tb/slut/o_val[6]} {-radix hexadecimal} {/state_variable_filter_iir_tb/slut/o_val[5]} {-radix hexadecimal} {/state_variable_filter_iir_tb/slut/o_val[4]} {-radix hexadecimal} {/state_variable_filter_iir_tb/slut/o_val[3]} {-radix hexadecimal} {/state_variable_filter_iir_tb/slut/o_val[2]} {-radix hexadecimal} {/state_variable_filter_iir_tb/slut/o_val[1]} {-radix hexadecimal} {/state_variable_filter_iir_tb/slut/o_val[0]} {-radix hexadecimal}} /state_variable_filter_iir_tb/slut/o_val
add wave -noupdate -radix hexadecimal /state_variable_filter_iir_tb/SVF/i_data
add wave -noupdate /state_variable_filter_iir_tb/SVF/o_filtered
add wave -noupdate /state_variable_filter_iir_tb/SVF/v1
add wave -noupdate /state_variable_filter_iir_tb/SVF/v2
add wave -noupdate /state_variable_filter_iir_tb/SVF/v3
add wave -noupdate /state_variable_filter_iir_tb/SVF/ic1eq
add wave -noupdate /state_variable_filter_iir_tb/SVF/ic2eq
add wave -noupdate -radix binary /state_variable_filter_iir_tb/SVF/a1
add wave -noupdate -radix binary /state_variable_filter_iir_tb/SVF/a2
add wave -noupdate -radix binary /state_variable_filter_iir_tb/SVF/a3
add wave -noupdate /state_variable_filter_iir_tb/SVF/run
add wave -noupdate /state_variable_filter_iir_tb/SVF/state
add wave -noupdate /state_variable_filter_iir_tb/SVF/mR_0
add wave -noupdate /state_variable_filter_iir_tb/SVF/mR_1
add wave -noupdate /state_variable_filter_iir_tb/SVF/mR_2
add wave -noupdate /state_variable_filter_iir_tb/SVF/mR_3
add wave -noupdate /state_variable_filter_iir_tb/SVF/w_extended_i_data
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {22568 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {0 ps} {93440 ps}
