// slow CLK_EN(as opposed to slow_clk this lasts only for a one cycle of the fast clock)

module slow_clk_en #(parameter IN_FREQ, 
							parameter OUT_FREQ) (
							input clk,
							input rst,
							output reg clk_en);
							
	localparam DIVISOR = IN_FREQ/OUT_FREQ;
	
	reg [10:0] counter; // this is not scalable -> need manual bit setting or calc with log? -> there is a clog function, or it can be calcd manually
	
	initial begin
		counter = 11'b0;
		clk_en = 1'b0;
	end
	
	always @(posedge clk or posedge rst) begin
		if (rst) begin
			counter <= 11'b0;
			clk_en <= 1'b0;
		end else begin
			if (counter == DIVISOR) begin
				counter <= 11'b0;
				clk_en <= 1'b1;
			end else begin
				counter <= counter + 1;
				clk_en <= 1'b0;
			end
		end
	end	
				
endmodule 