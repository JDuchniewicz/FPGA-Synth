// Top level module for Synthesizer project

// buttons should be wired here, as well as inputs from Device Tree and outputs to SDRAM
// This is synthesized as Avalon MM Slave - hence one input and one output signal (readdata and writedata)
module synthesizer_top(input clk,
							  input reset,
							  input avs_s0_write,
							  input avs_s0_read, //read is not that important for now
							  input [31:0] avs_s0_writedata, // control signals for writing and reading have to be added
							  output [31:0] avs_s0_readdata);
							  
							  // IF I want to add a debug flash of LED or anything, a counduit is required to drive the signal out of the FPGA
	

	reg [15:0]	r_oneshot_data;
	//reg [15:0] r_tmp_signal;
	wire[23:0] w_osignal; // this will be later routed to SDRAM	
	wire[3:0] w_oidx;
	wire w_clk_slow;
	
	clk_slow slow(.clk(clk), .rst(reset), .clk_out(w_clk_slow));
	
	bank_manager bm(.clk(clk), .clk_slow(w_clk_slow), .reset(reset), .i_data(r_oneshot_data), .o_signal(w_osignal), .o_idx(w_oidx));
	// This module is responsible for pinging bm to process a new sound and each cycle collect processed signal from it
	// global modules like noise adders may be present here and wired to bm
	// bm manages pipelines which perform all steps of signal processing and output ready signal via bm
	
	// stages of pipeline:
	// generation -> pipeline
	// noise adder -> global (not vital right now)
	// filter -> pipeline
	// effects -> both pipeline and global? (not vital right now)
	// adsr -> pipeline
	// aftereffects -> to be considered
	
	initial r_oneshot_data = 16'b0;
	
	assign avs_s0_readdata = { w_oidx, {8{1'b0}}, w_osignal }; // after SDRAM impl, it will be sth other?

	always @ (posedge clk) begin // this will trigger new signal to bm just once
		if (avs_s0_write) begin
			r_oneshot_data <= avs_s0_writedata[15:0];
		end else  begin
			// keep the input value to BM 
			r_oneshot_data <= 16'b0;
		end
	end
	
	
	// inputs from the board should be wired here,
	// SDRAM controller IP is required here
	// 100MHz clock for synth, 400MHz clock for sdram and 96kHz for DAC 
	// Maybe collect out signals from synth in batches and batch-write them to SDRAM
	// give access to this memory on Linux? to see in real time how it is filled with values? (not DMA)
					 
					 
	// STEPS to take:
	// wire debug pin to act as clk
	// add this module to GHRD and build an image
	// create entry in Device tree and flash it on FPGA
	// write to this module and step it in hardware
	// wire output to Linux and print it (debug purposes)
	
	// for now just print current signal + index and perform manual stepping through the system
	// SUDDEN IDEA - if I want to get the proper value from all banks (not lose any samples) -> divide the bank clocks by N (number of banks !!!) - TEST IT !!!!!
	
	// GPIO's may be written directly from this module, no need to wire them through QSys
endmodule
