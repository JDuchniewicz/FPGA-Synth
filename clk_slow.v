// parametrized clock with assumed reference 100MHz

module clk_slow #(parameter FREQ = 1) (
					 input clk,
					 input rst,
					 output reg clk_out);
		
	reg [26:0] counter;
	
	initial begin
		counter = 27'b0;
		clk_out = 1'b0;
	end
	
	always @(posedge clk or posedge rst) begin
		if (rst) begin
			counter <= 27'b0;
			clk_out <= 1'b0;
		end else begin
			counter <= counter + 1;
			if (counter == 100_000_000/2/FREQ) begin // assuming 100MHz ref clock
				counter <= 27'b0;
				clk_out <= ~clk_out;
			end
		end
	end
	
endmodule
