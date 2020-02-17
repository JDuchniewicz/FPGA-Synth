// Quarter-wave sine logic

module quarter_sine(input clk,
							input[15:0] phase,
							output reg[15:0] val_out);
		reg negate[1:0];
		reg[13:0] index; // 2 bits are being used inside this module
		reg[15:0] lut_sine;
		wire[15:0] tmp_val;
		
		quarter_sine_lut lut(.phase(index), .val_out(tmp_val));
		always @(posedge clk) begin
			// clock one
			negate[0] <= phase[15]; // negate or not
			index <= phase[14] ? ~phase[13:0] : phase[13:0]; // invert index if 2nd MSB is set
			
			// clock two
			lut_sine <= tmp_val;
			negate[1] <= negate[0]; //to avoid overwriting

			//clock three
			if (negate[1])
				val_out <= -lut_sine;
			else
				val_out <= lut_sine;
		end
endmodule
