// phase calculating banks, for now just for a4 note

//TODO: clock enable has to be given because it cannot be always enabled
// for now just A4 (440Hz) generating module (for phase calculation) 
module dummyA4(clk, phase_out); // maybe different style of coding, everything in module declaration?
	input clk;
	output reg [15:0] phase_out; // width depends on samples N
	// Phase increment can be precalculated = 0.072(ignoring the truncated part) -> 2^14(16384 samples) * fd /fs
	// but rescale 0.072 * 65535 / 6.283185 = 751.9 ~ 752
	
	initial phase_out = 16'h0000;
	always @(posedge clk) begin
		phase_out <= phase_out + 16'h2f0;
	end
	
endmodule
