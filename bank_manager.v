
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
						  input clk_slow,
						  input clk_en,
						  input reset,
						  input[15:0] i_data,
						  output reg signed[15:0] o_signal,
						  output reg signed[3:0] o_idx); 
						 
	localparam IDLE = 2'b00, BSY = 2'b01, RDY = 2'b10;					
	
	wire[1:0] w_st0, w_st1, w_st2, w_st3, w_st4, // these states seem to be useless other than for debug? (but still not of use) BM is the master, pipeline does not have any power
				 w_st5, w_st6, w_st7, w_st8, w_st9;
				 
	reg[15:0] r_data0, r_data1, r_data2, r_data3, r_data4,
				 r_data5, r_data6, r_data7, r_data8, r_data9;
	
	wire [13:0] w_lut_input_0, w_lut_input_1, w_lut_input_2, w_lut_input_3, w_lut_input_4,
					w_lut_input_5, w_lut_input_6, w_lut_input_7, w_lut_input_8, w_lut_input_9;
	
	reg [13:0] r_lut_input_direct;
								
	reg signed [15:0] r_lut_output_0, r_lut_output_1, r_lut_output_2, r_lut_output_3, r_lut_output_4,
							r_lut_output_5, r_lut_output_6, r_lut_output_7, r_lut_output_8, r_lut_output_9;
				 
	wire signed[15:0] w_signal0, w_signal1, w_signal2, w_signal3, w_signal4,
							w_signal5, w_signal6, w_signal7, w_signal8, w_signal9,
							w_lut_output_direct;
				  
	reg[6:0]   r_midi0, r_midi1, r_midi2, r_midi3, r_midi4,
				  r_midi5, r_midi6, r_midi7, r_midi8, r_midi9;
				  
	reg r_rst_pulled; // feels like this reset is just an extended reset from outer components, TODO: rethink?
				  
	integer v_idx;
	
	wire 		  w_cmd;
	wire[6:0]  w_midi;
	
	assign w_cmd = i_data[15]; // maybe there should be more commands?
	assign w_midi = i_data[14:8];
	
	pipeline
				p0(.clk(clk_slow), .clk_en(clk_en), .rst(r_rst_pulled), .i_data(r_data0), .o_lut_input(w_lut_input_0), .i_lut_output(r_lut_output_0), .o_state(w_st0), .o_signal(w_signal0)),
				p1(.clk(clk_slow), .clk_en(clk_en), .rst(r_rst_pulled), .i_data(r_data1), .o_lut_input(w_lut_input_1), .i_lut_output(r_lut_output_1), .o_state(w_st1), .o_signal(w_signal1)),
				p2(.clk(clk_slow), .clk_en(clk_en), .rst(r_rst_pulled), .i_data(r_data2), .o_lut_input(w_lut_input_2), .i_lut_output(r_lut_output_2), .o_state(w_st2), .o_signal(w_signal2)),
				p3(.clk(clk_slow), .clk_en(clk_en), .rst(r_rst_pulled), .i_data(r_data3), .o_lut_input(w_lut_input_3), .i_lut_output(r_lut_output_3), .o_state(w_st3), .o_signal(w_signal3)),
				p4(.clk(clk_slow), .clk_en(clk_en), .rst(r_rst_pulled), .i_data(r_data4), .o_lut_input(w_lut_input_4), .i_lut_output(r_lut_output_4), .o_state(w_st4), .o_signal(w_signal4)),
				p5(.clk(clk_slow), .clk_en(clk_en), .rst(r_rst_pulled), .i_data(r_data5), .o_lut_input(w_lut_input_5), .i_lut_output(r_lut_output_5), .o_state(w_st5), .o_signal(w_signal5)),
				p6(.clk(clk_slow), .clk_en(clk_en), .rst(r_rst_pulled), .i_data(r_data6), .o_lut_input(w_lut_input_6), .i_lut_output(r_lut_output_6), .o_state(w_st6), .o_signal(w_signal6)),
				p7(.clk(clk_slow), .clk_en(clk_en), .rst(r_rst_pulled), .i_data(r_data7), .o_lut_input(w_lut_input_7), .i_lut_output(r_lut_output_7), .o_state(w_st7), .o_signal(w_signal7)),
				p8(.clk(clk_slow), .clk_en(clk_en), .rst(r_rst_pulled), .i_data(r_data8), .o_lut_input(w_lut_input_8), .i_lut_output(r_lut_output_8), .o_state(w_st8), .o_signal(w_signal8)),
				p9(.clk(clk_slow), .clk_en(clk_en), .rst(r_rst_pulled), .i_data(r_data9), .o_lut_input(w_lut_input_9), .i_lut_output(r_lut_output_9), .o_state(w_st9), .o_signal(w_signal9));
	
	// single LUT for all pipelines -> phase bank works on 10 times slower clock than bank_manager
	// For now just clock every pipeline with 10x slower clock, if this is too laggy, then try running each pipeline on two distinct clocks
	quarter_sine_lut slut(.i_phase(r_lut_input_direct), .o_val(w_lut_output_direct));
	// Because of slowing down clock - there is induced a lag on stable output of samples -> filter 3 times the same value will appear because filter takes so much time -> can be minimized later but
	// for now just put it less often into registers :)))
				
	initial begin
		v_idx = 0;
		o_signal = 16'b0;
		r_rst_pulled = 1'b0;
		
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
		
		r_lut_output_0 = 16'b0;
		r_lut_output_1 = 16'b0;
		r_lut_output_2 = 16'b0;
		r_lut_output_3 = 16'b0;
		r_lut_output_4 = 16'b0;
		r_lut_output_5 = 16'b0;
		r_lut_output_6 = 16'b0;
		r_lut_output_7 = 16'b0;
		r_lut_output_8 = 16'b0;
		r_lut_output_9 = 16'b0;
		
		r_lut_input_direct = 14'b0;
	end
	
	// bank manager should ping each pipeline to do its work
	// and at proper intervals collect input from them
	// it should give out a signal to the synthesizer top, which at a different clock will sample them to DAC
	
	// Write new tests, continue with creating elements of the pipeline, for now just try to issue a signal to enter it and exit it
	// then ADSR
	
	always @ (posedge clk) begin
		if (reset) begin
			r_rst_pulled <= 1'b1; // should reset be held?
		end else if (r_rst_pulled) begin 
			o_signal <= 16'b0; // if reset is active, clear the output signal and return it
			r_rst_pulled <= 1'b0;
		end else if (w_cmd == 1) begin // START, find free bank and signal to pipeline
			if (r_midi0 == 7'h0) begin
				r_midi0 <= w_midi;
				r_data0 <= i_data;
			end else if (r_midi1 == 7'h0) begin
				r_midi1 <= w_midi;
				r_data1 <= i_data;
			end else if (r_midi2 == 7'h0) begin
				r_midi2 <= w_midi;
				r_data2 <= i_data;			
			end else if (r_midi3 == 7'h0) begin
				r_midi3 <= w_midi;
				r_data3 <= i_data;
			end else if (r_midi4 == 7'h0) begin
				r_midi4 <= w_midi;
				r_data4 <= i_data;
			end else if (r_midi5 == 7'h0) begin
				r_midi5 <= w_midi;
				r_data5 <= i_data;
			end else if (r_midi6 == 7'h0) begin
				r_midi6 <= w_midi;
				r_data6 <= i_data;
			end else if (r_midi7 == 7'h0) begin
				r_midi7 <= w_midi;
				r_data7 <= i_data;
			end else if (r_midi8 == 7'h0) begin
				r_midi8 <= w_midi;
				r_data8 <= i_data;
			end else if (r_midi9 == 7'h0) begin
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
				r_data0 <= 16'b0;
				r_data1 <= 16'b0;
				r_data2 <= 16'b0;
				r_data3 <= 16'b0;
				r_data4 <= 16'b0;
				r_data5 <= 16'b0;
				r_data6 <= 16'b0;
				r_data7 <= 16'b0;
				r_data8 <= 16'b0;
				r_data9 <= 16'b0;
			end else if (r_midi0 == w_midi) begin
				r_midi0 <= 7'h0; // MIDI 0 is equal to turn off
				r_data0 <= 16'b0;
			end else if (r_midi1 == w_midi) begin
				r_midi1 <= 7'h0;
				r_data1 <= 16'b0;
			end else if (r_midi2 == w_midi) begin
				r_midi2 <= 7'h0;
				r_data2 <= 16'b0;
			end else if (r_midi3 == w_midi) begin
				r_midi3 <= 7'h0;
				r_data3 <= 16'b0;
			end else if (r_midi4 == w_midi) begin
				r_midi4 <= 7'h0;
				r_data4 <= 16'b0;
			end else if (r_midi5 == w_midi) begin
				r_midi5 <= 7'h0;
				r_data5 <= 16'b0;
			end else if (r_midi6 == w_midi) begin
				r_midi6 <= 7'h0;
				r_data6 <= 16'b0;
			end else if (r_midi7 == w_midi) begin
				r_midi7 <= 7'h0;
				r_data7 <= 16'b0;
			end else if (r_midi8 == w_midi) begin
				r_midi8 <= 7'h0;
				r_data8 <= 16'b0;
			end else if (r_midi9 == w_midi) begin
				r_midi9 <= 7'h0;
				r_data9 <= 16'b0;
			end
		end
		
		// To be refactored to something more efficient
		// loop around the banks and output a value from one of them, if some are empty do nothing for now (this should be optimized)
		// maybe just output values from ones that are not empty?, this will have to be signalled further down the pipeline (size of window?) ask mr Zabołotny
		
		// problem is with wiring to lut and out of -> 1 cycle takes to write values, so they should be written in cyclic manner
			// idx 0 
			// r_lut_input_direct <= w_lut_input_0; // wire up
			// r_lut_output_9 <= w_lut_output_direct; // 1 cycle delay but output_direct has already computed value for 9!
			//
			// idx 1
			// r_lut_input_direct <= w_lut_input_1;
			// r_lut_output_0 <= w_lut_output_direct; 
			// and so on -> this way no need for memory
			
		if (clk_en) begin // <- IMPORTANT, this is beginning of clk_en and streamlining implementation
			if (v_idx == 0) begin // && w_st0 == RDY) begin // maybe separate collection of ready signals?
				o_signal <= w_signal0;
				r_lut_input_direct <= w_lut_input_0; // wire up this bank's phase
				r_lut_output_9 <= w_lut_output_direct; // last cycle's looked-up value is for previous index
			end else if (v_idx == 1) begin // && w_st1 == RDY) begin // for now remove ready check
				o_signal <= w_signal1;
				r_lut_input_direct <= w_lut_input_1;
				r_lut_output_0 <= w_lut_output_direct;
			end else if (v_idx == 2) begin // && && w_st2 == RDY) begin
				o_signal <= w_signal2;
				r_lut_input_direct <= w_lut_input_2;
				r_lut_output_1 <= w_lut_output_direct;
			end else if (v_idx == 3) begin // && && w_st3 == RDY) begin
				o_signal <= w_signal3;		
				r_lut_input_direct <= w_lut_input_3;
				r_lut_output_2 <= w_lut_output_direct;
			end else if (v_idx == 4) begin // && && w_st4 == RDY) begin
				o_signal <= w_signal4;
				r_lut_input_direct <= w_lut_input_4;
				r_lut_output_3 <= w_lut_output_direct;
			end else if (v_idx == 5 ) begin // &&&& w_st5 == RDY) begin
				o_signal <= w_signal5;
				r_lut_input_direct <= w_lut_input_5;
				r_lut_output_4 <= w_lut_output_direct;
			end else if (v_idx == 6) begin // && && w_st6 == RDY) begin
				o_signal <= w_signal6;
				r_lut_input_direct <= w_lut_input_6;
				r_lut_output_5 <= w_lut_output_direct;
			end else if (v_idx == 7 ) begin // &&&& w_st7 == RDY) begin
				o_signal <= w_signal7;
				r_lut_input_direct <= w_lut_input_7;
				r_lut_output_6 <= w_lut_output_direct;
			end else if (v_idx == 8 ) begin // &&&& w_st8 == RDY) begin
				o_signal <= w_signal8;
				r_lut_input_direct <= w_lut_input_8;
				r_lut_output_7 <= w_lut_output_direct;
			end else if (v_idx == 9) begin // && && w_st9 == RDY) begin
				o_signal <= w_signal9;
				r_lut_input_direct <= w_lut_input_9;
				r_lut_output_8 <= w_lut_output_direct;
			end
			
			if (v_idx == 9)
				v_idx <= 0;
			else
				v_idx <= v_idx + 1;
			o_idx <= v_idx; // DEBUG
		end
	end

endmodule
