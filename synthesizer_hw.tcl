# TCL File Generated by Component Editor 19.1
# Sat May 16 15:49:17 CEST 2020
# DO NOT MODIFY


# 
# synthesizer "synthesizer" v1.0
# Jakub Duchniewicz 2020.05.16.15:49:17
# A synthesizer component for my Bachelor's Thesis
# 

# 
# request TCL package from ACDS 16.1
# 
package require -exact qsys 16.1


# 
# module synthesizer
# 
set_module_property DESCRIPTION "A synthesizer component for my Bachelor's Thesis"
set_module_property NAME synthesizer
set_module_property VERSION 1.0
set_module_property INTERNAL false
set_module_property OPAQUE_ADDRESS_MAP true
set_module_property GROUP Custom
set_module_property AUTHOR "Jakub Duchniewicz"
set_module_property DISPLAY_NAME synthesizer
set_module_property INSTANTIATE_IN_SYSTEM_MODULE true
set_module_property EDITABLE true
set_module_property REPORT_TO_TALKBACK false
set_module_property ALLOW_GREYBOX_GENERATION false
set_module_property REPORT_HIERARCHY false


# 
# file sets
# 
add_fileset QUARTUS_SYNTH QUARTUS_SYNTH "" ""
set_fileset_property QUARTUS_SYNTH TOP_LEVEL synthesizer_top_p
set_fileset_property QUARTUS_SYNTH ENABLE_RELATIVE_INCLUDE_PATHS false
set_fileset_property QUARTUS_SYNTH ENABLE_FILE_OVERWRITE_MODE false
add_fileset_file quarter_sine_lut.v VERILOG PATH ../Hardware/bank_manager/quarter_sine_lut.v
add_fileset_file lpm_multiplier.v VERILOG PATH ../Hardware/state_variable_filter_iir/lpm_multiplier.v
add_fileset_file clk_slow.v VERILOG PATH ../Hardware/synthesizer_top/clk_slow.v
add_fileset_file mixer.v VERILOG PATH ../Hardware/mixer/mixer.v
add_fileset_file dac_dsm2.vhd VHDL PATH ../Hardware/sigma_delta_dac_dual_loop/trunk/dsm2/dac_dsm2.vhd
add_fileset_file dac_dsm2_top.vhd VHDL PATH ../Hardware/sigma_delta_dac_dual_loop/trunk/dsm2/dac_dsm2_top.vhd
add_fileset_file bank_manager_p.v VERILOG PATH ../Hardware/bank_manager/bank_manager_p.v
add_fileset_file phase_bank_p.v VERILOG PATH ../Hardware/bank_manager/phase_bank_p.v
add_fileset_file quarter_sine_p.v VERILOG PATH ../Hardware/bank_manager/quarter_sine_p.v
add_fileset_file synthesizer_top_p.v VERILOG PATH ../Hardware/synthesizer_top/synthesizer_top_p.v TOP_LEVEL_FILE
add_fileset_file state_variable_filter_iir_p.v VERILOG PATH ../Hardware/state_variable_filter_iir/state_variable_filter_iir_p.v

add_fileset SIM_VERILOG SIM_VERILOG "" ""
set_fileset_property SIM_VERILOG TOP_LEVEL synthesizer_top_p
set_fileset_property SIM_VERILOG ENABLE_RELATIVE_INCLUDE_PATHS false
set_fileset_property SIM_VERILOG ENABLE_FILE_OVERWRITE_MODE false
add_fileset_file quarter_sine_lut.v VERILOG PATH ../Hardware/bank_manager/quarter_sine_lut.v
add_fileset_file lpm_multiplier.v VERILOG PATH ../Hardware/state_variable_filter_iir/lpm_multiplier.v
add_fileset_file clk_slow.v VERILOG PATH ../Hardware/synthesizer_top/clk_slow.v
add_fileset_file mixer.v VERILOG PATH ../Hardware/mixer/mixer.v
add_fileset_file dac_dsm2.vhd VHDL PATH ../Hardware/sigma_delta_dac_dual_loop/trunk/dsm2/dac_dsm2.vhd
add_fileset_file dac_dsm2_top.vhd VHDL PATH ../Hardware/sigma_delta_dac_dual_loop/trunk/dsm2/dac_dsm2_top.vhd
add_fileset_file bank_manager_p.v VERILOG PATH ../Hardware/bank_manager/bank_manager_p.v
add_fileset_file phase_bank_p.v VERILOG PATH ../Hardware/bank_manager/phase_bank_p.v
add_fileset_file quarter_sine_p.v VERILOG PATH ../Hardware/bank_manager/quarter_sine_p.v
add_fileset_file synthesizer_top_p.v VERILOG PATH ../Hardware/synthesizer_top/synthesizer_top_p.v
add_fileset_file state_variable_filter_iir_p.v VERILOG PATH ../Hardware/state_variable_filter_iir/state_variable_filter_iir_p.v


