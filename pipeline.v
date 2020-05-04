/*
	Pipeline module, responsible for managing synchronisation in terms of one signal processing pipeline
	Comprises of phase_bank, LUT's, Filters, ADSR?, Effects?
*/

// it would be wise to create some kind of more sophisticated looping system (for example queue?), need to be considered
module pipeline(input clk,
					 input rst,
					 input[15:0] i_data,
					 output [13:0] o_lut_input,
					 input signed [15:0] i_lut_output, // passthrough for LUT, probably can be used for other types of LUT
					 output reg[1:0] o_state,
					 output[15:0] o_signal
					);
	localparam IDLE = 2'b00, BSY = 2'b01, RDY = 2'b10;
	
	integer v_delay;
	
	reg r_filt_ena;
	
	wire[15:0] w_phase;
	wire signed[15:0] w_sine;
		
	wire[6:0]  w_midi;
	wire[7:0]  w_vel;
	
	assign w_midi = i_data[14:8];
	assign w_vel = i_data[7:0];
	
	phase_bank pb(.clk(clk), .i_midi(w_midi), .o_phase(w_phase)); // add reset control to these modules
	quarter_sine qsine(.clk(clk), .i_phase(w_phase), .o_lut_input(o_lut_input), .i_lut_output(i_lut_output), .o_val(w_sine));
	state_variable_filter_iir SVF(.clk(clk), .rst(rst), .ena(r_filt_ena), .i_midi(w_midi), .i_data(w_sine), .o_filtered(o_signal)); // when adding new modules, o_signal is moved to the last
							
							
	initial begin
		o_state = IDLE;
		v_delay = 0;
		r_filt_ena = 0;
	
	end

	always @(posedge clk or posedge rst) begin
		if (rst) begin
			o_state <= IDLE;
			v_delay <= 0;
			r_filt_ena <= 0;
		end
		
		// state machine logic
		else if (i_data !== 16'b0) begin
			if (o_state == IDLE) begin
				o_state <= BSY; // signal is now being generated
				v_delay <= v_delay + 1;
			end else if (o_state == BSY) begin
				if (v_delay > 6) // next cycle is ready (do not know if filter should not loop at least once?)
					o_state <= RDY;
				else if (v_delay > 2) // 3 cycles for sine wave (may need to be adjusted for different signals
					r_filt_ena <= 1; // signal is already ready

				v_delay <= v_delay + 1;
			end else if (o_state == RDY) begin
				// should this signal be accumulated somewhere? until it is read? (this is yet to be decided, on seeing the output) for now just ignore
				v_delay <= 0;
			end
		end
		else begin
			o_state <= IDLE;
		end
	end
					
endmodule
