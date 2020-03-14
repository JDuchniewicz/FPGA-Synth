// phase calculating banks, for now just for a4 note

//TODO: clock enable has to be given because it cannot be always enabled
// for now just A4 (440Hz) generating module (for phase calculation) 
/*
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
*/

/* Explanation to myself:
	Assuming 16 bits on input to LUT(2 bits taken for logic calc) and 16 bits of output of LUT (0-65535)
	We have mapped 0-65535 to 0-2*pi(6.283185), and 0-65535 to 0-1
	Hence phase banks increments have to also be rescaled from 0-2*pi to 0-65535
*/

module phase_bank(input clk,
						input i_cmd,
						input[6:0] i_midi,
						output reg o_state,
						output reg[15:0] o_phase);
						
		localparam IDLE = 1'b0, RUNNING = 1'b1;
		wire[15:0] w_tw; //tuning word
		
		initial o_state = IDLE;
		initial o_phase = 16'b0;
		
		tuning_word_lut tw_lut(.i_midi(i_midi), .o_tw(w_tw)); // will it calculate on time?
		
		always @(posedge clk) begin
			if (!o_state && i_cmd) begin// IDLE and run
				// calc tuning word
				o_state <= RUNNING;
			end else if (o_state && !i_cmd) begin // RUNNING and stop
				o_phase <= 16'b0;
				o_state <= IDLE;
			end else if (o_state && i_cmd) begin// RUNNING and RUN
				o_phase <= o_phase + w_tw;
			end
		end
						
endmodule

