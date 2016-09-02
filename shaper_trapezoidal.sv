//-----------------------------------------------------------------------------
// Title       : shaper_trapezoidal
//-----------------------------------------------------------------------------
// File        : shaper_trapezoidal.sv
// Company     : INP SB RAS
// Created     : 19/03/2014
// Created by  : Alina Ivanova
//-----------------------------------------------------------------------------
// Description : trapezoidal pulse shaper
//-----------------------------------------------------------------------------
// Revision    : 1.1
//-----------------------------------------------------------------------------
// Copyright (c) 2014 INP SB RAS
// This work may not be copied, modified, re-published, uploaded, executed, or
// distributed in any way, in any medium, whether in whole or in part, without
// prior written permission from INP SB RAS.
//-----------------------------------------------------------------------------
// dkl(n) = v(n)   - v(n-k) - v(n-l) + v(n-k-l)
//   p(n) = p(n-1) + dkl(n), n<=0
//   r(n) = p(n)   + M*dkl(n)
//   q(n) = r(n)   + M2*dkl(n)
//   s(n) = s(n-1) + q(n),   n<=0
//   M    = 1/(exp(Tclk/tau) - 1)
//-----------------------------------------------------------------------------
module shaper_trapezoidal (
//-----------------------------------------------------------------------------
// Input Ports
//-----------------------------------------------------------------------------
	input  wire                                                       clk,
	input  wire                                                       reset,
//-----------------------------------------------------------------------------
	input  wire                                                       end_impuls,
//-----------------------------------------------------------------------------
	input  wire                                                       trapezoidal_ena,
	input  wire                                                       enable,
	input  wire                                                       overflow_ena,
//-----------------------------------------------------------------------------
	input  wire [SIZE_SHAPER_CONSTANT-1:0]                            k_trapezoidal,
	input  wire [SIZE_SHAPER_CONSTANT-1:0]                            l_trapezoidal,
	input  wire [SIZE_SHAPER_CONSTANT-1:0]                            M1_trapezoidal,
	input  wire [SIZE_SHAPER_CONSTANT-1:0]                            M2_trapezoidal,
//-----------------------------------------------------------------------------
	input  wire [SIZE_SHAPER_DATA + SIZE_SHAPER_ADD_CAPACITY:0]       shift_reg_input_sig                [SIZE_SHAPER_SHIFT_REG-1:0], //60
	input  wire                                                       pulse_time,
//-----------------------------------------------------------------------------
// Output Ports
//-----------------------------------------------------------------------------
	output reg  [SIZE_SHAPER_DATA-1:0]                                output_data);
//-----------------------------------------------------------------------------
// Signal declarations
//-----------------------------------------------------------------------------
	reg  signed [SIZE_SHAPER_DATA + SIZE_SHAPER_ADD_CAPACITY:0]       dk_trapezoidal_a;
	reg  signed [SIZE_SHAPER_DATA + SIZE_SHAPER_ADD_CAPACITY:0]       dk_trapezoidal_b;
	wire signed [SIZE_SHAPER_DATA + SIZE_SHAPER_ADD_CAPACITY:0]       dk_trapezoidal;
//-----------------------------------------------------------------------------
	reg  signed [SIZE_SHAPER_DATA + SIZE_SHAPER_ADD_CAPACITY:0]       dl_trapezoidal_a;
	reg  signed [SIZE_SHAPER_DATA + SIZE_SHAPER_ADD_CAPACITY:0]       dl_trapezoidal_b;
	wire signed [SIZE_SHAPER_DATA + SIZE_SHAPER_ADD_CAPACITY:0]       dl_trapezoidal;
//-----------------------------------------------------------------------------
	wire signed [SIZE_SHAPER_DATA + SIZE_SHAPER_ADD_CAPACITY:0]       dkl_trapezoidal;
	wire signed [SIZE_SHAPER_DATA + SIZE_SHAPER_ADD_CAPACITY:0]       dkl_M1_trapezoidal_rate;
	reg  signed [SIZE_SHAPER_DATA + SIZE_SHAPER_ADD_CAPACITY:0]       dkl_M1_trapezoidal_rate_late;
	wire signed [SIZE_SHAPER_DATA + SIZE_SHAPER_ADD_CAPACITY:0]       dkl_M2_trapezoidal_rate;
	reg  signed [SIZE_SHAPER_DATA + SIZE_SHAPER_ADD_CAPACITY:0]       dkl_M2_trapezoidal_rate_late_0;
	reg  signed [SIZE_SHAPER_DATA + SIZE_SHAPER_ADD_CAPACITY:0]       dkl_M2_trapezoidal_rate_late_1;
	reg  signed [SIZE_SHAPER_DATA + SIZE_SHAPER_ADD_CAPACITY:0]       dkl_M2_trapezoidal_rate_late_2;
