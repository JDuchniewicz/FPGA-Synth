// Top level module for Synthesizer project

// buttons should be wired here, as well as inputs from Device Tree and outputs to SDRAM
// This is synthesized as Avalon MM Slave - hence one input and one output signal (readdata and writedata)
module synthesizer_top(input clk,
							  input reset,
							  input avs_s0_write,
							  input avs_s0_read, //read is not that important for now
							  input [31:0] avs_s0_writedata, // control signals for writing and reading have to be added
							  output [31:0] avs_s0_readdata,
							  output o_dac_out);
							  
							  // IF I want to add a debug flash of LED or anything, a counduit is required to drive the signal out of the FPGA
	

	reg [15:0]	r_oneshot_data;
	
	// a ring buffer sample storage
	reg [23:0] mixed_samples[100];
	integer read;
	integer write;
	reg clk_en; // runs pipeline only when the buffer is not full, for now  | THIS IMPLEMENTATION WILL BE FULLY VALID ONCE STREAMLINING IS DONE
	wire signed[23:0] w_mixed_sample;
	
	// DAC connections
	reg signed[23:0] r_dac_in;
	
	wire[23:0] w_osignal; // this will be later routed to SDRAM	- or both analogue and DMA
	wire[3:0] w_oidx;
	wire w_clk_slow;
	wire w_clk_96k;
	
	clk_slow #(10_000_000) slow (.clk(clk), .rst(reset), .clk_out(w_clk_slow)); // 10MHz
	clk_slow #(96_000) clk_96k(.clk(clk), .rst(reset), .clk_out(w_clk_96k)); // 96kHz
	
	bank_manager bm(.clk(clk), .clk_slow(w_clk_slow), .clk_en(clk_en), .reset(reset), .i_data(r_oneshot_data), .o_signal(w_osignal), .o_idx(w_oidx));
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
	
	assign avs_s0_readdata = { w_oidx, {4{1'b0}}, w_osignal }; // after SDRAM impl, it will be sth other?
	
	//integer idx = 0;

	// generator and system clock
	always @ (posedge clk or posedge reset) begin // this will trigger new signal to bm just once
	
		/*
		if (idx == 1_000_000_000) begin	// debug signal! just input single midi
			r_oneshot_data <= 16'b1_1000101_0000_0000;
		end else if (idx == 1_000_000_001) begin
			r_oneshot_data <= 16'b0;
		end //else if (idx == 3_000_000_000) begin

			r_oneshot_data <= 16'b1_0101000_0000_0000;
		end else if (idx == 3_000_000_001) begin
			r_oneshot_data <= 16'b0;
		end else if (idx == 3_500_000_000) begin
			r_oneshot_data <= 16'b1_1000101_0000_0000;
		end else if (idx == 3_500_000_001) begin
			r_oneshot_data <= 16'b0;
		end else if (idx == 4_000_000_000) begin
			r_oneshot_data <= 16'b0_1000101_0000_0000;
		end else if (idx == 4_000_000_001) begin
			r_oneshot_data <= 16'b0;
		end else if (idx == 5_000_000_000) begin
			r_oneshot_data <= 16'b0_1000101_0000_0000;
		end else if (idx == 5_000_000_001) begin
			r_oneshot_data <= 16'b0;
		end
		*/
		//idx <= idx + 1;
		
		if (reset) begin
			r_oneshot_data <= 16'b0;
			write <= 1;
			clk_en <= 1'b0;
		end else begin 		
			// temporary implementation before pipelining is finished
			if (read == write) begin // written enough samples, wait until free slot available
				clk_en <= 1'b0;
			end else if (write == 100) begin
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
		if (read == 100) begin // FINISH this concept and then try compiling everything, get the signal out on the GPIO, check what is being output
			r_dac_in <= mixed_samples[100];
			read <= 0;
		end else begin
			r_dac_in <= mixed_samples[read];
			read <= read + 1;
		end
	end
					 
					 
	// STEPS to take:
	// wire debug pin to act as clk - can be connected to slow_clk ( probably best)
	// add this module to GHRD and build an image - DONE
	// create entry in Device tree and flash it on FPGA
	// write to this module and step it in hardware
	// wire output to Linux and print it (debug purposes)
	
	// SUDDEN IDEA - if I want to get the proper value from all banks (not lose any samples) -> divide the bank clocks by N (number of banks !!!) - TEST IT !!!!!
	
	// GPIO's may be written directly from this module, no need to wire them through QSys?????????????????????????????
endmodule
