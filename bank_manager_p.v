// Pipelined bank manager

module bank_manager_p(input clk,
							  input clk_en, // all pipeline elements should stop on the index they are delayed about
							  input reset,
							  input[15:0] i_data,
							  output reg signed[23:0] o_signal);
							  
	parameter NBANKS = 10;
	
	reg[6:0]		midi_vals[NBANKS-1:0];
	reg[6:0]	  r_cur_midi;
	
	wire 		w_pb_valid, w_qs_valid, w_svf_valid;
	wire signed[23:0] w_qs_out, w_svf_out;
	wire [15:0] w_pb_out;
	wire[6:0] w_pb_o_midi, w_qs_o_midi, w_svf_o_midi;
	// midi information is passed each cycle ( optimize - just collapse busses)

	wire 		  w_cmd;
	wire[6:0]  w_midi;

	assign w_cmd = i_data[15];
	assign w_midi = i_data[14:8];
	
	phase_bank_p pb(.clk(clk),
						 .clk_en(clk_en), 
						 .rst(reset), 
						 .i_midi(r_cur_midi), 
						 .o_midi(w_pb_o_midi), 
						 .o_valid(w_pb_valid), 
						 .o_phase(w_pb_out)); // maybe pass velocity also?
						 
	quarter_sine_p sine(.clk(clk), 
							  .clk_en(clk_en), 
							  .rst(reset), 
							  .i_midi(w_pb_o_midi), 
							  .o_midi(w_qs_o_midi), 
							  .i_phase(w_pb_out), 
							  .i_valid(w_pb_valid), 
							  .o_valid(w_qs_valid), 
							  .o_sine(w_qs_out));
		/*					  // TODO debug why it does not work + check why one sound is not being played back, seems like something with indexing, FIX output values for midi 00 -> should not take anything from LUT but take 0x0 (check glitchy sound?)
	state_variable_filter_iir_p SVF(.clk(clk),
											  .clk_en(clk_en), 
											  .rst(reset), 
											  .i_midi(w_qs_o_midi), 
											  .o_midi(w_svf_o_midi), 
											  .i_data(w_qs_out), 
											  .i_valid(w_qs_valid), 
											  .o_valid(w_svf_valid), 
											  .o_filtered(w_svf_out)); // should svf be informed that the signal is ready? how? (sine lut can count but meh, )
			*/								  
											  	
	integer v_idx; // every element of the pipeline is delayed in terms of id
	integer i;
	
	initial begin
		for (i = 0; i < NBANKS; i = i + 1) begin
			midi_vals[i] = 7'h0;
		end
		r_cur_midi = 7'b0;
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
			o_signal <= 24'b0;
			v_idx <= 0;
		// handle commands
		end else begin
			if (w_cmd == 1) begin
				if (midi_vals[0] == 7'h0) begin
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
				if (w_qs_valid) begin // TODO LP turned off, changed from w_svf_valid
					o_signal <= w_qs_out; // w_svf_out
				end
				
				if (v_idx == NBANKS - 1)
					v_idx <= 0;
				else
					v_idx <= v_idx + 1;
			end
		end
	end			  
endmodule
