// Testbench for bank_manager module

`timescale 1ns/1ps

module bank_manager_tb;
	// in
	reg clk;
	reg [15:0] r_data;
	
	// out
	wire [15:0] w_signal;
	
	bank_manager bm(.clk(clk), 
						 .i_data(r_data), 
						 .o_signal(w_signal));

	// 7.04.20 need to check the tests for corectness, try to glue together inputs from FPGA and get some input, outputs?
	initial begin
		clk = 0;
		r_data = 0;
		
		#10 // stabilization wait (maybe shorter)
	@ (negedge clk); //use negedge here because at posedge we make changes in module
	
	$display("[%t] Start single note - A4", $time);
	r_data = 16'b1_1000101_0000_0000; // START A4
	#2
	r_data = 16'b0; // zero out the command, prevents turning on new banks each cycle
	#30
	r_data = 16'b0_1000101_0000_0000; //STOP A4
	#10 // observe zero output
	r_data = 16'b1_1000101_0000_0000; // START A4
	#2
	r_data = 16'b0;
	#30 
	r_data = 16'b0_1001001_0000_0000; //STOP D5 - not playing
	#10
	r_data = 16'b0_1000101_0000_1111; //STOP A4 with some irrelevant velocity
	#10								// total 360ns
	
	$display("[%t] Start 5 notes", $time); 
	r_data = 16'b1_1000101_0000_0000; // START A4
	#4
	r_data = 16'b1_0101000_0000_0000; // START E2
	#4
	r_data = 16'b1_0111100_0000_0000; // START C4
	#4
	r_data = 16'b1_1001101_0000_0000; // START F5
	#4
	r_data = 16'b1_1011111_0000_0000; // START B6
	#4
	r_data = 16'b0;
	#50								// total 410ns
	
	$display("[%t] Start 10 notes", $time);
	r_data = 16'b1_0011010_0000_0000; // START D1
	#4
	r_data = 16'b1_0011100_0000_0000; // START E1
	#4
	r_data = 16'b1_0011101_0000_0000; // START F1
	#4
	r_data = 16'b1_0011110_0000_0000; // START G1
	#4
	r_data = 16'b1_0100000_0000_0000; // START A1
	#4
	r_data = 16'b0;
	#360								// total 410ns
	
	$display("[%t] Add additional notes", $time);
	r_data = 16'b1_0011111_0000_0000; // START H1
	#2
	r_data = 16'b0;
	#20								// total 70ns
	
	$display("[%t] Start the same note one more time", $time);
	r_data = 16'b1_1000101_0000_0000; // START A4
	#2
	r_data = 16'b0;
	#20								// total 70ns
	
	$display("[%t] Turn off one, add one", $time);
	r_data = 16'b0_1000101_0000_0000; //STOP A4
	#4
	r_data = 16'b1_1100010_0000_0000; // START D7
	#50 								// total 370ns
	
	$display("[%t] Turn off two, add one", $time);
	r_data = 16'b0_0011010_0000_0000; // STOP D1
	#4
	r_data = 16'b0_0011100_0000_0000; // STOP E1
	#4
	r_data = 16'b1_1000001_0000_0000; // START E4
	#2
	r_data = 16'b0;
	#50 								// total 380ns
	$display("[%t] Turn off all", $time);
	r_data = 16'b0_1111111_0000_0000; // STOP_ALL
	#30							// total 150ns
	$display("[%t] Done", $time);
	$finish; // not testing velocity for now
	end
	
	always #1 clk = ~clk; // every 5ns ( this is not our model clock 100MHz, it would need 1ns)
endmodule
