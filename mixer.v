// Digital mixer of 10 values - counts to 10 and outputs stored value

// this module actually add 20 effective bits instead of 24 because of saturation precautions
module mixer(input clk,
				 input rst,
				 input signed[23:0] i_data,
				 output reg signed[23:0] o_mixed);
	
	reg signed[23:0] r_mixed;
	integer v_idx;
	
	initial begin
		r_mixed = 24'b0;
		o_mixed = 24'b0;
		v_idx = 0;
	end
	
	always @ (posedge clk or posedge rst) begin
		if (rst) begin
			r_mixed <= 24'b0;
			o_mixed <= 24'b0;
			v_idx <= 0;
		end
		
		else if (v_idx === 9) begin
			o_mixed <= r_mixed + (i_data >>> 4);
			r_mixed <= 24'b0;
			v_idx <= 0;
		end else begin
			o_mixed <= 24'b0;
			r_mixed <= r_mixed + (i_data >>> 4);
			v_idx <= v_idx + 1;
		end
	end
				
endmodule
