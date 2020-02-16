// phase calculating banks, for now just for a4 note

//TODO: clock enable has to be given because it cannot be always enabled
// for now just A4 (440kHz) generating module (for phase calculation) 
module dummyA4(clk, phase_out); // maybe different style of coding, everything in module declaration?
	input clk;
	output reg [31:0] phase_out = 32'b0; // does it need to be initialized?
	// Phase increment can be precalculated = 188978561.024 (ignoring the truncated part) -> 2^32 * fd /fs
	
	always @(posedge clk) begin
		phase_out <= phase_out + 32'h0b43_9581;
	end
	
endmodule
