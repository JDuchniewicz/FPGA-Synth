
// In this file will be added all hierarchical processing blocks imported from other places, BDF is just the design file (cannot? make use of it)
// read up about naming conventions etc, verilog is unwieldy

// TODO: 
// add the pool of currently available phase accumulator modules
// refactor a4dummy to be such module
// write a module which can quickly calculate frequency_step for phase increment (division mitigation)

// write a python script for generation of data - DONE for sine
// check bus widths
// optimize waveform space constraints (store just quarter of full period)
// finally plug this module into the board and test against real signals

// add 'manager' module to ask for generation of signal from one of free pools
// this module will properly trigger signals in other modules and will trigger effects? via pushbuttons and knobs

// DONE:
// write a testbench for Synthesizer and test it offline - DONE, looks fine

// KNOWLEDGE:
// CURRENTLY 3 clock cycles delay until value is valid (delay)
// Clock multiplier has to be wired before launching this module
module Synthesizer(clk, data_in, data_out); 
	
	input clk;
	input [15:0] data_in;
	output reg [15:0] data_out; //probably 24?
	
	//wire[15:0] freq_in;
	wire[15:0] signal_out; //width?
	
	dummyA4 a4(.clk(clk), .val_out(signal_out)); //how to wire up more? need a bank system for that
	
	always @ (posedge clk) begin
		case (data_in[15:8])
			// take care of different midi values
			
			8'h3f		:	data_out <= signal_out;
			default	:	data_out <= 16'b0;
		endcase
	end

endmodule
