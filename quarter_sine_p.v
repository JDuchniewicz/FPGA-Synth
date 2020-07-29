// Quarter-wave sine logic Pipelined

module quarter_sine_p(input clk,
							input clk_en,
							input wav_en,
							input rst,
							input[6:0] i_midi,
							output reg[6:0] o_midi,
							input[23:0] i_phase,
							input i_valid,
							output reg o_valid,
							output reg signed[23:0] o_sine);
		parameter NBANKS = 10;
		
		reg r_negate_1[1:0][NBANKS-1:0];
		reg r_negate_2[1:0][NBANKS-1:0];
		reg signed[15:0] r_lut_sine_1[NBANKS-1:0];
		reg signed[15:0] r_lut_sine_2[NBANKS-1:0];
		
		// for buffering values
		reg valid[2:0];
		reg[6:0] midi[2:0];
		
		reg[8:0]   r_cur_index_1, r_cur_index_2;
		wire[15:0] w_sine_out_1, w_sine_out_2;
		
		// next step phase
		wire[10:0] i_phase_next;
		reg [12:0] r_phase_frac[1:0][NBANKS-1:0];
		
		reg signed[15:0] r_mult_1a, r_mult_2a;
		reg [13:0] 		  r_mult_1b, r_mult_2b;
		wire signed[29:0] w_result_1, w_result_2;
		wire signed[29:0] w_result_added;
		
		// LUTs of size 512 outputting 16 bit sine values to be interpolated
		quarter_sine_lut slut_1(.i_phase(r_cur_index_1), .o_val(w_sine_out_1)); // difference between them is 2**13 so interpolation distance is 8192
		quarter_sine_lut slut_2(.i_phase(r_cur_index_2), .o_val(w_sine_out_2));

		// mult
		sine_mult mult_1(.dataa(r_mult_1a), .datab(r_mult_1b), .result(w_result_1));
		sine_mult mult_2(.dataa(r_mult_2a), .datab(r_mult_2b), .result(w_result_2));
		
		integer v_idx;
		integer i, j;
		
		assign i_phase_next = i_phase[23:13] + 11'b1;// this is the NEXT sample, our LUT has entries from 1 to 2 ** 11 indexed with 11 bits
		assign w_result_added = w_result_1 + w_result_2;
		
		initial begin
			o_sine = 24'b0;
			v_idx = 8; // delay of 2 computation blocks
			r_cur_index_1 = 9'b0;
			r_cur_index_2 = 9'b0;
			r_mult_1a = 16'b0;
			r_mult_2a = 16'b0;
			r_mult_1b = 14'b0;
			r_mult_2b = 14'b0;
			for (i = 0; i < NBANKS; i = i + 1) begin
				for (j = 0; j < 2; j = j + 1) begin
					r_negate_1[j][i] = 1'b0;
					r_negate_2[j][i] = 1'b0;
					r_phase_frac[j][i] = 13'b0;
				end
				r_lut_sine_1[i] = 16'b0;
				r_lut_sine_2[i] = 16'b0;
			end
			for (i = 0; i < 3; i = i + 1) begin
				valid[i] = 1'b0;
				midi[i] = 7'b0;
			end
			o_midi = 7'b0;
		end
		
		always @(posedge clk or posedge rst) begin
			if (rst) begin
				o_sine <= 16'b0;
				v_idx <= 8; // delay of 2 computation blocks
				r_cur_index_1 <= 9'b0;
				r_cur_index_2 <= 9'b0;
				r_mult_1a <= 16'b0;
				r_mult_2a <= 16'b0;
				r_mult_1b <= 14'b0;
				r_mult_2b <= 14'b0;
				for (i = 0; i < NBANKS; i = i + 1) begin
					for (j = 0; j < 2; j = j + 1) begin
						r_negate_1[j][i] <= 1'b0;
						r_negate_2[j][i] <= 1'b0;
						r_phase_frac[j][i] <= 13'b0;
					end
					r_lut_sine_1[i] <= 16'b0;
					r_lut_sine_2[i] <= 16'b0;
				end
				for (i = 0; i < 3; i = i + 1) begin
					valid[i] <= 1'b0;
					midi[i] <= 7'b0;
				end
				o_midi <= 7'b0;
			end else if(clk_en && wav_en) begin
				// clock one
				if (i_valid) begin
					r_negate_1[0][v_idx] <= i_phase[23]; // negate or not
					r_negate_2[0][v_idx] <= i_phase_next[10];
					r_cur_index_1 <= i_phase[22] ? ~i_phase[21:13] : i_phase[21:13]; // invert index if 2nd MSB is set
					r_cur_index_2 <= i_phase_next[9] ? ~i_phase_next[8:0] : i_phase_next[8:0]; // take just the lower part
					// store current phase fraction
					r_phase_frac[0][v_idx] <= i_phase[12:0];
				end
				
				// clock two
				if (valid[0]) begin
					if (v_idx == 0) begin
						r_lut_sine_1[NBANKS - 1] <= w_sine_out_1;
						r_lut_sine_2[NBANKS - 1] <= w_sine_out_2;
						r_negate_1[1][NBANKS - 1] <= r_negate_1[0][NBANKS - 1]; //to avoid overwriting
						r_negate_2[1][NBANKS - 1] <= r_negate_2[0][NBANKS - 1];
						r_phase_frac[1][NBANKS - 1] <= r_phase_frac[0][NBANKS - 1];
					end else begin
						r_lut_sine_1[v_idx - 1] <= w_sine_out_1;
						r_lut_sine_2[v_idx - 1] <= w_sine_out_2;
						r_negate_1[1][v_idx - 1] <= r_negate_1[0][v_idx - 1];
						r_negate_2[1][v_idx - 1] <= r_negate_2[0][v_idx - 1];
						r_phase_frac[1][v_idx - 1] <= r_phase_frac[0][v_idx - 1];
					end
				end
				
				//clock three
				if (valid[1]) begin // output only valid values
					if (v_idx == 0) begin
						if (r_negate_1[1][NBANKS - 2])
							r_mult_1a <= -r_lut_sine_1[NBANKS - 2];
						else
							r_mult_1a <= r_lut_sine_1[NBANKS - 2];
							
						if (r_negate_2[1][NBANKS - 2])
							r_mult_2a <= -r_lut_sine_2[NBANKS - 2];
						else
							r_mult_2a <= r_lut_sine_2[NBANKS - 2];
							
						r_mult_1b <= 14'h2000 - r_phase_frac[1][NBANKS - 2];
						r_mult_2b <= r_phase_frac[1][NBANKS - 2];
					end else if (v_idx == 1) begin
						if (r_negate_1[1][NBANKS - 1])
							r_mult_1a <= -r_lut_sine_1[NBANKS - 1];
						else
							r_mult_1a <= r_lut_sine_1[NBANKS - 1];
							
						if (r_negate_2[1][NBANKS - 1])
							r_mult_2a <= -r_lut_sine_2[NBANKS - 1];
						else
							r_mult_2a <= r_lut_sine_2[NBANKS - 1];
							
						r_mult_1b <= 14'h2000 - r_phase_frac[1][NBANKS - 1];
						r_mult_2b <= r_phase_frac[1][NBANKS - 1];
					end else begin
						if (r_negate_1[1][v_idx - 2])
							r_mult_1a <= -r_lut_sine_1[v_idx - 2];
						else
							r_mult_1a <= r_lut_sine_1[v_idx - 2];
							
						if (r_negate_2[1][v_idx - 2])
							r_mult_2a <= -r_lut_sine_2[v_idx - 2];
						else
							r_mult_2a <= r_lut_sine_2[v_idx - 2];
							
						r_mult_1b <= 14'h2000 - r_phase_frac[1][v_idx - 2];
						r_mult_2b <= r_phase_frac[1][v_idx - 2];
					end
				end
			
				// clock four -> multiply result
				if (valid[2]) begin
					o_sine <= w_result_added[29:6];
				end else begin
					o_sine <= 24'b0;
				end
				
				
				// move valid value
				valid[0] <= i_valid;
				valid[1] <= valid[0];
				valid[2] <= valid[1];
				o_valid <= valid[2];
				
				// move midi value
				midi[0] <= i_midi;
				midi[1] <= midi[0];
				midi[2] <= midi[1];
				o_midi <= midi[2];
				
				if (v_idx == NBANKS - 1)
					v_idx <= 0;
				else
					v_idx <= v_idx + 1;
			end else if(!wav_en) begin
				o_sine <= 24'b0;
				o_midi <= 7'b0;
				o_valid <= 1'b0;
			end
		end
endmodule
