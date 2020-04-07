// Testbench for state_variable_filter_iir

`timescale 1ns/1ps

module state_variable_filter_iir_tb;
	// in
	reg clk, rst, ena, r_cmd;
	reg signed[6:0] r_midi;
	
	// out
	wire signed[15:0] w_filtered;
	
	// connect
	wire[15:0] w_phase;
	wire signed[15:0] w_sine;
	
	wire w_cmd, w_st; // is w_st not signalling 'ena'? check

	quarter_sine 					slut(.clk(clk), .i_phase(w_phase), .o_val(w_sine));
	phase_bank 						pb(.clk(clk), .i_cmd(r_cmd), .i_midi(r_midi), .o_state(w_st), .o_phase(w_phase));
	state_variable_filter_iir  SVF(.clk(clk), .rst(rst), .ena(ena), .i_midi(r_midi), .i_data(w_sine), .o_filtered(w_filtered));
	
	// TODO: finish TB (probably communicate signalling with phase banks (may need refactoring the big module))
	// add reasonable tests, check clocking, then adjust filter state machine

	// Looks like lpm_mults need to be tested in terms of delays a'priori, separate testbenches for them
	// then states may need to be adjusted and overall pipeline speed may have to be adjusted
	// this is the bottleneck, no point in generating more samples so quickly if filter is stalling the pipeline
	// need to think on how to adjust the speeds of generated signals so that I fit in some windows, 
	
	// maybe the filter modules just need a different clock (slower), still the question what to do with to high speed of generation of waveforms remains
	
	// update 06.04 22:00 looks like multiplication works just fine?, chaining the pipelines seems to be weird - 22:30 - started working :), busses were not connected properly
	//	update 07.04 12:30 seems to be working pretty fine, 3 cycles of delay after obtainig input, time for pipeline assembly!
	initial begin
		clk = 0;
		rst = 0;
		ena = 0;
		r_midi = 7'b0;
		r_cmd = 0;
		#10// stabilization wait (maybe shorter)
	@ (negedge clk); //use negedge here because at posedge we make changes in module
	
	$display("[%t] Start single note - A4", $time); // There is probably  currently no way to reenable 'ena' signal each time the filter is done, and input is already ready
	r_midi = 7'b1000101; // START A4
	r_cmd = 1'b1;
	// the phase bank should signal ena only when the first sample has already been calculated - right now it is delay of
	#6 //tweak the delay from quarter sine with enable, it has to signal on a first valid input that it is ready
	ena = 1'b1;
	#30 // 6 cycles of clock done
	$display("[%t] Stop single note - A4", $time);
	r_midi = 7'b1000101; // STOP A4
	r_cmd = 1'b0;
	rst = 1; // in proper pipeline, pass midi 0 inside
	#10 // observe zero output
	$display("[%t] Start single note - F5", $time);
	r_midi = 7'b1001101; // START F5
	r_cmd = 1'b1;
	rst = 0;
	#30
	$display("[%t] Stop single note - F5", $time);
	r_midi = 7'b1001101; // STOP F5
	r_cmd = 1'b0;
	rst = 1;
	#10 							
	$display("[%t] Done", $time);
	$finish; // not testing velocity for now
	end
	
	always #1 clk = ~clk;
endmodule
