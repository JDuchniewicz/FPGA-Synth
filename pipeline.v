/*
	Pipeline module, responsible for managing synchronisation in terms of one signal processing pipeline
	Comprises of phase_bank, LUT's, Filters, ADSR?, Effects?
*/

// it would be wise to create some kind of more sophisticated looping system (for example queue?), need to be considered
module pipeline(input clk,
					 input rst,
					 input[15:0] i_data,
					 output reg rdy,
					 output reg[15:0] o_signal
					);

	
					
	wire 		  w_cmd;
	wire[6:0]  w_midi;
	wire[7:0]  w_vel;
	
	initial o_signal = 16'b0;
	
	assign w_cmd = i_data[15]; // maybe there should be more commands?
	assign w_midi = i_data[14:8];
	assign w_vel = i_data[7:0];
	
	quarter_sine lut(.clk(clk), .i_phase(), .o_val());
	phase_bank pb(.clk(clk), .i_cmd(), .i_midi(), .o_state(), .o_phase());
	state_variable_filter_iir SVF(.clk(clk), .rst(), .ena(), .i_midi(), .i_data(), .o_filtered());
	
	
					
endmodule
