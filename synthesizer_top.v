// Top level module for Synthesizer project

// buttons should be wired here, as well as inputs from Device Tree and outputs to SDRAM
module synthesizer_top(input clk,
							  input [15:0] i_data,
							  output [15:0] o_signal); // for now this is stored in o_signal, no need for reg
	
	reg [15:0] r_last_data, r_oneshot_data;
	//reg [15:0] r_tmp_signal;
	
	bank_manager bm(.clk(clk), .i_data(r_oneshot_data), .o_signal(o_signal));
	// noise adder -> not necessary
	// filter
	// effects?
	// adsr
	// aftereffects
	
	initial r_last_data = 16'b0;
	initial r_oneshot_data = 16'b0;
	//initial r_tmp_signal = 16'b0;

	always @ (posedge clk) begin // this will trigger new signal to bm just once
		if (r_last_data !== i_data) begin
			r_oneshot_data <= i_data;
			r_last_data <= i_data;
		end else if (r_last_data == i_data) begin
			r_oneshot_data <= 16'b0;
		end
	end
					 
endmodule