// precalculated for N = 16834(so 16 bits full period) by generate_tuning_word.py
module tuning_word_lut(input[6:0] i_midi,
								output reg[15:0] o_tw);
		initial o_tw = 16'b0;
		
		always @(i_midi) begin
			case(i_midi)
				7'h00 	:	o_tw <= 16'h000e;
            7'h01 	:	o_tw <= 16'h000f;
            7'h02 	:	o_tw <= 16'h0010;
            7'h03 	:	o_tw <= 16'h0011;
            7'h04 	:	o_tw <= 16'h0012;
            7'h05 	:	o_tw <= 16'h0013;
            7'h06 	:	o_tw <= 16'h0014;
            7'h07 	:	o_tw <= 16'h0015;
            7'h08 	:	o_tw <= 16'h0016;
            7'h09 	:	o_tw <= 16'h0017;
            7'h0a 	:	o_tw <= 16'h0019;
            7'h0b 	:	o_tw <= 16'h001a;
            7'h0c 	:	o_tw <= 16'h001c;
            7'h0d 	:	o_tw <= 16'h001e;
            7'h0e 	:	o_tw <= 16'h001f;
            7'h0f 	:	o_tw <= 16'h0021;
            7'h10 	:	o_tw <= 16'h0023;
            7'h11 	:	o_tw <= 16'h0025;
            7'h12 	:	o_tw <= 16'h0028;
            7'h13 	:	o_tw <= 16'h002a;
            7'h14 	:	o_tw <= 16'h002c;
            7'h15 	:	o_tw <= 16'h002f;
            7'h16 	:	o_tw <= 16'h0032;
            7'h17 	:	o_tw <= 16'h0035;
            7'h18 	:	o_tw <= 16'h0038;
            7'h19 	:	o_tw <= 16'h003b;
            7'h1a 	:	o_tw <= 16'h003f;
            7'h1b 	:	o_tw <= 16'h0042;
            7'h1c 	:	o_tw <= 16'h0046;
            7'h1d 	:	o_tw <= 16'h004b;
            7'h1e 	:	o_tw <= 16'h004f;
            7'h1f 	:	o_tw <= 16'h0054;
            7'h20 	:	o_tw <= 16'h0059;
            7'h21 	:	o_tw <= 16'h005e;
            7'h22 	:	o_tw <= 16'h0064;
            7'h23 	:	o_tw <= 16'h006a;
            7'h24 	:	o_tw <= 16'h0070;
            7'h25 	:	o_tw <= 16'h0076;
            7'h26 	:	o_tw <= 16'h007d;
            7'h27 	:	o_tw <= 16'h0085;
            7'h28 	:	o_tw <= 16'h008d;
            7'h29 	:	o_tw <= 16'h0095;
            7'h2a 	:	o_tw <= 16'h009e;
            7'h2b 	:	o_tw <= 16'h00a7;
            7'h2c 	:	o_tw <= 16'h00b1;
            7'h2d 	:	o_tw <= 16'h00bc;
            7'h2e 	:	o_tw <= 16'h00c7;
            7'h2f 	:	o_tw <= 16'h00d3;
            7'h30 	:	o_tw <= 16'h00e0;
            7'h31 	:	o_tw <= 16'h00ed;
            7'h32 	:	o_tw <= 16'h00fb;
            7'h33 	:	o_tw <= 16'h010a;
            7'h34 	:	o_tw <= 16'h011a;
            7'h35 	:	o_tw <= 16'h012a;
            7'h36 	:	o_tw <= 16'h013c;
            7'h37 	:	o_tw <= 16'h014f;
            7'h38 	:	o_tw <= 16'h0163;
            7'h39 	:	o_tw <= 16'h0178;
            7'h3a 	:	o_tw <= 16'h018e;
            7'h3b 	:	o_tw <= 16'h01a6;
            7'h3c 	:	o_tw <= 16'h01bf;
            7'h3d 	:	o_tw <= 16'h01da;
            7'h3e 	:	o_tw <= 16'h01f6;
            7'h3f 	:	o_tw <= 16'h0214;
            7'h40 	:	o_tw <= 16'h0233;
            7'h41 	:	o_tw <= 16'h0255;
            7'h42 	:	o_tw <= 16'h0278;
            7'h43 	:	o_tw <= 16'h029e;
            7'h44 	:	o_tw <= 16'h02c6;
            7'h45 	:	o_tw <= 16'h02f0;
            7'h46 	:	o_tw <= 16'h031d;
            7'h47 	:	o_tw <= 16'h034c;
            7'h48 	:	o_tw <= 16'h037e;
            7'h49 	:	o_tw <= 16'h03b3;
            7'h4a 	:	o_tw <= 16'h03ec;
            7'h4b 	:	o_tw <= 16'h0427;
            7'h4c 	:	o_tw <= 16'h0467;
            7'h4d 	:	o_tw <= 16'h04aa;
            7'h4e 	:	o_tw <= 16'h04f1;
            7'h4f 	:	o_tw <= 16'h053c;
            7'h50 	:	o_tw <= 16'h058b;
            7'h51 	:	o_tw <= 16'h05e0;
            7'h52 	:	o_tw <= 16'h0639;
            7'h53 	:	o_tw <= 16'h0698;
            7'h54 	:	o_tw <= 16'h06fc;
            7'h55 	:	o_tw <= 16'h0767;
            7'h56 	:	o_tw <= 16'h07d7;
            7'h57 	:	o_tw <= 16'h084f;
            7'h58 	:	o_tw <= 16'h08cd;
            7'h59 	:	o_tw <= 16'h0953;
            7'h5a 	:	o_tw <= 16'h09e1;
            7'h5b 	:	o_tw <= 16'h0a78;
            7'h5c 	:	o_tw <= 16'h0b17;
            7'h5d 	:	o_tw <= 16'h0bc0;
            7'h5e 	:	o_tw <= 16'h0c73;
            7'h5f 	:	o_tw <= 16'h0d30;
            7'h60 	:	o_tw <= 16'h0df9;
            7'h61 	:	o_tw <= 16'h0ecd;
            7'h62 	:	o_tw <= 16'h0faf;
            7'h63 	:	o_tw <= 16'h109e;
            7'h64 	:	o_tw <= 16'h119a;
            7'h65 	:	o_tw <= 16'h12a6;
            7'h66 	:	o_tw <= 16'h13c2;
            7'h67 	:	o_tw <= 16'h14ef;
            7'h68 	:	o_tw <= 16'h162e;
            7'h69 	:	o_tw <= 16'h177f;
            7'h6a 	:	o_tw <= 16'h18e5;
            7'h6b 	:	o_tw <= 16'h1a60;
            7'h6c 	:	o_tw <= 16'h1bf2;
            7'h6d 	:	o_tw <= 16'h1d9b;
            7'h6e 	:	o_tw <= 16'h1f5e;
            7'h6f 	:	o_tw <= 16'h213b;
            7'h70 	:	o_tw <= 16'h2335;
            7'h71 	:	o_tw <= 16'h254d;
            7'h72 	:	o_tw <= 16'h2785;
            7'h73 	:	o_tw <= 16'h29de;
            7'h74 	:	o_tw <= 16'h2c5c;
            7'h75 	:	o_tw <= 16'h2eff;
            7'h76 	:	o_tw <= 16'h31ca;
            7'h77 	:	o_tw <= 16'h34c0;
            7'h78 	:	o_tw <= 16'h37e3;
            7'h79 	:	o_tw <= 16'h3b36;
            7'h7a 	:	o_tw <= 16'h3ebb;
            7'h7b 	:	o_tw <= 16'h4276;
            7'h7c 	:	o_tw <= 16'h466a;
            7'h7d 	:	o_tw <= 16'h4a9a;
            7'h7e 	:	o_tw <= 16'h4f09;
				default 	:	o_tw <= 16'h0000; // h7f is INVALID value
			endcase
		end	
endmodule

