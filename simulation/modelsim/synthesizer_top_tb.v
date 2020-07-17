// testbench for the top module of synthesizer 

`timescale 10ns/1ns // 1 clock cycle of 100MHz clock is 10ns

module synthesizer_top_tb;
	// in
	reg clk;
	reg reset;
	reg write;
	reg read;
	reg [15:0] r_data;
	
	// out
	wire [15:0] w_signal;
	wire [31:0] avalon_write_data, avalon_read_data, aso_read_data;
	wire w_aso_valid;
	wire dac_out;
	
	// simulate Avalon write issuing, trigger write for one cycle
	synthesizer_top_p synth(.clk(clk), 
								.reset(reset),
							   .avs_s0_write(write),
							   .avs_s0_read(read),
							   .avs_s0_writedata(avalon_write_data),
							   .avs_s0_readdata(avalon_read_data),
								.o_dac_out(dac_out),
								.aso_ss0_data(aso_read_data),
								.aso_ss0_valid(w_aso_valid),
								.current_out(w_signal));
								
	assign avalon_write_data = { {16{1'b0}}, r_data };

	initial begin
		clk = 0;
		reset = 0;
		write = 0;
		read = 0;
		r_data = 0;
		
		#20 // stabilization wait (maybe shorter)
	@ (negedge clk); //use negedge here because at posedge we make changes in module
	/*
	// TESTS FOR SINGLE NOTES STABILITY

	$display("[%t] Start single note - G6", $time);
	#1
	r_data = 16'b1_1011011_0000_0000;
	write = 1'b1;
	#1
	write = 1'b0;
	#1000000
	r_data = 16'b0_1011011_0000_0000;
	write = 1'b1;
	#1
	write = 1'b0;
	*/
	/*
	// TESTS FOR MULTIPLE SIMULTANEOUS NOTES STABILITY

	$display("[%t] Start single note - G6", $time);
	#1
	r_data = 16'b1_1011011_0000_0000;
	write = 1'b1;
	#1
	write = 1'b0;
	#1
	$display("[%t] Start single note - C4", $time);
	#20
	r_data = 16'b1_0111100_0000_0000;
	write = 1'b1;
	#1
	write = 1'b0;

	#1000000
	r_data = 16'b0_0111100_0000_0000;
	write = 1'b1;
	#1
	write = 1'b0;
	#1
	r_data = 16'b0_1011011_0000_0000;
	write = 1'b1;
	#1
	write = 1'b0;
	#1000

	*/
	/*
	// TESTS FOR FIFO BEHAVIOUR
	$display("[%t] Start single note - G6", $time);
	#1
	r_data = 16'b1_1011011_0000_0000;
	write = 1'b1;
	#1
	write = 1'b0;
	#1
	#30000
	r_data = 16'b0_1011011_0000_0000;
	write = 1'b1;
	#1
	write = 1'b0;
	#1000
	
	$display("[%t] Start single note - C4", $time);
	#20
	r_data = 16'b1_0111100_0000_0000;
	write = 1'b1;
	#1
	write = 1'b0;
	#30000
	r_data = 16'b0_0111100_0000_0000;
	write = 1'b1;
	#1
	write = 1'b0;
	#1000
	// TESTS FOR LONG TIME PLAYING 96 kHz sampling
	$display("[%t] Start single note - G6", $time);
	#1
	r_data = 16'b1_1011011_0000_0000;
	write = 1'b1;
	#1
	write = 1'b0;
	#1
	#1_000_000_0 // 0.01 second
	r_data = 16'b0_1011011_0000_0000;
	write = 1'b1;
	#1
	write = 1'b0;
	#1000
	*/
	$display("[%t] Start single note - D3", $time);
	#1
	r_data = 16'b1_0110010_0000_0000;
	write = 1'b1;
	#1
	write = 1'b0;
	#1
	#3000000
	r_data = 16'b0_0110010_0000_0000;
	write = 1'b1;
	#1
	write = 1'b0;
	#1000
	
	/*	
	$display("[%t] Start single note - F2", $time);
	#10
	r_data = 16'b1_0101001_0000_0000;
	write = 1'b1;
	#10
	write = 1'b0;
	#10000
	r_data = 16'b0_0101001_0000_0000;
	write = 1'b1;
	#10
	write = 1'b0;
	*/
	/*
	// HIGHER FREQUENCIES
		$display("[%t] Start single note - F2", $time);
	#10
	r_data = 16'b1_0101001_0000_0000;
	write = 1'b1;
	#10
	write = 1'b0;
	#10000
	r_data = 16'b0_0101001_0000_0000;
	write = 1'b1;
	#10
	write = 1'b0;
	*/
	/*
	$display("[%t] Start single note - F2", $time);
	#10
	r_data = 16'b1_0101001_0000_0000;
	write = 1'b1;
	#10
	write = 1'b0;
	#10000
	r_data = 16'b0_0101001_0000_0000;
	write = 1'b1;
	#10
	write = 1'b0; // TODO: Finish once DMA part is finalized, test thoroughly and fix the generating issues - wrong frequency offsets
	*/
	/* TESTS FOR FUNCTIONAL COMPLETENESS
	$display("[%t] Start single note - A4", $time);
	#10
	r_data = 16'b1_1000101_0000_0000; // START A4
	write = 1'b1;
	#10
	write = 1'b0;
	#10000
	
	#10
	r_data = 16'b0_1000101_0000_0000; //STOP A4
	write = 1'b1;
	#10
	write = 1'b0;
	
	#300
	r_data = 16'b1_1000101_0000_0000; // START A4	
	write = 1'b1;
	#10
	write = 1'b0;
	
	#1200
	r_data = 16'b0_1001001_0000_0000; //STOP D5 - not playing
	write = 1'b1;
	#10
	write = 1'b0;
	
	#300
	r_data = 16'b0_1000101_0000_1111; //STOP A4 with some irrelevant velocity
	write = 1'b1;
	#10
	write = 1'b0;
	
	
	#300 								// total 360ns
	
	$display("[%t] Start 5 notes", $time);  // delays do not need to take 20 right now
	r_data = 16'b1_1000101_0000_0000; // START A4
	write = 1'b1;
	#10
	write = 1'b0;
	
	#10
	r_data = 16'b1_0101000_0000_0000; // START E2
	write = 1'b1;
	#10
	write = 1'b0;

	#10
	r_data = 16'b1_0111100_0000_0000; // START C4
	write = 1'b1;
	#10
	write = 1'b0;
	
	#10
	r_data = 16'b1_1001101_0000_0000; // START F5
	write = 1'b1;
	#10
	write = 1'b0;
	
	#10
	r_data = 16'b1_1011111_0000_0000; // START B6
	write = 1'b1;
	#10
	write = 1'b0;
	#3600								// total 410ns
	
	$display("[%t] Start 10 notes", $time);
	r_data = 16'b1_0011010_0000_0000; // START D1
	write = 1'b1;
	#10
	write = 1'b0;
	
	#20
	r_data = 16'b1_0011100_0000_0000; // START E1
	write = 1'b1;
	#10
	write = 1'b0;
	
	#20
	r_data = 16'b1_0011101_0000_0000; // START F1
	write = 1'b1;
	#10
	write = 1'b0;
	
	#20
	r_data = 16'b1_0011110_0000_0000; // START G1
	write = 1'b1;
	#10
	write = 1'b0;
	
	#20
	r_data = 16'b1_0100000_0000_0000; // START A1
	write = 1'b1;
	#10
	write = 1'b0;
	
	#3600								// total 400ns
	
	$display("[%t] Add additional notes", $time);
	r_data = 16'b1_0011111_0000_0000; // START H1
	write = 1'b1;
	#10
	write = 1'b0;
	#600								// total 60ns
	
	$display("[%t] Start the same note one more time", $time);
	r_data = 16'b1_1000101_0000_0000; // START A4
	write = 1'b1;
	#10
	write = 1'b0;
	#600								// total 70ns
	
	$display("[%t] Turn off one, add one", $time);
	r_data = 16'b0_1000101_0000_0000; //STOP A4
	write = 1'b1;
	#10
	write = 1'b0;
	
	#20
	r_data = 16'b1_1100010_0000_0000; // START D7
	write = 1'b1;
	#10
	write = 1'b0;
	#3600 								// total 370ns
	
	$display("[%t] Turn off two, add one", $time);
	r_data = 16'b0_0011010_0000_0000; // STOP D1
	write = 1'b1;
	#10
	write = 1'b0;
	
	#20
	r_data = 16'b0_0011100_0000_0000; // STOP E1
	write = 1'b1;
	#10
	write = 1'b0;
	
	#20
	r_data = 16'b1_1000001_0000_0000; // START E4
	write = 1'b1;
	#10
	write = 1'b0;
	#3600 								// total 380ns
	$display("[%t] Turn off all", $time);
	r_data = 16'b0_1111111_0000_0000; // STOP_ALL
	write = 1'b1;
	#10
	write = 1'b0;
	#1500								// total 150ns
	*/
	$display("[%t] Done", $time);
	$finish; // not testing velocity for now
	end
	
	always #1 clk = ~clk; // every 1ns
endmodule
