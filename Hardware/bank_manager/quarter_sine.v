// Quarter-wave sine logic

module quarter_sine(input clk,
						  input clk_en,
							input[15:0] i_phase,
							output reg [13:0] o_lut_input, // 2 bits are being used inside this module
							input signed [15:0] i_lut_output,
							output reg signed[15:0] o_val);
		reg r_negate[1:0];
		reg signed[15:0] r_lut_sine;
		
		initial o_val = 16'b0;
		initial o_lut_input = 14'b0;
		
		always @(posedge clk) begin
			if(clk_en) begin
				// clock one
				r_negate[0] <= i_phase[15]; // negate or not
				o_lut_input <= i_phase[14] ? ~i_phase[13:0] : i_phase[13:0]; // invert index if 2nd MSB is set
				
				// clock two
				r_lut_sine <= i_lut_output;
				r_negate[1] <= r_negate[0]; //to avoid overwriting

				//clock three
				if (r_negate[1])
					o_val <= -r_lut_sine;
				else
					o_val <= r_lut_sine;
			end
		end
endmodule
