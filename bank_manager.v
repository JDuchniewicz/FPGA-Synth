
// In this file will be added all hierarchical processing blocks imported from other places, BDF is just the design file (cannot? make use of it)
// read up about naming conventions etc, verilog is unwieldy

// TODO:
// check bus widths
// finally plug this module into the board and test against real signals
// add module for reading input from linux and pushing this one just once, then feeding zeroes
// this module will properly trigger signals in other modules and will trigger effects? via pushbuttons and knobs
// add module for writing to sdram
// SPI to DAC - MASH?

// DONE:
// write a testbench for Synthesizer and test it offline - DONE, looks fine
// write a python script for generation of data - DONE for sine
// optimize waveform space constraints (store just quarter of full period)
// add 'manager' module to ask for generation of signal from one of free pools
// add the pool of currently available phase accumulator modules

// KNOWLEDGE:
// CURRENTLY 1 clock cycle delay, cannot be minimalized, demux current input and obtain value back has to work
// Clock multiplier has to be wired before launching this module
// SDRAM can be used as buffer for holding data, addressing is by 32 bits - 1 address (check it), obtain memory and map it
// i_data 16'b0'1111111'xxxxxxxx is STOP_ALL cmd - there is no MIDI 0 available
// DELAYS
// 3 cycles sine generation from LUT
// up to 10 cycles for one phase bank (to be available on output)
// 2 cycles delay between valid input
// after putting valid value, input 0s to prevent activation of new bank on next clock cycle

// TIP: this is not C++/C, you connect wires to logic, no need for nesting modules (cascading), just connect it inside

