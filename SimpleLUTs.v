// modules for LUT's for multiple sinewaves for SIMPLE synthesis


//TODO: clock enable has to be given because it cannot be always enabled
// for now just A4 (440kHz) generating module (for phase calculation) 
module dummyA4(clk, val_out); // maybe different style of coding, everything in module declaration?
	input clk;
	output reg [15:0] val_out;
	reg [31:0] phase;
	// Phase increment can be precalculated = 188978561.024 (ignoring the truncated part) -> 2^32 * fd /fs
	
	wire [15:0] lut_out;
	assign lut_out = val_out;
	
	// for now wire it like this? can it be done simpler?
	sineLUT lut(.clk(clk), .index(phase[31:16]), .val_out(lut_out));
	
	always @(posedge clk)
		phase <= phase + 32'h0b43_9581;
	
endmodule

// for now let's assume 8192 samples = 2^13, generate four quarters of one cycle for now (simplify later, but requires more logic)
module sineLUT(clk, index, val_out);
	input clk;
	input [15:0] index; // has to be bus?
	output reg [15:0] val_out; //width?
	
	always @(posedge clk) begin
		case (index)
			//generate values
			default	:	val_out <= 16'b0;
		endcase
	end
endmodule
