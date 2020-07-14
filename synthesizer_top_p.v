// Top level module for Synthesizer project

module synthesizer_top_p(input clk,
							  input reset,
							  input avs_s0_write,
							  input avs_s0_read, //read is not that important for now
							  input [31:0] avs_s0_writedata, // control signals for writing and reading have to be added
							  output [31:0] avs_s0_readdata,
							  output o_dac_out,
							  output reg [31:0] aso_ss0_data,
							  output reg aso_ss0_valid);
							  //output [23:0] current_out); //debug value
	
	parameter NSAMPLES = 100;
	
	// a ring buffer sample storage
	reg signed[23:0] mixed_samples[NSAMPLES-1:0];
	reg [15:0]	r_oneshot_data; // incoming signal
	reg clk_en;
	reg ss0_valid_fast_r1, ss0_valid_fast_r2, ss0_valid_fast_r3;
	integer read;
	integer write;
	
	// DAC connections
	reg signed[23:0] r_dac_in;
	
	wire signed[23:0] w_osignal;
	wire w_rdy;
	wire signed[23:0] w_mixed_sample;
	
	wire w_clk_96k;
	
	//DEBUG
	//assign current_out = w_osignal;
	
	clk_slow #(96_000) clk_96k(.clk(clk), .rst(reset), .clk_out(w_clk_96k)); // 96kHz
	
	bank_manager_p bm(.clk(clk), .clk_en(clk_en), .reset(reset), .i_data(r_oneshot_data), .o_signal(w_osignal));
	// This module is responsible for pinging bm to process a new sound and each cycle collect processed signal from it
	// global modules like noise adders may be present here and wired to bm
	// bm manages pipelines which perform all steps of signal processing and output ready signal via bm
	
	mixer mix(.clk(clk), .clk_en(clk_en), .rst(reset), .i_data(w_osignal >>> 4), .o_mixed(w_mixed_sample), .o_rdy(w_rdy)); // if ADSR is to be implemented in Verilog, then it should be before mixing it
	dac_dsm2_top dac(.din(r_dac_in), .dout(o_dac_out), .clk(w_clk_96k), .n_rst(~reset)); // DAC MASH from WZab
	
	// stages of pipeline:
	// generation -> pipeline
	// noise adder -> global (not vital right now)
	// filter -> pipeline
	// effects -> both pipeline and global? (not vital right now)
	// adsr -> pipeline
	// aftereffects -> to be considered
	
	initial begin
		r_oneshot_data = 16'b0;
		read = 0; // 1 element difference
		write = 1;
		clk_en = 1'b1;
		r_dac_in = 24'b0;
		aso_ss0_data = 32'b0;
		ss0_valid_fast_r1 = 1'b0;
		ss0_valid_fast_r2 = 1'b0;
		ss0_valid_fast_r3 = 1'b0;
	end
	
	// generator and system clock
	always @ (posedge clk or posedge reset) begin // this will trigger new signal to bm just once
		if (reset) begin
			r_oneshot_data <= 16'b0;
			write <= 1;
			clk_en <= 1'b0;
			ss0_valid_fast_r1 <= 1'b0;
			ss0_valid_fast_r2 <= 1'b0;
			ss0_valid_fast_r3 <= 1'b0;
		end else begin 
	// this logic has to be turned off for simulating -> too slow clock for sampling
			if (read == write) begin // written enough samples, wait until free slot available
				clk_en <= 1'b0;
			end else begin 
				if (w_rdy) begin // if got a full 10 batch
					mixed_samples[write] <= w_mixed_sample;
					
					if (write == NSAMPLES - 1) begin
						write <= 0;
					end else begin
						write <= write + 1;
					end
				end 
				clk_en <= 1'b1;
			end
			
			// catching the valid signal and signalizing it to the mSGDMA
			ss0_valid_fast_r1 <= w_clk_96k;
			ss0_valid_fast_r2 <= ss0_valid_fast_r1;
			ss0_valid_fast_r3 <= ss0_valid_fast_r2;
			
			if (ss0_valid_fast_r3 == 1'b0 && ss0_valid_fast_r2 == 1'b1) begin // this will find a rising edge of slow clock(with a two clock delay)
				aso_ss0_valid <= 1'b1;
			end else begin
				aso_ss0_valid <= 1'b0;
			end
			// Avalon communication logic
			if (avs_s0_write) begin
				r_oneshot_data <= avs_s0_writedata[15:0];
			end else  begin
				// keep the input value to BM 
				r_oneshot_data <= 16'b0;
			end
		end
	end

	// clock for DAC sampling and outputing samples to mSGDMA(read==write will not happen?)
	always @(posedge w_clk_96k or posedge reset) begin
		if (reset) begin
			read <= 0;
			r_dac_in <= 24'b0;
			aso_ss0_data <= 32'b0;
		end else
		if (read == NSAMPLES - 1) begin
			r_dac_in <= mixed_samples[NSAMPLES - 1];
			aso_ss0_data <= mixed_samples[NSAMPLES - 1]; // for now write mixed value (can write them 1by1 though)
			read <= 0;
		end else begin
			r_dac_in <= mixed_samples[read];
			aso_ss0_data <= mixed_samples[read];
			read <= read + 1;
		end
	end	
					 
endmodule