module bank_manager(input clk,
						 input[15:0] i_data,
						 output reg[15:0] o_signal); 
						
	wire[15:0] w_phase0, w_phase1, w_phase2, w_phase3, w_phase4,
				  w_phase5, w_phase6, w_phase7, w_phase8, w_phase9,
				  w_sine0, w_sine1, w_sine2, w_sine3, w_sine4, 
				  w_sine5, w_sine6, w_sine7, w_sine8, w_sine9;
				  
	wire		  w_st0, w_st1, w_st2, w_st3, w_st4,
				  w_st5, w_st6, w_st7, w_st8, w_st9;
				  
	reg 		  r_cmd0, r_cmd1, r_cmd2, r_cmd3, r_cmd4,
				  r_cmd5, r_cmd6, r_cmd7, r_cmd8, r_cmd9;
				  
	reg[6:0]   r_midi0, r_midi1, r_midi2, r_midi3, r_midi4,
				  r_midi5, r_midi6, r_midi7, r_midi8, r_midi9;
				  
	integer v_idx;
	
	// should it be done? CHECK WHICH SHOULD BE REGISTERS?
	wire 		  w_cmd;
	wire[6:0]  w_midi;
	wire[7:0]  w_vel;
	
	initial v_idx = 0;
	initial o_signal = 16'b0;
	
	assign w_cmd = i_data[15]; // maybe there should be more commands?
	assign w_midi = i_data[14:8];
	assign w_vel = i_data[7:0]; // this is passed further to waveshaping modules, route it out?
	
	quarter_sine // there should be more LUT's for more waveforms
					slut_0(.clk(clk), .i_phase(w_phase0), .o_val(w_sine0)),
					slut_1(.clk(clk), .i_phase(w_phase1), .o_val(w_sine1)),
					slut_2(.clk(clk), .i_phase(w_phase2), .o_val(w_sine2)),
					slut_3(.clk(clk), .i_phase(w_phase3), .o_val(w_sine3)),
					slut_4(.clk(clk), .i_phase(w_phase4), .o_val(w_sine4)),
					slut_5(.clk(clk), .i_phase(w_phase5), .o_val(w_sine5)),
					slut_6(.clk(clk), .i_phase(w_phase6), .o_val(w_sine6)),
					slut_7(.clk(clk), .i_phase(w_phase7), .o_val(w_sine7)),
					slut_8(.clk(clk), .i_phase(w_phase8), .o_val(w_sine8)),
					slut_9(.clk(clk), .i_phase(w_phase9), .o_val(w_sine9));
	
	phase_bank 
					pb_0(.clk(clk), .i_cmd(r_cmd0), .i_midi(r_midi0), .o_state(w_st0), .o_phase(w_phase0)), 
					pb_1(.clk(clk), .i_cmd(r_cmd1), .i_midi(r_midi1), .o_state(w_st1), .o_phase(w_phase1)), 
					pb_2(.clk(clk), .i_cmd(r_cmd2), .i_midi(r_midi2), .o_state(w_st2), .o_phase(w_phase2)), 
					pb_3(.clk(clk), .i_cmd(r_cmd3), .i_midi(r_midi3), .o_state(w_st3), .o_phase(w_phase3)),
					pb_4(.clk(clk), .i_cmd(r_cmd4), .i_midi(r_midi4), .o_state(w_st4), .o_phase(w_phase4)), 
					pb_5(.clk(clk), .i_cmd(r_cmd5), .i_midi(r_midi5), .o_state(w_st5), .o_phase(w_phase5)), 
					pb_6(.clk(clk), .i_cmd(r_cmd6), .i_midi(r_midi6), .o_state(w_st6), .o_phase(w_phase6)), 
					pb_7(.clk(clk), .i_cmd(r_cmd7), .i_midi(r_midi7), .o_state(w_st7), .o_phase(w_phase7)), 
					pb_8(.clk(clk), .i_cmd(r_cmd8), .i_midi(r_midi8), .o_state(w_st8), .o_phase(w_phase8)),
					pb_9(.clk(clk), .i_cmd(r_cmd9), .i_midi(r_midi9), .o_state(w_st9), .o_phase(w_phase9));
	
	// output value from different bank every cycle until banks have ended
	// val_out is written dependent on bank_idx
	// just one command may be served at one cycle
	/* // THIS CREATES LATCHING PROBLEMS
	always @* begin
		// they should be initialized???
		if (w_cmd == 1) begin // START, find free bank and signal to process
			if (w_st0 == 0) begin
				r_midi0 = w_midi; // LOOKS like cmd's are redundant, non-zero midi value implies command :)
				r_cmd0 = 1;
			end if (w_st1 == 0) begin
				r_midi1 = w_midi;
				r_cmd1 = 1;
			end if (w_st2 == 0) begin
				r_midi2 = w_midi;
				r_cmd2 = 1;			
			end if (w_st3 == 0) begin
				r_midi3 = w_midi;
				r_cmd3 = 1;
			end if (w_st4 == 0) begin
				r_midi4 = w_midi;
				r_cmd4 = 1;
			end if (w_st5 == 0) begin
				r_midi5 = w_midi;
				r_cmd5 = 1;
			end if (w_st6 == 0) begin
				r_midi6 = w_midi;
				r_cmd6 = 1;
			end if (w_st7 == 0) begin
				r_midi7 = w_midi;
				r_cmd7 = 1;
			end if (w_st8 == 0) begin
				r_midi8 = w_midi;
				r_cmd8 = 1;
			end if (w_st9 == 0) begin
				r_midi9 = w_midi;
				r_cmd9 = 1;
			end
		end else if(w_cmd == 0) begin // STOP, check if any register contains this midi already
			if (w_st0 == 0 && r_midi0 == w_midi) begin
				r_midi0 = 7'h7f; // 7 bits '1'
				r_cmd0 = 0;
			end if (w_st1 == 0 && r_midi1 == w_midi) begin
				r_midi1 = 7'h7f;
				r_cmd1 = 0;
			end if (w_st2 == 0 && r_midi2 == w_midi) begin
				r_midi2 = 7'h7f;
				r_cmd2 = 0;
			end if (w_st3 == 0 && r_midi3 == w_midi) begin
				r_midi3 = 7'h7f;
				r_cmd3 = 0;
			end if (w_st4 == 0 && r_midi4 == w_midi) begin
				r_midi4 = 7'h7f;
				r_cmd4 = 0;
			end if (w_st5 == 0 && r_midi5 == w_midi) begin
				r_midi5 = 7'h7f;
				r_cmd5 = 0;
			end if (w_st6 == 0 && r_midi6 == w_midi) begin
				r_midi6 = 7'h7f;
				r_cmd6 = 0;
			end if (w_st7 == 0 && r_midi7 == w_midi) begin
				r_midi7 = 7'h7f;
				r_cmd7 = 0;
			end if (w_st8 == 0 && r_midi8 == w_midi) begin
				r_midi8 = 7'h7f;
				r_cmd8 = 0;
			end if (w_st9 == 0 && r_midi9 == w_midi) begin
				r_midi9 = 7'h7f;
				r_cmd9 = 0;
			end // it looks like latches are inferred each time a comibnatorial path does not set r_midi or r_cmd even if it does not
			// use it, becasue of that they have to be set in every conditional path???!
		end
	end
*/
	always @ (posedge clk) begin
		if (w_cmd == 1) begin // START, find free bank and signal to process
			if (w_st0 == 0) begin
				r_midi0 <= w_midi; // LOOKS like cmd's are redundant, non-zero midi value implies command :)
				r_cmd0 <= 1;
			end else if (w_st1 == 0) begin
				r_midi1 <= w_midi;
				r_cmd1 <= 1;
			end else if (w_st2 == 0) begin
				r_midi2 <= w_midi;
				r_cmd2 <= 1;			
			end else if (w_st3 == 0) begin
				r_midi3 <= w_midi;
				r_cmd3 <= 1;
			end else if (w_st4 == 0) begin
				r_midi4 <= w_midi;
				r_cmd4 <= 1;
			end else if (w_st5 == 0) begin
				r_midi5 <= w_midi;
				r_cmd5 <= 1;
			end else if (w_st6 == 0) begin
				r_midi6 <= w_midi;
				r_cmd6 <= 1;
			end else if (w_st7 == 0) begin
				r_midi7 <= w_midi;
				r_cmd7 <= 1;
			end else if (w_st8 == 0) begin
				r_midi8 <= w_midi;
				r_cmd8 <= 1;
			end else if (w_st9 == 0) begin
				r_midi9 <= w_midi;
				r_cmd9 <= 1;
			end // failure to playback yet another sound should be signalled to user!
		end else if(w_cmd == 0) begin // STOP, check if any register contains this midi already
			if (w_midi == 7'h7f) begin // STOP_ALL
				r_midi0 <= 7'h7f;
				r_midi1 <= 7'h7f;
				r_midi2 <= 7'h7f;
				r_midi3 <= 7'h7f;
				r_midi4 <= 7'h7f;
				r_midi5 <= 7'h7f;
				r_midi6 <= 7'h7f;
				r_midi7 <= 7'h7f;
				r_midi8 <= 7'h7f;
				r_midi9 <= 7'h7f;
				r_cmd0 <= 0;
				r_cmd1 <= 0;
				r_cmd2 <= 0;
				r_cmd3 <= 0;
				r_cmd4 <= 0;
				r_cmd5 <= 0;
				r_cmd6 <= 0;
				r_cmd7 <= 0;
				r_cmd8 <= 0;
				r_cmd9 <= 0;
			end else if (w_st0 == 1 && r_midi0 == w_midi) begin
				r_midi0 <= 7'h7f; // 7 bits '1'
				r_cmd0 <= 0;
			end else if (w_st1 == 1 && r_midi1 == w_midi) begin
				r_midi1 <= 7'h7f;
				r_cmd1 <= 0;
			end else if (w_st2 == 1 && r_midi2 == w_midi) begin
				r_midi2 <= 7'h7f;
				r_cmd2 <= 0;
			end else if (w_st3 == 1 && r_midi3 == w_midi) begin
				r_midi3 <= 7'h7f;
				r_cmd3 <= 0;
			end else if (w_st4 == 1 && r_midi4 == w_midi) begin
				r_midi4 <= 7'h7f;
				r_cmd4 <= 0;
			end else if (w_st5 == 1 && r_midi5 == w_midi) begin
				r_midi5 <= 7'h7f;
				r_cmd5 <= 0;
			end else if (w_st6 == 1 && r_midi6 == w_midi) begin
				r_midi6 <= 7'h7f;
				r_cmd6 <= 0;
			end else if (w_st7 == 1 && r_midi7 == w_midi) begin
				r_midi7 <= 7'h7f;
				r_cmd7 <= 0;
			end else if (w_st8 == 1 && r_midi8 == w_midi) begin
				r_midi8 <= 7'h7f;
				r_cmd8 <= 0;
			end else if (w_st9 == 1 && r_midi9 == w_midi) begin
				r_midi9 <= 7'h7f;
				r_cmd9 <= 0;
			end // it looks like latches are inferred each time a comibnatorial path does not set r_midi or r_cmd even if it does not
			// use it, becasue of that they have to be set in every conditional path???!
		end
		
		// loop around the banks and output a value from one of them, if some are empty do nothing for now (this should be optimized)
		// maybe just output values from ones that are not empty?, this will have to be signalled further down the pipeline (size of window?) ask mr Zabołotny
		if (v_idx == 0 && w_st0 == 1) begin // it may be not valid here yet!!! just knowing it is working
			o_signal <= w_sine0;
		end else if (v_idx == 1 && w_st1 == 1) begin
			o_signal <= w_sine1;
		end else if (v_idx == 2 && w_st2 == 1) begin
			o_signal <= w_sine2;		
		end else if (v_idx == 3 && w_st3 == 1) begin
			o_signal <= w_sine3;		
		end else if (v_idx == 4 && w_st4 == 1) begin
			o_signal <= w_sine4;		
		end else if (v_idx == 5 && w_st5 == 1) begin
			o_signal <= w_sine5;		
		end else if (v_idx == 6 && w_st6 == 1) begin
			o_signal <= w_sine6;		
		end else if (v_idx == 7 && w_st7 == 1) begin
			o_signal <= w_sine7;		
		end else if (v_idx == 8 && w_st8 == 1) begin
			o_signal <= w_sine8;		
		end else if (v_idx == 9 && w_st9 == 1) begin
			o_signal <= w_sine9;
		end
		if (v_idx == 9)
			v_idx <= 0;
		else
			v_idx <= v_idx + 1;
	end

endmodule
