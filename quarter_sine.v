// Quarter-wave sine logic

module quarter_sine(input clk,
							input[15:0] i_phase,
							output reg[15:0] o_val);
		reg r_negate[1:0];
		reg[13:0] r_index; // 2 bits are being used inside this module
		reg[15:0] r_lut_sine;
		wire[15:0] w_tmp_val;
		
		quarter_sine_lut lut(.i_phase(r_index), .o_val(w_tmp_val));
		always @(posedge clk) begin
			// clock one
			r_negate[0] <= i_phase[15]; // negate or not
			r_index <= i_phase[14] ? ~i_phase[13:0] : i_phase[13:0]; // invert index if 2nd MSB is set
			
			// clock two
			r_lut_sine <= w_tmp_val;
			r_negate[1] <= r_negate[0]; //to avoid overwriting

			//clock three
			if (r_negate[1])
				o_val <= -r_lut_sine;
			else
				o_val <= r_lut_sine;
		end
endmodule