//-----------------------------------------------------------------------------
	wire signed [SIZE_SHAPER_DATA + SIZE_SHAPER_ADD_CAPACITY:0]       p_trapezoidal;
	reg  signed [SIZE_SHAPER_DATA + SIZE_SHAPER_ADD_CAPACITY:0]       p_trapezoidal_late;
//-----------------------------------------------------------------------------
	reg  signed [SIZE_SHAPER_DATA + SIZE_SHAPER_ADD_CAPACITY:0]       r_trapezoidal;
	reg         [SIZE_SHAPER_DATA + SIZE_SHAPER_ADD_CAPACITY:0]       r_trapezoidal_late;
//-----------------------------------------------------------------------------
	reg  signed [SIZE_SHAPER_DATA + SIZE_SHAPER_ADD_CAPACITY:0]       q_trapezoidal;
	reg         [SIZE_SHAPER_DATA + SIZE_SHAPER_ADD_CAPACITY:0]       q_trapezoidal_late;
//-----------------------------------------------------------------------------
	reg  signed [SIZE_SHAPER_DATA + SIZE_SHAPER_ADD_CAPACITY:0]       s_trapezoidal;
	reg         [SIZE_SHAPER_DATA + SIZE_SHAPER_ADD_CAPACITY:0]       s_trapezoidal_late;
	reg         [SIZE_SHAPER_DATA + SIZE_SHAPER_ADD_CAPACITY:0]       s_trapezoidal_norm;
	reg  signed [SIZE_SHAPER_DATA + SIZE_SHAPER_ADD_CAPACITY:0]       s_trapezoidal_norm_late;
//-----------------------------------------------------------------------------
	reg         [SIZE_SHAPER_DATA + SIZE_SHAPER_ADD_CAPACITY:0]       input_data_late                    [1:0];
	reg         [SIZE_SHAPER_DATA + SIZE_SHAPER_ADD_CAPACITY:0]       input_data_difference;
//-----------------------------------------------------------------------------
	reg                                                               reset_mult;
	reg                                                               ena_plus_one;
//-----------------------------------------------------------------------------
// Sub Module Section
//-----------------------------------------------------------------------------
	shaper_add_sub ShaperAddSubDk (
		.aclr                                                     (~reset_mult),
		.add_sub                                                  (0),
		.clock                                                    (clk),
		.dataa                                                    (dk_trapezoidal_a),
		.datab                                                    (dk_trapezoidal_b),
		.result                                                   (dk_trapezoidal));

	shaper_add_sub ShaperAddSubDl (
		.aclr                                                     (~reset_mult),
		.add_sub                                                  (0),
		.clock                                                    (clk),
		.dataa                                                    (dl_trapezoidal_a),
		.datab                                                    (dl_trapezoidal_b),
		.result                                                   (dl_trapezoidal));

	shaper_add_sub ShaperAddSubDkl (
		.aclr                                                     (~reset_mult),
		.add_sub                                                  (0),
		.clock                                                    (clk),
		.dataa                                                    (dk_trapezoidal),
		.datab                                                    (dl_trapezoidal),
		.result                                                   (dkl_trapezoidal));

	shaper_mult ShaperMultM1 (
		.aclr                                                     (~reset_mult),
		.clock                                                    (clk),
		.dataa                                                    (dkl_trapezoidal),
		.datab                                                    (M1_trapezoidal),
		.result                                                   (dkl_M1_trapezoidal_rate));

	shaper_mult ShaperMultM2 (
		.aclr                                                     (~reset_mult),
		.clock                                                    (clk),
		.dataa                                                    (dkl_trapezoidal),
		.datab                                                    (M2_trapezoidal),
		.result                                                   (dkl_M2_trapezoidal_rate));

	shaper_add_sub ShaperAddSubP (
		.aclr                                                     (~reset_mult),
		.add_sub                                                  (1),
		.clock                                                    (clk),
		.dataa                                                    (p_trapezoidal),
		.datab                                                    (dkl_trapezoidal),
		.result                                                   (p_trapezoidal));

	shaper_add_sub ShaperAddSubR (
		.aclr                                                     (~reset_mult),
		.add_sub                                                  (1),
		.clock                                                    (clk),
		.dataa                                                    (p_trapezoidal_late),
		.datab                                                    (dkl_M1_trapezoidal_rate_late),
		.result                                                   (r_trapezoidal));

	shaper_add_sub ShaperAddSubQ (
		.aclr                                                     (~reset_mult),
		.add_sub                                                  (1),
		.clock                                                    (clk),
		.dataa                                                    (r_trapezoidal_late),
		.datab                                                    (dkl_M2_trapezoidal_rate_late_2),
		.result                                                   (q_trapezoidal));

	shaper_add_sub ShaperAddSubS (
		.aclr                                                      (~reset_mult),
		.add_sub                                                   (1),
		.clock                                                     (clk),
		.dataa                                                     (r_trapezoidal),
		.datab                                                     (s_trapezoidal),
		.result                                                    (s_trapezoidal));
