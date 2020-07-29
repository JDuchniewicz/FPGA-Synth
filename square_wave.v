// A square wave module in 1 cycle

module square_wave(input clk,
							input clk_en,
							input wav_en,
							input rst,
							input[6:0] i_midi,
							output reg[6:0] o_midi,
							input[23:0] i_phase,
							input i_valid,
							output reg o_valid,
							output reg signed[23:0] o_square);

		reg signed[23:0] MAX_SIGNED = {1'sb0, {23{1'sb1}}};
		reg signed[23:0] MIN_SIGNED = {1'sb1, {23{1'sb0}}};
		
		initial begin
			o_square = 24'b0;
			o_midi = 7'b0;
			o_valid = 1'b0;
		end
		
		always @(posedge clk or posedge rst) begin
			if (rst) begin
				o_square <= 24'b0;
				o_midi <= 7'b0;
				o_valid <= 1'b0;
			end else if(clk_en && wav_en) begin
				if (i_phase >= MIN_SIGNED && i_valid) begin // greater than half, output -1
					o_square <= MIN_SIGNED;
				end else if(i_valid) begin // less then half, output 1
					o_square <= MAX_SIGNED;
				end else begin
					o_square <= 24'b0;
				end
				o_midi <= i_midi;
				o_valid <= i_valid;
			end else if(!wav_en) begin
				o_square <= 24'b0;
				o_midi <= 7'b0;
				o_valid <= 1'b0;
			end
		end

endmodule
							