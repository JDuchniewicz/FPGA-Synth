// Top level module for Synthesizer project

module synthesizer_top_p(input clk,
						 input reset,
						 input avs_s0_write,
						 input avs_s0_read,
						 input [31:0] avs_s0_writedata,
						 output [31:0] avs_s0_readdata,
						 output o_dac_out,
						 output reg [31:0] aso_ss0_data,
						 output reg aso_ss0_valid);
	
	reg [15:0]	r_oneshot_data;
	reg clk_en;
	wire signed[23:0] w_fifo_out;
	reg signed[23:0] r_fifo_in;
	reg r_wr_req, r_rd_req;
	wire w_full, w_empty;

	// DAC connections
	reg signed[23:0] r_dac_in;
	
	wire signed[23:0] w_osignal;
	wire w_rdy;
	wire signed[23:0] w_mixed_sample;
	
	wire w_clk_96k_en;
	
	slow_clk_en #(100_000_000, 96_000) clk_96_en(.clk(clk),
																.rst(reset),
																.clk_en(w_clk_96k_en));
	
	bank_manager_p bm(.clk(clk), 
							.clk_en(clk_en),
							.reset(reset), 
							.i_data(r_oneshot_data), 
							.o_signal(w_osignal));
		
	fifo mixed_samples_fifo(.data(r_fifo_in), 
									.rdclk(clk), 
									.rdreq(r_rd_req), 
									.wrclk(clk), 
									.wrreq(r_wr_req), 
									.q(w_fifo_out), 
									.rdempty(w_empty), 
									.wrfull(w_full));
	
	mixer mix(.clk(clk), 
				 .clk_en(clk_en), 
				 .rst(reset), 
				 .i_data(w_osignal >>> 1), 
				 .o_mixed(w_mixed_sample), 
				 .o_rdy(w_rdy));
				 
	dac_dsm2_top dac(.din(r_dac_in),
						  .dout(o_dac_out), 
						  .clk(clk), 
						  .n_rst(~reset));
	initial begin
		r_oneshot_data = 16'b0;
		clk_en = 1'b1;
		r_fifo_in = 24'b0;
		r_wr_req = 1'b0;
		r_rd_req = 1'b0;
		r_dac_in = 24'b0;
		aso_ss0_data = 32'b0;
		aso_ss0_valid = 1'b0;
	end
	
	// generator and system clock
	always @ (posedge clk or posedge reset) begin
		if (reset) begin
			r_oneshot_data <= 16'b0;
			r_fifo_in <= 24'b0;
			r_wr_req <= 1'b0;
			r_rd_req <= 1'b0;
			clk_en <= 1'b0;
			aso_ss0_data <= 32'b0;
			aso_ss0_valid <= 1'b0;
		end else begin 
		// written enough samples, wait until free slot available
			if (w_full) begin
				clk_en <= 1'b0;
				r_wr_req <= 1'b0;
			end else begin 
				// if got a full 10 batch
				if (w_rdy && !r_wr_req) begin
					r_fifo_in <= w_mixed_sample;
					r_wr_req <= 1'b1;
				// signal wr_req just for a one cycle
				end else begin 
					r_wr_req <= 1'b0;
				end
				clk_en <= 1'b1;
			end
			
			// reading logic -> passing it 
			// clock_en for DAC sampling and outputing samples to mSGDMA
			if (w_clk_96k_en) begin
				if (!w_empty) begin
					r_rd_req <= 1'b1;
					aso_ss0_valid <= 1'b1;
					r_dac_in <= w_fifo_out;	
					aso_ss0_data <= {{8{1'b0}}, w_fifo_out[7:0], w_fifo_out[15:8], w_fifo_out[23:16]};
				end
			end else begin
				r_rd_req <= 1'b0;
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
					 
endmodule
