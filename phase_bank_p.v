// Pipelined phase bank module

module phase_bank_p(input clk,
						input clk_en,
						input rst,
						input[6:0] i_midi,
						output reg[6:0] o_midi,
						output reg o_valid, 
						output reg[15:0] o_phase);
		parameter NBANKS = 10;
		
		reg[15:0] phase_banks[NBANKS-1:0];
		wire[15:0] w_tw;
		
		tuning_word_lut tw_lut(.i_midi(i_midi), .o_tw(w_tw));
		
		integer v_idx;
		integer i;
		
		initial begin
			o_phase = 16'b0;
			v_idx = 9;
			for (i = 0; i < NBANKS; i = i + 1) begin
				phase_banks[i] = 16'b0;
			end
			o_midi = 7'b0;
		end
		
		always @(posedge clk or posedge rst) begin
			if (rst) begin
				o_phase = 16'b0;
				v_idx = 9;
				for (i = 0; i < NBANKS; i = i + 1) begin
				phase_banks[i] <= 16'b0;
				end
				o_midi <= 7'b0;
			end else if (clk_en) begin
				if (i_midi !== 7'h0) begin
					o_phase <= phase_banks[v_idx]; // output a delayed value (one whole loop)
				end else begin
					o_phase <= 16'b0;
				end
				
				// should keep on calculating even though current value is invalid (pipelining works like this)
				if (v_idx == 0)  // tw is 1 cycle late
					phase_banks[NBANKS - 1] <= phase_banks[NBANKS - 1] + w_tw;
				else
					phase_banks[v_idx - 1] <= phase_banks[v_idx - 1] + w_tw;
					
				o_valid <= (i_midi == 7'h0) ? 1'b0 : 1'b1;
				o_midi <= i_midi;
				
				if (v_idx == NBANKS - 1)
					v_idx <= 0;
				else
					v_idx <= v_idx + 1;
			end
		end
						
endmodule

// precalculated for N = 16834(so 16 bits full period) by generate_tuning_word.py // TODO check tuning word needs to be such big!
module tuning_word_lut(input[6:0] i_midi,
								output reg[15:0] o_tw);
		initial o_tw = 16'b0;
		
		always @(i_midi) begin
			case(i_midi)
            7'h00 	:	o_tw <= 16'h008c;
            7'h01 	:	o_tw <= 16'h0094;
            7'h02 	:	o_tw <= 16'h009d;
            7'h03 	:	o_tw <= 16'h00a6;
            7'h04 	:	o_tw <= 16'h00b0;
            7'h05 	:	o_tw <= 16'h00bb;
            7'h06 	:	o_tw <= 16'h00c6;
            7'h07 	:	o_tw <= 16'h00d1;
            7'h08 	:	o_tw <= 16'h00de;
            7'h09 	:	o_tw <= 16'h00eb;
            7'h0a 	:	o_tw <= 16'h00f9;
            7'h0b 	:	o_tw <= 16'h0108;
            7'h0c 	:	o_tw <= 16'h0117;
            7'h0d 	:	o_tw <= 16'h0128;
            7'h0e 	:	o_tw <= 16'h013a;
            7'h0f 	:	o_tw <= 16'h014c;
            7'h10 	:	o_tw <= 16'h0160;
            7'h11 	:	o_tw <= 16'h0175;
            7'h12 	:	o_tw <= 16'h018b;
            7'h13 	:	o_tw <= 16'h01a3;
            7'h14 	:	o_tw <= 16'h01bc;
            7'h15 	:	o_tw <= 16'h01d6;
            7'h16 	:	o_tw <= 16'h01f2;
            7'h17 	:	o_tw <= 16'h0210;
            7'h18 	:	o_tw <= 16'h022f;
            7'h19 	:	o_tw <= 16'h0250;
            7'h1a 	:	o_tw <= 16'h0273;
            7'h1b 	:	o_tw <= 16'h0299;
            7'h1c 	:	o_tw <= 16'h02c0;
            7'h1d 	:	o_tw <= 16'h02ea;
            7'h1e 	:	o_tw <= 16'h0316;
            7'h1f 	:	o_tw <= 16'h0345;
            7'h20 	:	o_tw <= 16'h0377;
            7'h21 	:	o_tw <= 16'h03ac;
            7'h22 	:	o_tw <= 16'h03e4;
            7'h23 	:	o_tw <= 16'h041f;
            7'h24 	:	o_tw <= 16'h045e;
            7'h25 	:	o_tw <= 16'h04a0;
            7'h26 	:	o_tw <= 16'h04e7;
            7'h27 	:	o_tw <= 16'h0531;
            7'h28 	:	o_tw <= 16'h0580;
            7'h29 	:	o_tw <= 16'h05d4;
            7'h2a 	:	o_tw <= 16'h062d;
            7'h2b 	:	o_tw <= 16'h068b;
            7'h2c 	:	o_tw <= 16'h06ee;
            7'h2d 	:	o_tw <= 16'h0758;
            7'h2e 	:	o_tw <= 16'h07c8;
            7'h2f 	:	o_tw <= 16'h083e;
            7'h30 	:	o_tw <= 16'h08bb;
            7'h31 	:	o_tw <= 16'h0940;
            7'h32 	:	o_tw <= 16'h09cd;
            7'h33 	:	o_tw <= 16'h0a62;
            7'h34 	:	o_tw <= 16'h0b01;
            7'h35 	:	o_tw <= 16'h0ba8;
            7'h36 	:	o_tw <= 16'h0c59;
            7'h37 	:	o_tw <= 16'h0d15;
            7'h38 	:	o_tw <= 16'h0ddd;
            7'h39 	:	o_tw <= 16'h0eb0;
            7'h3a 	:	o_tw <= 16'h0f8f;
            7'h3b 	:	o_tw <= 16'h107c;
            7'h3c 	:	o_tw <= 16'h1177;
            7'h3d 	:	o_tw <= 16'h1281;
            7'h3e 	:	o_tw <= 16'h139a;
            7'h3f 	:	o_tw <= 16'h14c5;
            7'h40 	:	o_tw <= 16'h1601;
            7'h41 	:	o_tw <= 16'h1750;
            7'h42 	:	o_tw <= 16'h18b3;
            7'h43 	:	o_tw <= 16'h1a2b;
            7'h44 	:	o_tw <= 16'h1bb9;
            7'h45 	:	o_tw <= 16'h1d5f;
            7'h46 	:	o_tw <= 16'h1f1e;
            7'h47 	:	o_tw <= 16'h20f8;
            7'h48 	:	o_tw <= 16'h22ee;
            7'h49 	:	o_tw <= 16'h2502;
            7'h4a 	:	o_tw <= 16'h2735;
            7'h4b 	:	o_tw <= 16'h298a;
            7'h4c 	:	o_tw <= 16'h2c02;
            7'h4d 	:	o_tw <= 16'h2ea0;
            7'h4e 	:	o_tw <= 16'h3166;
            7'h4f 	:	o_tw <= 16'h3456;
            7'h50 	:	o_tw <= 16'h3772;
            7'h51 	:	o_tw <= 16'h3abe;
            7'h52 	:	o_tw <= 16'h3e3d;
            7'h53 	:	o_tw <= 16'h41f0;
            7'h54 	:	o_tw <= 16'h45dc;
            7'h55 	:	o_tw <= 16'h4a03;
            7'h56 	:	o_tw <= 16'h4e6a;
            7'h57 	:	o_tw <= 16'h5314;
            7'h58 	:	o_tw <= 16'h5804;
            7'h59 	:	o_tw <= 16'h5d40;
            7'h5a 	:	o_tw <= 16'h62cc;
            7'h5b 	:	o_tw <= 16'h68ab;
            7'h5c 	:	o_tw <= 16'h6ee5;
            7'h5d 	:	o_tw <= 16'h757d;
            7'h5e 	:	o_tw <= 16'h7c79;
            7'h5f 	:	o_tw <= 16'h83e0;
            7'h60 	:	o_tw <= 16'h8bb8;
            7'h61 	:	o_tw <= 16'h9406;
            7'h62 	:	o_tw <= 16'h9cd4;
            7'h63 	:	o_tw <= 16'ha627;
            7'h64 	:	o_tw <= 16'hb008;
            7'h65 	:	o_tw <= 16'hba80;
            7'h66 	:	o_tw <= 16'hc597;
            7'h67 	:	o_tw <= 16'hd157;
            7'h68 	:	o_tw <= 16'hddca;
            7'h69 	:	o_tw <= 16'heafa;
            7'h6a 	:	o_tw <= 16'hf8f3;
            7'h6b 	:	o_tw <= 16'h107c0;
            7'h6c 	:	o_tw <= 16'h1176f;
            7'h6d 	:	o_tw <= 16'h1280d;
            7'h6e 	:	o_tw <= 16'h139a8;
            7'h6f 	:	o_tw <= 16'h14c4e;
            7'h70 	:	o_tw <= 16'h16011;
            7'h71 	:	o_tw <= 16'h17500;
            7'h72 	:	o_tw <= 16'h18b2e;
            7'h73 	:	o_tw <= 16'h1a2ae;
            7'h74 	:	o_tw <= 16'h1bb93;
            7'h75 	:	o_tw <= 16'h1d5f3;
            7'h76 	:	o_tw <= 16'h1f1e5;
            7'h77 	:	o_tw <= 16'h20f81;
            7'h78 	:	o_tw <= 16'h22edf;
            7'h79 	:	o_tw <= 16'h2501a;
            7'h7a 	:	o_tw <= 16'h2734f;
            7'h7b 	:	o_tw <= 16'h2989c;
            7'h7c 	:	o_tw <= 16'h2c022;
            7'h7d 	:	o_tw <= 16'h2ea00;
            7'h7e 	:	o_tw <= 16'h3165c;
            7'h7f 	:	o_tw <= 16'h3455c;
				default 	:	o_tw <= 16'h0000; // h00 is MIDI 0 value
			endcase
		end	
endmodule
