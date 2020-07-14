// Digital mixer of 10 values - counts to 10 and outputs stored value

// this module actually add 20 effective bits instead of 24 because of saturation precautions
module mixer(input clk,
				 input clk_en,
				 input rst,
				 input signed[23:0] i_data,
				 output reg signed[23:0] o_mixed,
				 output reg o_rdy);
	
	// Because verilog does not like signed numbers, these have to be explicite signed regs
	reg signed[23:0] MAX_SIGNED = {1'sb0, {23{1'sb1}}}; // check if really signed!
	reg signed[23:0] MIN_SIGNED = {1'sb1, {23{1'sb0}}};
	
	reg signed[27:0] r_mixed, r_overflow;
	integer v_idx;
	
	initial begin
		r_mixed = 28'b0;
		r_overflow = 28'b0;
		o_mixed = 24'b0;
		o_rdy = 1'b0;
		v_idx = 0;
	end
	
	always @ (posedge clk or posedge rst) begin
		if (rst) begin
			r_mixed <= 28'b0;
			r_overflow <= 28'b0;
			o_mixed <= 24'b0;
			o_rdy <= 1'b0;
			v_idx <= 0;
		end 
		
		else if (clk_en) begin // TODO: no need for complex logic, just reset buffer on each 0th cycle and output out buffer
			// handle overflow/underflow
			if (r_mixed + i_data > MAX_SIGNED) begin // OF
				r_mixed <= (v_idx === 9 ? 24'b0 : MAX_SIGNED);
				o_mixed <= (v_idx === 9 ? MAX_SIGNED : 24'b0);
				r_overflow <= r_overflow + (r_mixed + i_data - MAX_SIGNED);
			end else if (r_mixed + i_data < MIN_SIGNED) begin // UF
				r_mixed <= (v_idx === 9 ? 24'b0 : MIN_SIGNED);
				o_mixed <= (v_idx === 9 ? MIN_SIGNED : 24'b0);
				r_overflow <= r_overflow + (r_mixed + i_data - MIN_SIGNED);
			end else begin 					// in range - try offloading the overflow
				if (r_mixed + i_data + r_overflow > MAX_SIGNED) begin // OF still too big
					r_mixed <= (v_idx === 9 ? 24'b0 : MAX_SIGNED);
					o_mixed <= (v_idx === 9 ? MAX_SIGNED : 24'b0);
					r_overflow <= r_mixed + i_data + r_overflow - MAX_SIGNED;
				end else if (r_mixed + i_data + r_overflow < MIN_SIGNED) begin // UF still too small
					r_mixed <= (v_idx === 9 ? 24'b0 : MIN_SIGNED);
					o_mixed <= (v_idx === 9 ? MIN_SIGNED : 24'b0);
					r_overflow <= r_mixed + i_data + r_overflow - MIN_SIGNED;
				end else begin // can get rid off of the OF/UF or equal to 0
					r_mixed <= (v_idx === 9 ? 24'b0 : r_mixed + i_data + r_overflow);
					o_mixed <= (v_idx === 9 ? r_mixed + i_data + r_overflow : 24'b0);
				end
			end
			
			o_rdy <= (v_idx === 9 ? 1'b1 : 1'b0);
			v_idx <= (v_idx === 9 ? 0 : v_idx + 1);
		end else begin // counter not active - retain old values
			v_idx <= v_idx;
			r_mixed <= r_mixed;
			r_overflow <= r_overflow;
			o_mixed <= o_mixed;
			o_rdy <= 1'b0;
		end
	end
				
endmodule
