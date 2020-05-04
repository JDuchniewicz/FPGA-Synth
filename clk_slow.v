// 10 times slower clock than input one

module clk_slow(input clk,
					 input rst,
					 output reg clk_out);
		
	reg [3:0] counter;
	
	initial counter = 4'b0;
	
	always @(posedge clk or posedge rst) begin
		if (rst) begin
			counter <= 4'b0;
			clk_out <= 1'b0;
		end else begin
			if (counter == 9) begin
				clk_out <= 1'b1;
				counter <= 4'b0;
			end else begin
				clk_out <= 1'b0;
				counter <= counter + 1;
			end
		end
	end
	
endmodule
