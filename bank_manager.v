
// In this file will be added all hierarchical processing blocks imported from other places, BDF is just the design file (cannot? make use of it)
// read up about naming conventions etc, verilog is unwieldy

// TODO:
// check bus widths
// finally plug this module into the board and test against real signals
// add module for reading input from linux and pushing this one just once, then feeding zeroes
// this module will properly trigger signals in other modules and will trigger effects? via pushbuttons and knobs
// add module for writing to sdram
// SPI to DAC - MASH?

// REFACTOR!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// add concept of pipeline, move all that can be moved there and perform signalling generation etc from here
// here should remain only the part responsible for signal samples generation each cycle and signalling proper pipelines, registers that tell what their state is
// should be inside, along with midi stuff, filtering is done per pipeline and final signal of pipeline is to be delivered by an out reg by itself

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
						 output reg signed[15:0] o_signal); 
						 
	localparam IDLE = 2'b00, BSY = 2'b01, RDY = 2'b10;					
	
	wire[1:0] w_st0, w_st1, w_st2, w_st3, w_st4,
				 w_st5, w_st6, w_st7, w_st8, w_st9;
				 
	reg[15:0] r_data0, r_data1, r_data2, r_data3, r_data4,
				 r_data5, r_data6, r_data7, r_data8, r_data9;
				 
	wire signed[15:0] w_signal0, w_signal1, w_signal2, w_signal3, w_signal4,
							w_signal5, w_signal6, w_signal7, w_signal8, w_signal9;
				  
	reg[6:0]   r_midi0, r_midi1, r_midi2, r_midi3, r_midi4,
				  r_midi5, r_midi6, r_midi7, r_midi8, r_midi9;
				  
	reg rst;
				  
	integer v_idx;
	
	wire 		  w_cmd;
	wire[6:0]  w_midi;
	
	assign w_cmd = i_data[15]; // maybe there should be more commands?
	assign w_midi = i_data[14:8];
	
	pipeline
				p0(.clk(clk), .rst(rst), .i_data(r_data0), .o_state(w_st0), .o_signal(w_signal0)),
				p1(.clk(clk), .rst(rst), .i_data(r_data1), .o_state(w_st1), .o_signal(w_signal1)),
				p2(.clk(clk), .rst(rst), .i_data(r_data2), .o_state(w_st2), .o_signal(w_signal2)),
				p3(.clk(clk), .rst(rst), .i_data(r_data3), .o_state(w_st3), .o_signal(w_signal3)),
				p4(.clk(clk), .rst(rst), .i_data(r_data4), .o_state(w_st4), .o_signal(w_signal4)),
				p5(.clk(clk), .rst(rst), .i_data(r_data5), .o_state(w_st5), .o_signal(w_signal5)),
				p6(.clk(clk), .rst(rst), .i_data(r_data6), .o_state(w_st6), .o_signal(w_signal6)),
				p7(.clk(clk), .rst(rst), .i_data(r_data7), .o_state(w_st7), .o_signal(w_signal7)),
				p8(.clk(clk), .rst(rst), .i_data(r_data8), .o_state(w_st8), .o_signal(w_signal8)),
				p9(.clk(clk), .rst(rst), .i_data(r_data9), .o_state(w_st9), .o_signal(w_signal9));
				
	initial begin
		v_idx = 0;
		o_signal = 16'b0;
		rst = 1'b0;
		
		r_data0 = 16'b0;
		r_data1 = 16'b0;
		r_data2 = 16'b0;
		r_data3 = 16'b0;
		r_data4 = 16'b0;
		r_data5 = 16'b0;
		r_data6 = 16'b0;
		r_data7 = 16'b0;
		r_data8 = 16'b0;
		r_data9 = 16'b0;
		
		r_midi0 = 7'b0;
		r_midi1 = 7'b0;
		r_midi2 = 7'b0;
		r_midi3 = 7'b0;
		r_midi4 = 7'b0;
		r_midi5 = 7'b0;
		r_midi6 = 7'b0;
		r_midi7 = 7'b0;
		r_midi8 = 7'b0;
		r_midi9 = 7'b0;
	end
	
	// bank manager should ping each pipeline to do its work
	// and at proper intervals collect input from them
	// it should give out a signal to the synthesizer top, which at a different clock will sample them to DAC
	
	// Write new tests, continue with creating elements of the pipeline, for now just try to issue a signal to enter it and exit it
	// then ADSR
	
	always @ (posedge clk) begin
		if (w_cmd == 1) begin // START, find free bank and signal to pipeline
			if (w_st0 == IDLE) begin
				r_midi0 <= w_midi;
				r_data0 <= i_data;
			end else if (w_st1 == IDLE) begin
				r_midi1 <= w_midi;
				r_data1 <= i_data;
			end else if (w_st2 == IDLE) begin
				r_midi2 <= w_midi;
				r_data2 <= i_data;			
			end else if (w_st3 == IDLE) begin
				r_midi3 <= w_midi;
				r_data3 <= i_data;
			end else if (w_st4 == IDLE) begin
				r_midi4 <= w_midi;
				r_data4 <= i_data;
			end else if (w_st5 == IDLE) begin
				r_midi5 <= w_midi;
				r_data5 <= i_data;
			end else if (w_st6 == IDLE) begin
				r_midi6 <= w_midi;
				r_data6 <= i_data;
			end else if (w_st7 == IDLE) begin
				r_midi7 <= w_midi;
				r_data7 <= i_data;
			end else if (w_st8 == IDLE) begin
				r_midi8 <= w_midi;
				r_data8 <= i_data;
			end else if (w_st9 == IDLE) begin
				r_midi9 <= w_midi;
				r_data9 <= i_data;
			end // failure to playback yet another sound should be signalled to user!
		end else if(w_cmd == 0) begin // STOP, check if any register contains this midi already
			if (w_midi == 7'h7f) begin // STOP_ALL
				r_midi0 <= 7'h0;
				r_midi1 <= 7'h0;
				r_midi2 <= 7'h0;
				r_midi3 <= 7'h0;
				r_midi4 <= 7'h0;
				r_midi5 <= 7'h0;
				r_midi6 <= 7'h0;
				r_midi7 <= 7'h0;
				r_midi8 <= 7'h0;
				r_midi9 <= 7'h0;
				rst <= 1'b1;
			end else if (w_st0 !== IDLE && r_midi0 == w_midi) begin
				r_midi0 <= 7'h0; // MIDI 0 is equal to turn off
				r_data0 <= 16'b0;
			end else if (w_st1 !== IDLE && r_midi1 == w_midi) begin
				r_midi1 <= 7'h0;
				r_data1 <= 16'b0;
			end else if (w_st2 !== IDLE && r_midi2 == w_midi) begin
				r_midi2 <= 7'h0;
				r_data2 <= 16'b0;
			end else if (w_st3 !== IDLE && r_midi3 == w_midi) begin
				r_midi3 <= 7'h0;
				r_data3 <= 16'b0;
			end else if (w_st4 !== IDLE && r_midi4 == w_midi) begin
				r_midi4 <= 7'h0;
				r_data4 <= 16'b0;
			end else if (w_st5 !== IDLE && r_midi5 == w_midi) begin
				r_midi5 <= 7'h0;
				r_data5 <= 16'b0;
			end else if (w_st6 !== IDLE && r_midi6 == w_midi) begin
				r_midi6 <= 7'h0;
				r_data6 <= 16'b0;
			end else if (w_st7 !== IDLE && r_midi7 == w_midi) begin
				r_midi7 <= 7'h0;
				r_data7 <= 16'b0;
			end else if (w_st8 !== IDLE && r_midi8 == w_midi) begin
				r_midi8 <= 7'h0;
				r_data8 <= 16'b0;
			end else if (w_st9 !== IDLE && r_midi9 == w_midi) begin
				r_midi9 <= 7'h0;
				r_data9 <= 16'b0;
			end
		end
		
		// To be refactored to something more efficient
		// loop around the banks and output a value from one of them, if some are empty do nothing for now (this should be optimized)
		// maybe just output values from ones that are not empty?, this will have to be signalled further down the pipeline (size of window?) ask mr Zabołotny
		if (v_idx == 0 && w_st0 == 1) begin // it may be not valid here yet!!! just knowing it is working
			o_signal <= w_signal0;
		end else if (v_idx == 1 && w_st1 == RDY) begin
			o_signal <= w_signal1;
		end else if (v_idx == 2 && w_st2 == RDY) begin
			o_signal <= w_signal2;		
		end else if (v_idx == 3 && w_st3 == RDY) begin
			o_signal <= w_signal3;		
		end else if (v_idx == 4 && w_st4 == RDY) begin
			o_signal <= w_signal4;		
		end else if (v_idx == 5 && w_st5 == RDY) begin
			o_signal <= w_signal5;		
		end else if (v_idx == 6 && w_st6 == RDY) begin
			o_signal <= w_signal6;		
		end else if (v_idx == 7 && w_st7 == RDY) begin
			o_signal <= w_signal7;		
		end else if (v_idx == 8 && w_st8 == RDY) begin
			o_signal <= w_signal8;		
		end else if (v_idx == 9 && w_st9 == RDY) begin
			o_signal <= w_signal9;
		end
		if (v_idx == 9)
			v_idx <= 0;
		else
			v_idx <= v_idx + 1;
	end

endmodule
