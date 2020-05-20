// Pipelined State variable filter based on Andrew Simper's SVF whitepaper https://cytomic.com/files/dsp/SvfLinearTrapOptimised2.pdf

module state_variable_filter_iir_p(input clk,
											input clk_en,
											input rst,
											input[6:0] i_midi,
											output reg[6:0] o_midi,
											input signed[23:0] i_data,
											input i_valid,
											output reg o_valid,
											output reg signed[23:0] o_filtered // == v2
											);
	parameter NBANKS = 10;
	
	reg signed[34:0] v1[NBANKS-1:0];
	reg signed[34:0] v2[NBANKS-1:0];
	reg signed[34:0] v3[NBANKS-1:0];
	reg signed[34:0] ic1eq[NBANKS-1:0];
	reg signed[34:0] ic2eq[NBANKS-1:0];
	
	wire signed[34:0] w_a1, w_a2, w_a3;
	
	wire signed[64:0] mR_0, mR_1, mR_2, mR_3;
	
	reg signed[34:0] r_m_a1, r_m_a2, r_m_a3, r_m_ic1eq, r_m_v3;
	
	// for buffering values
	reg valid[2:0];
	reg[6:0] midi[2:0];
	reg signed[34:0] r_ext_i_data;
	
	
	reg[4:0] 		d0, d1, d2, d3, d4, d5, d6, d7; //dummy registeres
	wire[14:0] 		dm0, dm1, dm2, dm3;//dummy wires for driving the multipliers (cannot be left floating)
	
	coefficients_lut lut(.i_midi(i_midi), 
								.o_a1(w_a1),
								.o_a2(w_a2), 
								.o_a3(w_a3));
								
	lpm_multiplier 
						mult0(.dataa({d0 ,r_m_a1}),
								.datab({d1, r_m_ic1eq}),
								.result({dm0, mR_0})),
						mult1(.dataa({d2, r_m_a2}), 
								.datab({d3, r_m_v3}), 
								.result({dm1, mR_1})),
						mult2(.dataa({d4, r_m_a2}), 
								.datab({d5, r_m_ic1eq}), 
								.result({dm2, mR_2})),
						mult3(.dataa({d6, r_m_a3}), 
								.datab({d7, r_m_v3}), 
								.result({dm3, mR_3}));
								
	integer v_idx;
	integer i;
	
	initial begin
		for (i = 0; i < NBANKS; i = i + 1) begin
			v1[i] = 35'b0;
			v2[i] = 35'b0;
			v3[i] = 35'b0;
			ic1eq[i] = 35'b0;
			ic2eq[i] = 35'b0;
		end
		for (i = 0; i < 3; i = i + 1) begin
			valid[i] = 1'b0;
			midi[i] = 7'b0;
		end
		r_m_a1 = 35'b0;
		r_m_a2 = 35'b0;
		r_m_a3 = 35'b0;
		r_m_ic1eq = 35'b0;
		r_m_v3 = 35'b0;
		r_ext_i_data = 35'b0;
		
		d0 = 5'b0;
		d1 = 5'b0;
		d2 = 5'b0;
		d3 = 5'b0;
		d4 = 5'b0;
		d5 = 5'b0;
		d6 = 5'b0;
		d7 = 5'b0;
		
		v_idx = 5;
	end
	
	always @(posedge clk or posedge rst) begin
		if (rst) begin // what about passthrough midi value?
			for (i = 0; i < NBANKS; i = i + 1) begin
				v1[i] <= 35'b0;
				v2[i] <= 35'b0;
				v3[i] <= 35'b0;
				ic1eq[i] <= 35'b0;
				ic2eq[i] <= 35'b0;		
			end
			for (i = 0; i < 3; i = i + 1) begin
				valid[i] <= 1'b0;
				midi[i] <= 7'b0;
			end
			r_m_a1 <= 35'b0;
			r_m_a2 <= 35'b0;
			r_m_a3 <= 35'b0;
			r_m_ic1eq <= 35'b0;
			r_m_v3 <= 35'b0;
			r_ext_i_data <= 35'b0;
			
			d0 <= 5'b0;
			d1 <= 5'b0;
			d2 <= 5'b0;
			d3 <= 5'b0;
			d4 <= 5'b0;
			d5 <= 5'b0;
			d6 <= 5'b0;
			d7 <= 5'b0;
			
			v_idx <= 5;
		end else if (clk_en) begin
			// four cycles of delay - sine-like solution
			// first cycle calc coefficients -> clear registers if midi 00
			if (i_midi == 7'b0) begin
				v1[v_idx] <= 35'b0;
				v2[v_idx] <= 35'b0;
				v3[v_idx] <= 35'b0;
				ic1eq[v_idx] <= 35'b0;
				ic2eq[v_idx] <= 35'b0;
			end else begin
			
			// second cycle -> start multiplication
			r_m_a1 <= w_a1;
			r_m_a2 <= w_a2;
			r_m_a3 <= w_a3;
			if (v_idx == 0) begin
				// filter step
				v3[NBANKS - 1] <= r_ext_i_data - ic2eq[NBANKS - 1];
				// fill the lpm_multiplier
				r_m_ic1eq <= ic1eq[NBANKS - 1];
				r_m_v3 <= r_ext_i_data - ic2eq[NBANKS - 1]; // to prevent 1 cycle delay
			end else begin
				// filter step
				v3[v_idx - 1] <= r_ext_i_data - ic2eq[v_idx - 1];
				// fill the lpm_multiplier
				r_m_ic1eq <= ic1eq[v_idx - 1];
				r_m_v3 <= r_ext_i_data - ic2eq[v_idx - 1]; // to prevent 1 cycle delay
			end

			// third cycle -> obtain multiplication results
			if (v_idx == 0) begin
				v1[NBANKS - 2] <= (mR_0 >>> 31) + (mR_1 >>> 31); // remove scaling factor due to multiplication  (probably need to take a slice out of it, truncates automatically)
				v2[NBANKS - 2] <= ic2eq[NBANKS - 2] + (mR_2 >>> 31) + (mR_3 >>> 31); // should this be a shift or (TODO: this could probably need a greater width...?)
			end else if (v_idx == 1) begin
				v1[NBANKS - 1] <= (mR_0 >>> 31) + (mR_1 >>> 31);
				v2[NBANKS - 1] <= ic2eq[NBANKS - 1] + (mR_2 >>> 31) + (mR_3 >>> 31);
			end else begin
				v1[v_idx - 2] <= (mR_0 >>> 31) + (mR_1 >>> 31);
				v2[v_idx - 2] <= ic2eq[v_idx - 2] + (mR_2 >>> 31) + (mR_3 >>> 31);
			end

			// fourth cycle -> last steps and output result
			if (v_idx == 0) begin
				ic1eq[NBANKS - 3] <= (v1[NBANKS - 3] <<< 2) - ic1eq[NBANKS - 3];
				ic2eq[NBANKS - 3] <= (v2[NBANKS - 3] <<< 2) - ic2eq[NBANKS - 3];
				o_filtered <= {v2[NBANKS - 3][32], v2[NBANKS - 3][31:9]};
			end else if (v_idx == 1) begin
				ic1eq[NBANKS - 2] <= (v1[NBANKS - 2] <<< 2) - ic1eq[NBANKS - 2];
				ic2eq[NBANKS - 2] <= (v2[NBANKS - 2] <<< 2) - ic2eq[NBANKS - 2];
				o_filtered <= {v2[NBANKS - 2][32], v2[NBANKS - 2][31:9]};		
			end else if (v_idx == 2) begin
				ic1eq[NBANKS - 1] <= (v1[NBANKS - 1] <<< 2) - ic1eq[NBANKS - 1];
				ic2eq[NBANKS - 1] <= (v2[NBANKS - 1] <<< 2) - ic2eq[NBANKS - 1];
				o_filtered <= {v2[NBANKS - 1][32], v2[NBANKS - 1][31:9]};
			end else begin
				ic1eq[v_idx - 3] <= (v1[v_idx - 3] <<< 2) - ic1eq[v_idx - 3];
				ic2eq[v_idx - 3] <= (v2[v_idx - 3] <<< 2) - ic2eq[v_idx - 3];
				o_filtered <= {v2[v_idx - 3][32], v2[v_idx - 3][31:9]};				
			end
			
			// move valid value
			valid[0] <= i_valid;
			valid[1] <= valid[0];
			valid[2] <= valid[1];
			o_valid <= valid[2];
			
			// move midi value
			midi[0] <= i_midi;
			midi[1] <= midi[0];
			midi[2] <= midi[1];
			o_midi <= midi[2];
			
			r_ext_i_data <= {{3{i_data[23]}}, {i_data[22:0]}, 9'b0};
			
			if (v_idx == NBANKS - 1)
				v_idx <= 0;
			else
				v_idx <= v_idx + 1;
		end
	end

endmodule

module coefficients_lut(input[6:0] i_midi,
								output reg signed[34:0] o_a1,
								output reg signed[34:0] o_a2,
								output reg signed[34:0] o_a3); // q format needed here check maths if are proper, addition substraction and multiplication have to be done
										// check required precision for calculating the output signal etc, when to convert and how v2 -> output signal, input should be rescaled to -1 - 1 range? and to q format?
	initial begin
		o_a1 = 35'b0;
		o_a2 = 35'b0;
		o_a3 = 35'b0;
	end
	
	always @(i_midi) begin
		case (i_midi)
            7'h00 	:	 begin 
                o_a1 <= 35'b00000000000000000000000000000000000; // must be 0
                o_a2 <= 35'b00000000000000000000000000000000000;
                o_a3 <= 35'b00000000000000000000000000000000000;
                end
            7'h01 	:	 begin 
                o_a1 <= 35'b00001111111100001100101010011110110;
                o_a2 <= 35'b00000000000001111001100011100001000;
                o_a3 <= 35'b00000000000000000000001110011110111;
                end
            7'h02 	:	 begin 
                o_a1 <= 35'b00001111111000010101111000011010111;
                o_a2 <= 35'b00000000000011110100100110010110110;
                o_a3 <= 35'b00000000000000000000111010110111011;
                end
            7'h03 	:	 begin 
                o_a1 <= 35'b00001111110100011011101000001100011;
                o_a2 <= 35'b00000000000101110001001000100110111;
                o_a3 <= 35'b00000000000000000010000110100101100;
                end
            7'h04 	:	 begin 
                o_a1 <= 35'b00001111110000011101111000001110000;
                o_a2 <= 35'b00000000000111101111001010010100111;
                o_a3 <= 35'b00000000000000000011110011001000000;
                end
            7'h05 	:	 begin 
                o_a1 <= 35'b00001111101100011100100110111101000;
                o_a2 <= 35'b00000000001001101110101011100001000;
                o_a3 <= 35'b00000000000000000110000010000000111;
                end
            7'h06 	:	 begin 
                o_a1 <= 35'b00001111101000010111110010111001011;
                o_a2 <= 35'b00000000001011101111101100001000110;
                o_a3 <= 35'b00000000000000001000110100110100111;
                end
            7'h07 	:	 begin 
                o_a1 <= 35'b00001111100100001111011010100110000;
                o_a2 <= 35'b00000000001101110010001100000110110;
                o_a3 <= 35'b00000000000000001100001101001100011;
                end
            7'h08 	:	 begin 
                o_a1 <= 35'b00001111100000000011011100101000101;
                o_a2 <= 35'b00000000001111110110001011010010010;
                o_a3 <= 35'b00000000000000010000001100110010101;
                end
            7'h09 	:	 begin 
                o_a1 <= 35'b00001111011011110011110111101010011;
                o_a2 <= 35'b00000000010001111011101001011111100;
                o_a3 <= 35'b00000000000000010100110101010110011;
                end
            7'h0a 	:	 begin 
                o_a1 <= 35'b00001111010111100000101010010111001;
                o_a2 <= 35'b00000000010100000010100110011111101;
                o_a3 <= 35'b00000000000000011010001000101001011;
                end
            7'h0b 	:	 begin 
                o_a1 <= 35'b00001111010011001001110011011110110;
                o_a2 <= 35'b00000000010110001011000001111111111;
                o_a3 <= 35'b00000000000000100000001000100001011;
                end
            7'h0c 	:	 begin 
                o_a1 <= 35'b00001111001110101111010001110100000;
                o_a2 <= 35'b00000000011000010100111011101010011;
                o_a3 <= 35'b00000000000000100110110110110110111;
                end
            7'h0d 	:	 begin 
                o_a1 <= 35'b00001111001010010001000100001101101;
                o_a2 <= 35'b00000000011010100000010011000101110;
                o_a3 <= 35'b00000000000000101110010101100110101;
                end
            7'h0e 	:	 begin 
                o_a1 <= 35'b00001111000101101111001001100101110;
                o_a2 <= 35'b00000000011100101101000111110100101;
                o_a3 <= 35'b00000000000000110110100110110000101;
                end
            7'h0f 	:	 begin 
                o_a1 <= 35'b00001111000001001001100000111010110;
                o_a2 <= 35'b00000000011110111011011001010110011;
                o_a3 <= 35'b00000000000000111111101100011000011;
                end
            7'h10 	:	 begin 
                o_a1 <= 35'b00001110111100100000001001001110100;
                o_a2 <= 35'b00000000100001001011000111000101111;
                o_a3 <= 35'b00000000000001001001101000100101100;
                end
            7'h11 	:	 begin 
                o_a1 <= 35'b00001110110111110011000001100111011;
                o_a2 <= 35'b00000000100011011100010000011010101;
                o_a3 <= 35'b00000000000001010100011101100011001;
                end
            7'h12 	:	 begin 
                o_a1 <= 35'b00001110110011000010001001001111101;
                o_a2 <= 35'b00000000100101101110110100100111111;
                o_a3 <= 35'b00000000000001100000001101100000100;
                end
            7'h13 	:	 begin 
                o_a1 <= 35'b00001110101110001101011111010110001;
                o_a2 <= 35'b00000000101000000010110010111100101;
                o_a3 <= 35'b00000000000001101100111010110000100;
                end
            7'h14 	:	 begin 
                o_a1 <= 35'b00001110101001010101000011001110000;
                o_a2 <= 35'b00000000101010011000001010100011110;
                o_a3 <= 35'b00000000000001111010100111101010010;
                end
            7'h15 	:	 begin 
                o_a1 <= 35'b00001110100100011000110100001110111;
                o_a2 <= 35'b00000000101100101110111010100100001;
                o_a3 <= 35'b00000000000010001001010110101000110;
                end
            7'h16 	:	 begin 
                o_a1 <= 35'b00001110011111011000110001110101001;
                o_a2 <= 35'b00000000101111000111000001111111101;
                o_a3 <= 35'b00000000000010011001001010001011010;
                end
            7'h17 	:	 begin 
                o_a1 <= 35'b00001110011010010100111011100010000;
                o_a2 <= 35'b00000000110001100000011111110100010;
                o_a3 <= 35'b00000000000010101010000100110101001;
                end
            7'h18 	:	 begin 
                o_a1 <= 35'b00001110010101001101010000111011100;
                o_a2 <= 35'b00000000110011111011010010111011001;
                o_a3 <= 35'b00000000000010111100001001001110000;
                end
            7'h19 	:	 begin 
                o_a1 <= 35'b00001110010000000001110001101100101;
                o_a2 <= 35'b00000000110110010111011010001000101;
                o_a3 <= 35'b00000000000011001111011010000001110;
                end
            7'h1a 	:	 begin 
                o_a1 <= 35'b00001110001010110010011101100101100;
                o_a2 <= 35'b00000000111000110100110100001100110;
                o_a3 <= 35'b00000000000011100011111010000000110;
                end
            7'h1b 	:	 begin 
                o_a1 <= 35'b00001110000101011111010100011011010;
                o_a2 <= 35'b00000000111011010011011111110010100;
                o_a3 <= 35'b00000000000011111001101011111111101;
                end
            7'h1c 	:	 begin 
                o_a1 <= 35'b00001110000000001000010110001000100;
                o_a2 <= 35'b00000000111101110011011011011111111;
                o_a3 <= 35'b00000000000100010000110010110111101;
                end
            7'h1d 	:	 begin 
                o_a1 <= 35'b00001101111010101101100010101101001;
                o_a2 <= 35'b00000001000000010100100101110110000;
                o_a3 <= 35'b00000000000100101001010001100110100;
                end
            7'h1e 	:	 begin 
                o_a1 <= 35'b00001101110101001110111010001110100;
                o_a2 <= 35'b00000001000010110110111101010001011;
                o_a3 <= 35'b00000000000101000011001011001110101;
                end
            7'h1f 	:	 begin 
                o_a1 <= 35'b00001101101111101100011100110111011;
                o_a2 <= 35'b00000001000101011010100000001000101;
                o_a3 <= 35'b00000000000101011110100010110111000;
                end
            7'h20 	:	 begin 
                o_a1 <= 35'b00001101101010000110001010111000010;
                o_a2 <= 35'b00000001000111111111001100101101111;
                o_a3 <= 35'b00000000000101111011011011101011101;
                end
            7'h21 	:	 begin 
                o_a1 <= 35'b00001101100100011100000100100111010;
                o_a2 <= 35'b00000001001010100101000001001101110;
                o_a3 <= 35'b00000000000110011001111000111101000;
                end
            7'h22 	:	 begin 
                o_a1 <= 35'b00001101011110101110001010011111111;
                o_a2 <= 35'b00000001001101001011111011101111101;
                o_a3 <= 35'b00000000000110111001111110000000100;
                end
            7'h23 	:	 begin 
                o_a1 <= 35'b00001101011000111100011101000100000;
                o_a2 <= 35'b00000001001111110011111010010101100;
                o_a3 <= 35'b00000000000111011011101110010000110;
                end
            7'h24 	:	 begin 
                o_a1 <= 35'b00001101010011000110111100111010111;
                o_a2 <= 35'b00000001010010011100111010111011111;
                o_a3 <= 35'b00000000000111111111001101001101000;
                end
            7'h25 	:	 begin 
                o_a1 <= 35'b00001101001101001101101010110001110;
                o_a2 <= 35'b00000001010101000110111011011010001;
                o_a3 <= 35'b00000000001000100100011110011001110;
                end
            7'h26 	:	 begin 
                o_a1 <= 35'b00001101000111010000100111011011101;
                o_a2 <= 35'b00000001010111110001111001100001110;
                o_a3 <= 35'b00000000001001001011100101100000101;
                end
            7'h27 	:	 begin 
                o_a1 <= 35'b00001101000001001111110011110001101;
                o_a2 <= 35'b00000001011010011101110010111110110;
                o_a3 <= 35'b00000000001001110100100110010000101;
                end
            7'h28 	:	 begin 
                o_a1 <= 35'b00001100111011001011010000110010110;
                o_a2 <= 35'b00000001011101001010100101010111110;
                o_a3 <= 35'b00000000001010011111100100011101101;
                end
            7'h29 	:	 begin 
                o_a1 <= 35'b00001100110101000010111111100011110;
                o_a2 <= 35'b00000001011111111000001110001101011;
                o_a3 <= 35'b00000000001011001100100100000001010;
                end
            7'h2a 	:	 begin 
                o_a1 <= 35'b00001100101110110111000001001111011;
                o_a2 <= 35'b00000001100010100110101010111011001;
                o_a3 <= 35'b00000000001011111011101000111010010;
                end
            7'h2b 	:	 begin 
                o_a1 <= 35'b00001100101000100111010111000110100;
                o_a2 <= 35'b00000001100101010101111000110110000;
                o_a3 <= 35'b00000000001100101100110111001101001;
                end
            7'h2c 	:	 begin 
                o_a1 <= 35'b00001100100010010100000010011111110;
                o_a2 <= 35'b00000001101000000101110101001110000;
                o_a3 <= 35'b00000000001101100000010011000011111;
                end
            7'h2d 	:	 begin 
                o_a1 <= 35'b00001100011011111101000100110111101;
                o_a2 <= 35'b00000001101010110110011101001100111;
                o_a3 <= 35'b00000000001110010110000000101110010;
                end
            7'h2e 	:	 begin 
                o_a1 <= 35'b00001100010101100010011111110000100;
                o_a2 <= 35'b00000001101101100111101101110110110;
                o_a3 <= 35'b00000000001111001110000100100001110;
                end
            7'h2f 	:	 begin 
                o_a1 <= 35'b00001100001111000100010100110010101;
                o_a2 <= 35'b00000001110000011001100100001001111;
                o_a3 <= 35'b00000000010000001000100010111001100;
                end
            7'h30 	:	 begin 
                o_a1 <= 35'b00001100001000100010100101101011101;
                o_a2 <= 35'b00000001110011001011111100111110100;
                o_a3 <= 35'b00000000010001000101100000010111001;
                end
            7'h31 	:	 begin 
                o_a1 <= 35'b00001100000001111101010100001111011;
                o_a2 <= 35'b00000001110101111110110101000111010;
                o_a3 <= 35'b00000000010010000101000001100001111;
                end
            7'h32 	:	 begin 
                o_a1 <= 35'b00001011111011010100100010010110110;
                o_a2 <= 35'b00000001111000110010001001010000110;
                o_a3 <= 35'b00000000010011000111001011000111011;
                end
            7'h33 	:	 begin 
                o_a1 <= 35'b00001011110100101000010010000000100;
                o_a2 <= 35'b00000001111011100101110110000001110;
                o_a3 <= 35'b00000000010100001100000001111011110;
                end
            7'h34 	:	 begin 
                o_a1 <= 35'b00001011101101111000100101010000110;
                o_a2 <= 35'b00000001111110011001110111111010111;
                o_a3 <= 35'b00000000010101010011101010111001011;
                end
            7'h35 	:	 begin 
                o_a1 <= 35'b00001011100111000101011110010000101;
                o_a2 <= 35'b00000010000001001110001011010110111;
                o_a3 <= 35'b00000000010110011110001011000001010;
                end
            7'h36 	:	 begin 
                o_a1 <= 35'b00001011100000001110111111001110110;
                o_a2 <= 35'b00000010000100000010101100101010111;
                o_a3 <= 35'b00000000010111101011100111011011011;
                end
            7'h37 	:	 begin 
                o_a1 <= 35'b00001011011001010101001010011110011;
                o_a2 <= 35'b00000010000110110111011000000101011;
                o_a3 <= 35'b00000000011000111100000101010110100;
                end
            7'h38 	:	 begin 
                o_a1 <= 35'b00001011010010011000000010011000000;
                o_a2 <= 35'b00000010001001101100001001101111101;
                o_a3 <= 35'b00000000011010001111101010001000101;
                end
            7'h39 	:	 begin 
                o_a1 <= 35'b00001011001011010111101001011000101;
                o_a2 <= 35'b00000010001100100000111101101100010;
                o_a3 <= 35'b00000000011011100110011011001110110;
                end
            7'h3a 	:	 begin 
                o_a1 <= 35'b00001011000100010100000010000001110;
                o_a2 <= 35'b00000010001111010101101111111000001;
                o_a3 <= 35'b00000000011101000000011110001101111;
                end
            7'h3b 	:	 begin 
                o_a1 <= 35'b00001010111101001101001110111001011;
                o_a2 <= 35'b00000010010010001010011100001010000;
                o_a3 <= 35'b00000000011110011101111000110010011;
                end
            7'h3c 	:	 begin 
                o_a1 <= 35'b00001010110110000011010010101001101;
                o_a2 <= 35'b00000010010100111110111110010010101;
                o_a3 <= 35'b00000000011111111110110000110000111;
                end
            7'h3d 	:	 begin 
                o_a1 <= 35'b00001010101110110110010000000000011;
                o_a2 <= 35'b00000010010111110011010001111100100;
                o_a3 <= 35'b00000000100001100011001100000110011;
                end
            7'h3e 	:	 begin 
                o_a1 <= 35'b00001010100111100110001001101111010;
                o_a2 <= 35'b00000010011010100111010010101100010;
                o_a3 <= 35'b00000000100011001011010000111000000;
                end
            7'h3f 	:	 begin 
                o_a1 <= 35'b00001010100000010011000010101011101;
                o_a2 <= 35'b00000010011101011010111100000000000;
                o_a3 <= 35'b00000000100100110111000101010100001;
                end
            7'h40 	:	 begin 
                o_a1 <= 35'b00001010011000111100111101101101111;
                o_a2 <= 35'b00000010100000001110001001001111110;
                o_a3 <= 35'b00000000100110100110101111110010011;
                end
            7'h41 	:	 begin 
                o_a1 <= 35'b00001010010001100011111101110001011;
                o_a2 <= 35'b00000010100011000000110101101101010;
                o_a3 <= 35'b00000000101000011010010110110011111;
                end
            7'h42 	:	 begin 
                o_a1 <= 35'b00001010001010001000000101110100010;
                o_a2 <= 35'b00000010100101110010111100100100000;
                o_a3 <= 35'b00000000101010010010000001000011101;
                end
            7'h43 	:	 begin 
                o_a1 <= 35'b00001010000010101001011000110111000;
                o_a2 <= 35'b00000010101000100100011000111000110;
                o_a3 <= 35'b00000000101100001101110101010111010;
                end
            7'h44 	:	 begin 
                o_a1 <= 35'b00001001111011000111111001111100011;
                o_a2 <= 35'b00000010101011010101000101101010000;
                o_a3 <= 35'b00000000101110001101111010101111011;
                end
            7'h45 	:	 begin 
                o_a1 <= 35'b00001001110011100011101100001000110;
                o_a2 <= 35'b00000010101110000100111101101111101;
                o_a3 <= 35'b00000000110000010010011000010111110;
                end
            7'h46 	:	 begin 
                o_a1 <= 35'b00001001101011111100110010100010010;
                o_a2 <= 35'b00000010110000110011111011111010100;
                o_a3 <= 35'b00000000110010011011010101101000100;
                end
            7'h47 	:	 begin 
                o_a1 <= 35'b00001001100100010011010000010000001;
                o_a2 <= 35'b00000010110011100001111010110100111;
                o_a3 <= 35'b00000000110100101000111010000110000;
                end
            7'h48 	:	 begin 
                o_a1 <= 35'b00001001011100100111001000011010011;
                o_a2 <= 35'b00000010110110001110110101000001101;
                o_a3 <= 35'b00000000110110111011001101100010001;
                end
            7'h49 	:	 begin 
                o_a1 <= 35'b00001001010100111000011110001001100;
                o_a2 <= 35'b00000010111000111010100100111100110;
                o_a3 <= 35'b00000000111001010010010111111100101;
                end
            7'h4a 	:	 begin 
                o_a1 <= 35'b00001001001101000111010100100110011;
                o_a2 <= 35'b00000010111011100101000100111010101;
                o_a3 <= 35'b00000000111011101110100001100100001;
                end
            7'h4b 	:	 begin 
                o_a1 <= 35'b00001001000101010011101110111001011;
                o_a2 <= 35'b00000010111110001110001111000111111;
                o_a3 <= 35'b00000000111110001111110010110110101;
                end
            7'h4c 	:	 begin 
                o_a1 <= 35'b00001000111101011101110000001010101;
                o_a2 <= 35'b00000011000000110101111101101001001;
                o_a3 <= 35'b00000001000000110110010100100010111;
                end
            7'h4d 	:	 begin 
                o_a1 <= 35'b00001000110101100101011011100001000;
                o_a2 <= 35'b00000011000011011100001010011011000;
                o_a3 <= 35'b00000001000011100010001111101000111;
                end
            7'h4e 	:	 begin 
                o_a1 <= 35'b00001000101101101010110100000010001;
                o_a2 <= 35'b00000011000110000000101111010001001;
                o_a3 <= 35'b00000001000110010011101101011011100;
                end
            7'h4f 	:	 begin 
                o_a1 <= 35'b00001000100101101101111100110010000;
                o_a2 <= 35'b00000011001000100011100101110110011;
                o_a3 <= 35'b00000001001001001010110111100001000;
                end
            7'h50 	:	 begin 
                o_a1 <= 35'b00001000011101101110111000110010100;
                o_a2 <= 35'b00000011001011000100100111101100001;
                o_a3 <= 35'b00000001001100000111110111110100111;
                end
            7'h51 	:	 begin 
                o_a1 <= 35'b00001000010101101101101011000010111;
                o_a2 <= 35'b00000011001101100011101110001001111;
                o_a3 <= 35'b00000001001111001010111000101001000;
                end
            7'h52 	:	 begin 
                o_a1 <= 35'b00001000001101101010010110011111100;
                o_a2 <= 35'b00000011010000000000110010011100101;
                o_a3 <= 35'b00000001010010010100000100100111000;
                end
            7'h53 	:	 begin 
                o_a1 <= 35'b00001000000101100100111110000001011;
                o_a2 <= 35'b00000011010010011011101101100110001;
                o_a3 <= 35'b00000001010101100011100110110010000;
                end
            7'h54 	:	 begin 
                o_a1 <= 35'b00000111111101011101100100011110000;
                o_a2 <= 35'b00000011010100110100011000011100101;
                o_a3 <= 35'b00000001011000111001101010101000011;
                end
            7'h55 	:	 begin 
                o_a1 <= 35'b00000111110101010100001100100110011;
                o_a2 <= 35'b00000011010111001010101011101001111;
                o_a3 <= 35'b00000001011100010110011100000101110;
                end
            7'h56 	:	 begin 
                o_a1 <= 35'b00000111101101001000111001000111010;
                o_a2 <= 35'b00000011011001011110011111101001111;
                o_a3 <= 35'b00000001011111111010000111100100101;
                end
            7'h57 	:	 begin 
                o_a1 <= 35'b00000111100100111011101100101000100;
                o_a2 <= 35'b00000011011011101111101100101010111;
                o_a3 <= 35'b00000001100011100100111010000001100;
                end
            7'h58 	:	 begin 
                o_a1 <= 35'b00000111011100101100101001101100011;
                o_a2 <= 35'b00000011011101111110001010101011101;
                o_a3 <= 35'b00000001100111010111000000111100010;
                end
            7'h59 	:	 begin 
                o_a1 <= 35'b00000111010100011011110010101111110;
                o_a2 <= 35'b00000011100000001001110001011010010;
                o_a3 <= 35'b00000001101011010000101010011011101;
                end
            7'h5a 	:	 begin 
                o_a1 <= 35'b00000111001100001001001010001001011;
                o_a2 <= 35'b00000011100010010010011000010011010;
                o_a3 <= 35'b00000001101111010010000101001111111;
                end
            7'h5b 	:	 begin 
                o_a1 <= 35'b00000111000011110100110010001001101;
                o_a2 <= 35'b00000011100100010111110110100000001;
                o_a3 <= 35'b00000001110011011011100000110101110;
                end
            7'h5c 	:	 begin 
                o_a1 <= 35'b00000110111011011110101100111010001;
                o_a2 <= 35'b00000011100110011010000010110101110;
                o_a3 <= 35'b00000001110111101101001101011010010;
                end
            7'h5d 	:	 begin 
                o_a1 <= 35'b00000110110011000110111100011101010;
                o_a2 <= 35'b00000011101000011000110011110010010;
                o_a3 <= 35'b00000001111100000111011011111110001;
                end
            7'h5e 	:	 begin 
                o_a1 <= 35'b00000110101010101101100010101110100;
                o_a2 <= 35'b00000011101010010011111111011011100;
                o_a3 <= 35'b00000010000000101010011110011010001;
                end
            7'h5f 	:	 begin 
                o_a1 <= 35'b00000110100010010010100001100001101;
                o_a2 <= 35'b00000011101100001011011011011101011;
                o_a3 <= 35'b00000010000101010110100111100011011;
                end
            7'h60 	:	 begin 
                o_a1 <= 35'b00000110011001110101111010100010011;
                o_a2 <= 35'b00000011101101111110111101000110011;
                o_a3 <= 35'b00000010001010001100001011010000101;
                end
            7'h61 	:	 begin 
                o_a1 <= 35'b00000110010001010111101111010101000;
                o_a2 <= 35'b00000011101111101110011001000101110;
                o_a3 <= 35'b00000010001111001011011110011111001;
                end
            7'h62 	:	 begin 
                o_a1 <= 35'b00000110001000111000000001010101011;
                o_a2 <= 35'b00000011110001011001100011101000110;
                o_a3 <= 35'b00000010010100010100110111011000111;
                end
            7'h63 	:	 begin 
                o_a1 <= 35'b00000110000000010110110001110111011;
                o_a2 <= 35'b00000011110011000000010000010110110;
                o_a3 <= 35'b00000010011001101000101101011010110;
                end
            7'h64 	:	 begin 
                o_a1 <= 35'b00000101110111110100000010000111001;
                o_a2 <= 35'b00000011110100100010010010001110010;
                o_a3 <= 35'b00000010011111000111011001011100001;
                end
            7'h65 	:	 begin 
                o_a1 <= 35'b00000101101111001111110011001000011;
                o_a2 <= 35'b00000011110101111111011011100000101;
                o_a3 <= 35'b00000010100100110001010101110110010;
                end
            7'h66 	:	 begin 
                o_a1 <= 35'b00000101100110101010000101110111100;
                o_a2 <= 35'b00000011110111010111011101101101101;
                o_a3 <= 35'b00000010101010100110111110101100111;
                end
            7'h67 	:	 begin 
                o_a1 <= 35'b00000101011110000010111011001001011;
                o_a2 <= 35'b00000011111000101010001001011111001;
                o_a3 <= 35'b00000010110000101000110001111000001;
                end
            7'h68 	:	 begin 
                o_a1 <= 35'b00000101010101011010010011101100000;
                o_a2 <= 35'b00000011111001110111001110100010110;
                o_a3 <= 35'b00000010110110110111001111001110011;
                end
            7'h69 	:	 begin 
                o_a1 <= 35'b00000101001100110000010000000111001;
                o_a2 <= 35'b00000011111010111110011011100100001;
                o_a3 <= 35'b00000010111101010010111000110000100;
                end
            7'h6a 	:	 begin 
                o_a1 <= 35'b00000101000100000100110000111101001;
                o_a2 <= 35'b00000011111011111111011110000110011;
                o_a3 <= 35'b00000011000011111100010010110110000;
                end
            7'h6b 	:	 begin 
                o_a1 <= 35'b00000100111011010111110110101011111;
                o_a2 <= 35'b00000011111100111010000010011100000;
                o_a3 <= 35'b00000011001010110100000100011011110;
                end
            7'h6c 	:	 begin 
                o_a1 <= 35'b00000100110010101001100001101110101;
                o_a2 <= 35'b00000011111101101101110011011110101;
                o_a3 <= 35'b00000011010001111010110111010011111;
                end
            7'h6d 	:	 begin 
                o_a1 <= 35'b00000100101001111001110010011110101;
                o_a2 <= 35'b00000011111110011010011010100101001;
                o_a3 <= 35'b00000011011001010001011000010110111;
                end
            7'h6e 	:	 begin 
                o_a1 <= 35'b00000100100001001000101001010110011;
                o_a2 <= 35'b00000011111110111111011111011000111;
                o_a3 <= 35'b00000011100000111000010111110111110;
                end
            7'h6f 	:	 begin 
                o_a1 <= 35'b00000100011000010110000110110010111;
                o_a2 <= 35'b00000011111111011100100111101001101;
                o_a3 <= 35'b00000011101000110000101001111001110;
                end
            7'h70 	:	 begin 
                o_a1 <= 35'b00000100001111100010001011010111100;
                o_a2 <= 35'b00000011111111110001010110111111101;
                o_a3 <= 35'b00000011110000111011000110101001000;
                end
            7'h71 	:	 begin 
                o_a1 <= 35'b00000100000110101100110111110000111;
                o_a2 <= 35'b00000011111111111101001110101100011;
                o_a3 <= 35'b00000011111001011000101010110110010;
                end
            7'h72 	:	 begin 
                o_a1 <= 35'b00000011111101110110001100111001101;
                o_a2 <= 35'b00000011111111111111101101011000001;
                o_a3 <= 35'b00000100000010001010011000010101110;
                end
            7'h73 	:	 begin 
                o_a1 <= 35'b00000011110100111110001011111111011;
                o_a2 <= 35'b00000011111111111000001110101111000;
                o_a3 <= 35'b00000100001011010001010110100010100;
                end
            7'h74 	:	 begin 
                o_a1 <= 35'b00000011101100000100110110101000100;
                o_a2 <= 35'b00000011111111100110001011001000111;
                o_a3 <= 35'b00000100010100101110110011000101011;
                end
            7'h75 	:	 begin 
                o_a1 <= 35'b00000011100011001010001110111100010;
                o_a2 <= 35'b00000011111111001000110111010000011;
                o_a3 <= 35'b00000100011110100100000010100010110;
                end
            7'h76 	:	 begin 
                o_a1 <= 35'b00000011011010001110010111101010111;
                o_a2 <= 35'b00000011111110011111100011100100010;
                o_a3 <= 35'b00000100101000110010100001001100011;
                end
            7'h77 	:	 begin 
                o_a1 <= 35'b00000011010001010001010100011000011;
                o_a2 <= 35'b00000011111101101001011011110101100;
                o_a3 <= 35'b00000100110011011011110011111100010;
                end
            7'h78 	:	 begin 
                o_a1 <= 35'b00000011001000010011001001101001100;
                o_a2 <= 35'b00000011111100100101100110011111110;
                o_a3 <= 35'b00000100111110100001101001010110110;
                end
            7'h79 	:	 begin 
                o_a1 <= 35'b00000010111111010011111101010010110;
                o_a2 <= 35'b00000011111011010011000011111011100;
                o_a3 <= 35'b00000101001010000101111010110110000;
                end
            7'h7a 	:	 begin 
                o_a1 <= 35'b00000010110110010011110110101010101;
                o_a2 <= 35'b00000011111001110000101101101001111;
                o_a3 <= 35'b00000101010110001010101110000001011;
                end
            7'h7b 	:	 begin 
                o_a1 <= 35'b00000010101101010010111110111111111;
                o_a2 <= 35'b00000011110111111101010101010110111;
                o_a3 <= 35'b00000101100010110010010110010010001;
                end
            7'h7c 	:	 begin 
                o_a1 <= 35'b00000010100100010001100001110100001;
                o_a2 <= 35'b00000011110101110111100011110010001;
                o_a3 <= 35'b00000101101111111111010110100111011;
                end
            7'h7d 	:	 begin 
                o_a1 <= 35'b00000010011011001111101101011011111;
                o_a2 <= 35'b00000011110011011101110111011011100;
                o_a3 <= 35'b00000101111101110100100011101101000;
                end
            7'h7e 	:	 begin 
                o_a1 <= 35'b00000010010010001101110011100110001;
                o_a2 <= 35'b00000011110000101110100011000000010;
                o_a3 <= 35'b00000110001100010101000110011001001;
                end
            7'h7f 	:	 begin 
                o_a1 <= 35'b00000010001001001100001010001011110;
                o_a2 <= 35'b00000011101101100111101011101000010;
                o_a3 <= 35'b00000110011011100100011110100011011;
                end
        endcase
	end								
endmodule