//-----------------------------------------------------------------------------
// Signal Section
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// Process Section
//-----------------------------------------------------------------------------
	always_ff @ (negedge reset_mult or posedge clk)
	begin: SHAPER_TRAPEZOIDAL_CALCULATE
		if (!reset_mult)
		begin
			dk_trapezoidal_a                                  <= 0;
			dk_trapezoidal_b                                  <= 0;
//-----------------------------------------------------------------------------
			dl_trapezoidal_a                                  <= 0;
			dl_trapezoidal_b                                  <= 0;
//-----------------------------------------------------------------------------
			dkl_M1_trapezoidal_rate_late                      <= 0;
			dkl_M2_trapezoidal_rate_late_0                    <= 0;
			dkl_M2_trapezoidal_rate_late_1                    <= 0;
			dkl_M2_trapezoidal_rate_late_2                    <= 0;
//-----------------------------------------------------------------------------
			p_trapezoidal_late                                <= 0;
			r_trapezoidal_late                                <= 0;
			q_trapezoidal_late                                <= 0;
		end
		else
		begin
			dk_trapezoidal_a                                  <= shift_reg_input_sig[0];
			dk_trapezoidal_b                                  <= shift_reg_input_sig[k];
//-----------------------------------------------------------------------------
			dl_trapezoidal_a                                  <= shift_reg_input_sig[l];
			dl_trapezoidal_b                                  <= shift_reg_input_sig[k+l];
//-----------------------------------------------------------------------------
			dkl_M1_trapezoidal_rate_late                      <= dkl_M1_trapezoidal_rate;
			dkl_M2_trapezoidal_rate_late_0                    <= dkl_M2_trapezoidal_rate;
			dkl_M2_trapezoidal_rate_late_1                    <= dkl_M2_trapezoidal_rate_late_0;
			dkl_M2_trapezoidal_rate_late_2                    <= dkl_M2_trapezoidal_rate_late_1;
//-----------------------------------------------------------------------------
			p_trapezoidal_late                                <= p_trapezoidal;
			r_trapezoidal_late                                <= r_trapezoidal;
			q_trapezoidal_late                                <= q_trapezoidal;
		end
	end
//-----------------------------------------------------------------------------
	always_ff @ (negedge reset or posedge clk)
	begin: SHAPER_TRAPEZOIDAL_RESET_MULT
		if (!reset)
		begin
			reset_mult                                        <= 0;
		end
		else
		begin
			if (trapezoidal_ena && enable && pulse_time)
				reset_mult                                <= 1;
			else
				reset_mult                                <= 0;
		end
	end
//-----------------------------------------------------------------------------
	always_ff @ (negedge reset_mult or posedge clk)
	begin: SHAPER_TRAPEZOIDAL_OUTPUT_DATA
		if (!reset_mult)
		begin
			output_data                                      <= 0;
		end
		else
		begin
			output_data                                      <= s_trapezoidal >>> norm;
		end
	end
//-----------------------------------------------------------------------------
endmodule
