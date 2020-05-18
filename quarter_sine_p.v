// Quarter-wave sine logic Pipelined

module quarter_sine_p(input clk,
							input clk_en,
							input rst,
							input[6:0] i_midi,
							output reg[6:0] o_midi,
							input[15:0] i_phase,
							input i_valid,
							output reg o_valid,
							output reg signed[23:0] o_sine);
		parameter NBANKS = 10;
		
		reg r_negate[1:0][NBANKS-1:0];
		reg signed[23:0] r_lut_sine[NBANKS-1:0];
		
		reg signed[13:0] r_cur_index;
		wire[23:0] w_sine_out;
		
		quarter_sine_lut slut(.i_phase(r_cur_index), .o_val(w_sine_out));
		
		integer v_idx;
		integer i, j;
		
		initial begin
			o_sine = 16'b0;
			v_idx = 8; // delay of 2 computation blocks
			r_cur_index = 14'b0;
			for (i = 0; i < NBANKS; i = i + 1) begin
				for (j = 0; j < 2; j = j + 1) begin
					r_negate[j][i] = 1'b0;
				end
				r_lut_sine[i] = 24'b0;
			end
			o_midi = 7'b0;
		end
		
		always @(posedge clk or posedge rst) begin
			if (rst) begin
				o_sine <= 16'b0;
				v_idx <= 8; // delay of 2 computation blocks
				r_cur_index <= 14'b0;
				for (i = 0; i < NBANKS; i = i + 1) begin
					for (j = 0; j < 2; j = j + 1) begin
						r_negate[j][i] <= 1'b0;
					end
					r_lut_sine[i] <= 24'b0;
				end
				o_midi <= 7'b0;
			end else if(clk_en) begin
				// clock one
				r_negate[0][v_idx] <= i_phase[15]; // negate or not
				r_cur_index <= i_phase[14] ? ~i_phase[13:0] : i_phase[13:0]; // invert index if 2nd MSB is set
				
				// clock two
				if (v_idx == 0) begin
					r_lut_sine[NBANKS - 1] <= w_sine_out;
					r_negate[1][NBANKS - 1] <= r_negate[0][NBANKS - 1]; //to avoid overwriting
				end else begin
					r_lut_sine[v_idx - 1] <= w_sine_out;
					r_negate[1][v_idx - 1] <= r_negate[0][v_idx - 1];
				end
				
				//clock three
				if (v_idx == 0) begin
					if (r_negate[1][NBANKS - 1])
						o_sine <= -r_lut_sine[NBANKS - 1];
					else
						o_sine <= r_lut_sine[NBANKS - 1];
				end else begin
					if (r_negate[1][v_idx - 1])
						o_sine <= -r_lut_sine[v_idx - 1];
					else
						o_sine <= r_lut_sine[v_idx - 1];
				end
					
				o_valid <= i_valid; // do not care for the delay in computation
				o_midi <= i_midi;
				
				if (v_idx == NBANKS - 1)
					v_idx <= 0;
				else
					v_idx <= v_idx + 1;
			end
		end
endmodule
