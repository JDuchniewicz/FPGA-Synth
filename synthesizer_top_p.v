// Top level module for Synthesizer project

module synthesizer_top_p(input clk,
							  input reset,
							  input avs_s0_write,
							  input avs_s0_read, //read is not that important for now
							  input [31:0] avs_s0_writedata, // control signals for writing and reading have to be added
							  output [31:0] avs_s0_readdata,
							  output o_dac_out,
							  output reg [31:0] aso_s0_data);
	
	parameter NSAMPLES = 100;
	
	// a ring buffer sample storage
	reg [23:0] mixed_samples[NSAMPLES];
	reg [15:0]	r_oneshot_data; // incoming signal
	reg clk_en;
	integer read;
	integer write;
	
	// DAC connections
	reg signed[23:0] r_dac_in;
	
	wire[23:0] w_osignal;
	wire signed[23:0] w_mixed_sample;
	
	wire w_clk_96k;
	
	clk_slow #(96_000) clk_96k(.clk(clk), .rst(reset), .clk_out(w_clk_96k)); // 96kHz
	
	bank_manager_p bm(.clk(clk), .clk_en(clk_en), .reset(reset), .i_data(r_oneshot_data), .o_signal(w_osignal));
	// This module is responsible for pinging bm to process a new sound and each cycle collect processed signal from it
	// global modules like noise adders may be present here and wired to bm
	// bm manages pipelines which perform all steps of signal processing and output ready signal via bm
	
	mixer mix(.clk(clk), .clk_en(clk_en), .rst(reset), .i_data(w_osignal), .o_mixed(w_mixed_sample)); // if ADSR is to be implemented in Verilog, then it should be before mixing it
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
	end
	
	// generator and system clock
	always @ (posedge clk or posedge reset) begin // this will trigger new signal to bm just once
		if (reset) begin
			r_oneshot_data <= 16'b0;
			write <= 1;
			clk_en <= 1'b0;
		end else begin 		
			// temporary implementation before pipelining is finished
			if (read == write) begin // written enough samples, wait until free slot available
				clk_en <= 1'b0;
			end else if (write == NSAMPLES) begin
				mixed_samples[write] <= w_mixed_sample;
				write <= 0;
				clk_en <= 1'b1;
			end else begin
				mixed_samples[write] <= w_mixed_sample;
				write <= write + 1;
				clk_en <= 1'b1;
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
	
	// clock for DAC sampling (read==write will not happen?)
	always @(posedge clk_96k or posedge reset) begin
		if (reset) begin
			read <= 0;
			r_dac_in <= 24'b0;
		end else
		if (read == NSAMPLES) begin // FINISH this concept and then try compiling everything, get the signal out on the GPIO, check what is being output
			r_dac_in <= mixed_samples[NSAMPLES];
			aso_s0_data <= mixed_samples[NSAMPLES]; // for now write mixed value (can write them 1by1 though)
			read <= 0;
		end else begin
			r_dac_in <= mixed_samples[read];
			aso_s0_data <= mixed_samples[read];
			read <= read + 1;
		end
	end
					 
endmodule