# 
# parameters
# 
add_parameter NSAMPLES INTEGER 100
set_parameter_property NSAMPLES DEFAULT_VALUE 100
set_parameter_property NSAMPLES DISPLAY_NAME NSAMPLES
set_parameter_property NSAMPLES TYPE INTEGER
set_parameter_property NSAMPLES UNITS None
set_parameter_property NSAMPLES ALLOWED_RANGES -2147483648:2147483647
set_parameter_property NSAMPLES HDL_PARAMETER true


# 
# module assignments
# 
set_module_assignment embeddedsw.dts.compatible dev,synthesizer
set_module_assignment embeddedsw.dts.group synthesizer
set_module_assignment embeddedsw.dts.vendor jduchniewicz


# 
# display items
# 


# 
# connection point clock
# 
add_interface clock clock end
set_interface_property clock clockRate 0
set_interface_property clock ENABLED true
set_interface_property clock EXPORT_OF ""
set_interface_property clock PORT_NAME_MAP ""
set_interface_property clock CMSIS_SVD_VARIABLES ""
set_interface_property clock SVD_ADDRESS_GROUP ""

add_interface_port clock clk clk Input 1


# 
# connection point reset
# 
add_interface reset reset end
set_interface_property reset associatedClock clock
set_interface_property reset synchronousEdges DEASSERT
set_interface_property reset ENABLED true
set_interface_property reset EXPORT_OF ""
set_interface_property reset PORT_NAME_MAP ""
set_interface_property reset CMSIS_SVD_VARIABLES ""
set_interface_property reset SVD_ADDRESS_GROUP ""

add_interface_port reset reset reset Input 1


# 
# connection point s0
# 
add_interface s0 avalon end
set_interface_property s0 addressUnits WORDS
set_interface_property s0 associatedClock clock
set_interface_property s0 associatedReset reset
set_interface_property s0 bitsPerSymbol 8
set_interface_property s0 burstOnBurstBoundariesOnly false
set_interface_property s0 burstcountUnits WORDS
set_interface_property s0 explicitAddressSpan 0
set_interface_property s0 holdTime 0
set_interface_property s0 linewrapBursts false
set_interface_property s0 maximumPendingReadTransactions 0
set_interface_property s0 maximumPendingWriteTransactions 0
set_interface_property s0 readLatency 0
set_interface_property s0 readWaitTime 1
set_interface_property s0 setupTime 0
set_interface_property s0 timingUnits Cycles
set_interface_property s0 writeWaitTime 0
set_interface_property s0 ENABLED true
set_interface_property s0 EXPORT_OF ""
set_interface_property s0 PORT_NAME_MAP ""
set_interface_property s0 CMSIS_SVD_VARIABLES ""
set_interface_property s0 SVD_ADDRESS_GROUP ""

add_interface_port s0 avs_s0_write write Input 1
add_interface_port s0 avs_s0_read read Input 1
add_interface_port s0 avs_s0_writedata writedata Input 32
add_interface_port s0 avs_s0_readdata readdata Output 32
set_interface_assignment s0 embeddedsw.configuration.isFlash 0
set_interface_assignment s0 embeddedsw.configuration.isMemoryDevice 0
set_interface_assignment s0 embeddedsw.configuration.isNonVolatileStorage 0
set_interface_assignment s0 embeddedsw.configuration.isPrintableDevice 0


# 
# connection point dac_out
# 
add_interface dac_out conduit end
set_interface_property dac_out associatedClock clock
set_interface_property dac_out associatedReset reset
set_interface_property dac_out ENABLED true
set_interface_property dac_out EXPORT_OF ""
set_interface_property dac_out PORT_NAME_MAP ""
set_interface_property dac_out CMSIS_SVD_VARIABLES ""
set_interface_property dac_out SVD_ADDRESS_GROUP ""

add_interface_port dac_out o_dac_out export Output 1


# 
# connection point ss0
# 
add_interface ss0 avalon_streaming start
set_interface_property ss0 associatedClock clock
set_interface_property ss0 associatedReset reset
set_interface_property ss0 dataBitsPerSymbol 8
set_interface_property ss0 errorDescriptor ""
set_interface_property ss0 firstSymbolInHighOrderBits true
set_interface_property ss0 maxChannel 0
set_interface_property ss0 readyLatency 0
set_interface_property ss0 ENABLED true
set_interface_property ss0 EXPORT_OF ""
set_interface_property ss0 PORT_NAME_MAP ""
set_interface_property ss0 CMSIS_SVD_VARIABLES ""
set_interface_property ss0 SVD_ADDRESS_GROUP ""

add_interface_port ss0 aso_ss0_data data Output 32

