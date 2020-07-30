// Pipelined bank manager

module bank_manager_p(input clk,
							  input clk_en, // all pipeline elements should stop on the index they are delayed about
							  input reset,
							  input[15:0] i_data,
							  output reg signed[23:0] o_signal);
							  
	parameter NBANKS = 10;
	localparam SINE = 2'b00, SQUARE = 2'b01, SAWTOOTH = 2'b10, TRIANGLE = 2'b11;
	
	reg[6:0]				midi_vals[NBANKS-1:0];
	reg[6:0]	   		r_cur_midi;
	
	reg[1:0] 			waveform;
	reg					r_sine_en, r_square_en, r_sawtooth_en, r_triangle_en;
	
	wire 					w_pb_valid, w_wave_valid, w_qs_valid, w_square_valid, w_sawtooth_valid, w_triangle_valid, w_svf_valid, w_signal_valid;
	wire signed[23:0] w_wave_out, w_square_out, w_sawtooth_out, w_triangle_out, w_qs_out, w_svf_out, w_signal_out;
	wire [23:0] 		w_pb_out;
	wire[6:0] 			w_pb_o_midi, w_wave_o_midi, w_qs_o_midi, w_square_o_midi, w_sawtooth_o_midi, w_triangle_o_midi, w_svf_o_midi;

	wire 		  			w_cmd;
	wire[6:0]  			w_midi;

	assign w_cmd = i_data[15];
	assign w_midi = i_data[14:8];
	assign w_velocity = i_data[7:0];
	
	phase_bank_p pb(.clk(clk),
						 .clk_en(clk_en), 
						 .rst(reset), 
						 .i_midi(r_cur_midi), 
						 .o_midi(w_pb_o_midi), 
						 .o_valid(w_pb_valid), 
						 .o_phase(w_pb_out));
						 
	quarter_sine_p sine(.clk(clk), 
							  .clk_en(clk_en),
							  .wav_en(r_sine_en),
							  .rst(reset), 
							  .i_midi(w_pb_o_midi), 
							  .o_midi(w_qs_o_midi), 
							  .i_phase(w_pb_out), 
							  .i_valid(w_pb_valid), 
							  .o_valid(w_qs_valid), 
							  .o_sine(w_qs_out));
							  
	square_wave square(.clk(clk),
							 .clk_en(clk_en),
							 .wav_en(r_square_en),
							 .rst(reset),
							 .i_midi(w_pb_o_midi),
							 .o_midi(w_square_o_midi),
							 .i_phase(w_pb_out),
							 .i_valid(w_pb_valid),
							 .o_valid(w_square_valid),
							 .o_square(w_square_out));
							 
	sawtooth_wave sawtooth(.clk(clk),
								  .clk_en(clk_en),
								  .wav_en(r_sawtooth_en),
								  .rst(reset),
								  .i_midi(w_pb_o_midi),
								  .o_midi(w_sawtooth_o_midi),
								  .i_phase(w_pb_out),
								  .i_valid(w_pb_valid),
								  .o_valid(w_sawtooth_valid),
								  .o_sawtooth(w_sawtooth_out));
								  
	triangle_wave triangle(.clk(clk),
								  .clk_en(clk_en),
								  .wav_en(r_triangle_en),
								  .rst(reset),
								  .i_midi(w_pb_o_midi),
								  .o_midi(w_triangle_o_midi),
								  .i_phase(w_pb_out),
								  .i_valid(w_pb_valid),
								  .o_valid(w_triangle_valid),
								  .o_triangle(w_triangle_out));					  

	state_variable_filter_iir_p SVF(.clk(clk),
											  .clk_en(clk_en), 
											  .rst(reset), 
											  .i_midi(w_wave_o_midi), 
											  .o_midi(w_svf_o_midi), 
											  .i_data(w_wave_out), 
											  .i_valid(w_wave_valid), 
											  .o_valid(w_svf_valid), 
											  .o_filtered(w_svf_out));
								
								
	assign w_wave_out = w_qs_out | w_sawtooth_out | w_triangle_out;
	assign w_wave_o_midi = w_qs_o_midi | w_sawtooth_o_midi | w_triangle_o_midi;
	assign w_wave_valid = w_qs_valid | w_sawtooth_valid | w_triangle_valid;
	
	// bypass of SVF for square wave
	assign w_signal_valid = w_svf_valid | w_square_valid;
	assign w_signal_out = w_svf_out | (w_square_out >>> 1);
	
	integer v_idx; // every element of the pipeline is delayed in terms of id
	integer i;
	
	initial begin
		for (i = 0; i < NBANKS; i = i + 1) begin
			midi_vals[i] = 7'h0;
		end
		r_cur_midi = 7'b0;
		waveform = 2'b0;
		r_sine_en = 1'b1;
		r_square_en = 1'b0;
		r_sawtooth_en = 1'b0;
		r_triangle_en = 1'b0;
		o_signal = 24'b0;
		v_idx = 0;
	end
	
	always @(posedge clk or posedge reset) begin
		if (reset) begin
			for (i = 0; i < NBANKS; i = i + 1) begin
				midi_vals[i] <= 7'h0;
			end
			// and more...
			r_cur_midi <= 7'b0;
			waveform <= 2'b0;
			r_sine_en <= 1'b1;
			r_square_en <= 1'b0;
			r_sawtooth_en <= 1'b0;
			r_triangle_en <= 1'b0;
			o_signal <= 24'b0;
			v_idx <= 0;
		// handle commands
		end else begin
			if (w_cmd == 1) begin
				if (w_midi == 7'b0 && w_velocity == 8'b0) begin // CHANGE_WAVE
					if (waveform == TRIANGLE) begin // turn on sine
						waveform <= SINE;
						r_sine_en <= 1'b1;
						r_square_en <= 1'b0;
						r_sawtooth_en <= 1'b0;
						r_triangle_en <= 1'b0;
					end else if (waveform == SINE) begin // turn on square
						waveform <= SQUARE;
						r_sine_en <= 1'b0;
						r_square_en <= 1'b1;
						r_sawtooth_en <= 1'b0;
						r_triangle_en <= 1'b0;
					end else if (waveform == SQUARE) begin // turn on saw
						waveform <= SAWTOOTH;
						r_sine_en <= 1'b0;
						r_square_en <= 1'b0;
						r_sawtooth_en <= 1'b1;
						r_triangle_en <= 1'b0;
					end else if (waveform == SAWTOOTH) begin // turn on triangle
						waveform <= TRIANGLE;
						r_sine_en <= 1'b0;
						r_square_en <= 1'b0;
						r_sawtooth_en <= 1'b0;
						r_triangle_en <= 1'b1;
					end
				end else if (midi_vals[0] == 7'h0) begin
					midi_vals[0] <= w_midi;
				end else if (midi_vals[1] == 7'h0) begin
					midi_vals[1] <= w_midi;
				end else if (midi_vals[2] == 7'h0) begin
					midi_vals[2] <= w_midi;			
				end else if (midi_vals[3] == 7'h0) begin
					midi_vals[3] <= w_midi;
				end else if (midi_vals[4] == 7'h0) begin
					midi_vals[4] <= w_midi;
				end else if (midi_vals[5] == 7'h0) begin
					midi_vals[5] <= w_midi;
				end else if (midi_vals[6] == 7'h0) begin
					midi_vals[6] <= w_midi;
				end else if (midi_vals[7] == 7'h0) begin
					midi_vals[7] <= w_midi;
				end else if (midi_vals[8] == 7'h0) begin
					midi_vals[8] <= w_midi;
				end else if (midi_vals[9] == 7'h0) begin
					midi_vals[9] <= w_midi;
				end // failure to playback yet another sound should be signalled to user!
			end else if (w_cmd == 0) begin
				if (w_midi == 7'h7f) begin // STOP_ALL
					for (i = 0; i < NBANKS; i = i + 1) begin
						midi_vals[i] <= 7'h0;
					end
				end else if (midi_vals[0] == w_midi) begin
					midi_vals[0] <= 7'h0; // MIDI 0 is equal to turn off
				end else if (midi_vals[1] == w_midi) begin
					midi_vals[1] <= 7'h0;
				end else if (midi_vals[2] == w_midi) begin
					midi_vals[2] <= 7'h0;
				end else if (midi_vals[3] == w_midi) begin
					midi_vals[3] <= 7'h0;
				end else if (midi_vals[4] == w_midi) begin
					midi_vals[4] <= 7'h0;
				end else if (midi_vals[5] == w_midi) begin
					midi_vals[5] <= 7'h0;
				end else if (midi_vals[6] == w_midi) begin
					midi_vals[6] <= 7'h0;
				end else if (midi_vals[7] == w_midi) begin
					midi_vals[7] <= 7'h0;
				end else if (midi_vals[8] == w_midi) begin
					midi_vals[8] <= 7'h0;
				end else if (midi_vals[9] == w_midi) begin
					midi_vals[9] <= 7'h0;
				end
			end
		
			// handle dispatching midi with valid info
			if (clk_en) begin
				r_cur_midi <= midi_vals[v_idx]; // if 7'h0 then invalid
				
				// change when adding more elements to pipeline
				if (w_signal_valid) begin
					o_signal <= w_signal_out;
				end else begin
					o_signal <= 24'b0;
				end
				/* FOR DISABLING LP
				if (w_qs_valid) begin // TODO LP turned off, changed from w_svf_valid
					o_signal <= w_qs_out; // w_svf_out
				end else begin
					o_signal <= 24'b0;
				end
				*/
				if (v_idx == NBANKS - 1)
					v_idx <= 0;
				else
					v_idx <= v_idx + 1;
			end
		end
	end			  
endmodule
