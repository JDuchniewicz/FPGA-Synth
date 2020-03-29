// State variable filter based on Andrew Simper's SVF whitepaper https://cytomic.com/files/dsp/SvfLinearTrapOptimised2.pdf

// this filter is hardwired to being a lowpass filter only (for now)

module state_variable_filter_iir(input clk,
											input rst,
											input[6:0] i_midi,
											input[15:0] i_data,
											output reg[15:0] o_filtered
											);
											
											// IT is crucial that I check how to synchronise this module with the rest, for now either producer makes a buffer of values?, or this module, filter signals only when it has finished, or just look how many cycles of latency there are, -> probably not a good idea

// module to calculate cutoff based on midi note
// reset when note changes, flush current states
	localparam IDLE = 2'b00, CALC = 2'b01, RDY = 2'b10;
	
	reg[15:0] v1, v2, v3, ic1eq, ic2eq,
				 g, k, a1, a2, a3, m; 			// parameters for filter calculation
	reg[1:0] init_st, v_st, res_st;
	// init_rdy when all ops for init done
	// v_rdy when all v's calculated and added
	// res_rdy when all results are done and o_filtered contains valid output
	
	initial begin
		v1 = 0;
		v2 = 0;
		v3 = 0;
		ic1eq = 0;
		ic2eq = 0;
		
		// find g based on midi to cutoff -> sample rate LUT
		g = 1'b1; // TEMP
		k = 2'b10; // 1/q -> q == 0.5
		a1 = 0;
		a2 = 0;
		a3 = 0;
		m = 0;
		
		init_st = IDLE;
		v_st = IDLE;
		res_st = IDLE;
	end 
	/* 1. Initial calc -> coefficients
			aa) g -> LUT
			a) m = 1+g*(g+k)
			b) a1 = 1/m
			c) a2 = g*a1
			d) a3 = g*a2 = g*g*a1
		2. Each update
		+	v3 = v0 - ic2eq
		+	v1 = a1 * ic1eq + a2 * v3
		+	v2 = ic2eq + a2 * ic1eq + a3 * v3 // calc sim 4 multipliers
		\	ic1eq = 2*v1 - ic1eq // shift
		\	ic2eq = 2*v2 - ic2eq // shift simult
			// careful about operations order now, be sure to check which finish first
	*/
	// calculate coefficients from LUT
	// first test in MATLAB if coeff are proper
	
	
	always @ (posedge clk) begin
		if (rst) begin
			ic1eq <= 0;
			ic2eq <= 0;
			v1 <= 0;
			v2 <= 0;
			v3 <= 0;
			g <= 0;
			k <= 0;
			a1 <= 0;
			a2 <= 0;
			a3 <= 0;
			m <= 0;
			// reset all temp, output
			o_filtered <= 16'b0;
		end
	if (init_st == IDLE || init_st == CALC) begin // only entered until initialized
	
	
	end else if (v_st == IDLE) begin // calculation not yet started, what about when it is in progress and we still end up in this  -> states are needed becasue of that
	
	end else if (res_st == IDLE) begin
	
	end else begin // yeah? what should be here?
	
	end
		
		
		
	end

endmodule
