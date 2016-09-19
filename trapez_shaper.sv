//-----------------------------------------------------------------------------
// Title       : trapez_shaper
//-----------------------------------------------------------------------------
// File        : trapez_shaper.sv
// Company     : My company
// Created     : 19/03/2014
// Created by  : Alina Ivanova
//-----------------------------------------------------------------------------
// Description : trapezoidal pulse shaper
//-----------------------------------------------------------------------------
// Revision    : 1.1
//-----------------------------------------------------------------------------
// Copyright (c) 2014 My company
// This work may not be copied, modified, re-published, uploaded, executed, or
// distributed in any way, in any medium, whether in whole or in part, without
// prior written permission from My company.
//-----------------------------------------------------------------------------
// dkl(n) = v(n)   - v(n-k) - v(n-l) + v(n-k-l)
//   p(n) = p(n-1) + dkl(n), n<=0
//   r(n) = p(n)   + M*dkl(n)
//   q(n) = r(n)   + M2*dkl(n)
//   s(n) = s(n-1) + q(n),   n<=0
//   M    = 1/(exp(Tclk/tau) - 1)
//-----------------------------------------------------------------------------
`timescale 1ns/1ps
//-----------------------------------------------------------------------------
import package_settings::*;
//-----------------------------------------------------------------------------
module trapez_shaper (
//-----------------------------------------------------------------------------
// Input Ports
//-----------------------------------------------------------------------------
	input  wire                                                       clk,
	input  wire                                                       reset,
//-----------------------------------------------------------------------------
	input  wire                                                       end_impuls,
//-----------------------------------------------------------------------------
	input  wire                                                       trapez_ena,
	input  wire                                                       enable,
	input  wire                                                       overflow_ena,
//-----------------------------------------------------------------------------
	input  wire [SIZE_SHAPER_CONSTANT-1:0]                            k_trapez,
	input  wire [SIZE_SHAPER_CONSTANT-1:0]                            l_trapez,
	input  wire [SIZE_SHAPER_CONSTANT-1:0]                            M1_trapez,
	input  wire [SIZE_SHAPER_CONSTANT-1:0]                            M2_trapez,
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
	reg  signed [SIZE_SHAPER_DATA + SIZE_SHAPER_ADD_CAPACITY:0]       dk_trapez_a;
	reg  signed [SIZE_SHAPER_DATA + SIZE_SHAPER_ADD_CAPACITY:0]       dk_trapez_b;
	wire signed [SIZE_SHAPER_DATA + SIZE_SHAPER_ADD_CAPACITY:0]       dk_trapez;
//-----------------------------------------------------------------------------
	reg  signed [SIZE_SHAPER_DATA + SIZE_SHAPER_ADD_CAPACITY:0]       dl_trapez_a;
	reg  signed [SIZE_SHAPER_DATA + SIZE_SHAPER_ADD_CAPACITY:0]       dl_trapez_b;
	wire signed [SIZE_SHAPER_DATA + SIZE_SHAPER_ADD_CAPACITY:0]       dl_trapez;
//-----------------------------------------------------------------------------
	wire signed [SIZE_SHAPER_DATA + SIZE_SHAPER_ADD_CAPACITY:0]       dkl_trapez;
	wire signed [SIZE_SHAPER_DATA + SIZE_SHAPER_ADD_CAPACITY:0]       dkl_M1_trapez_rate;
	reg  signed [SIZE_SHAPER_DATA + SIZE_SHAPER_ADD_CAPACITY:0]       dkl_M1_trapez_rate_late;
	wire signed [SIZE_SHAPER_DATA + SIZE_SHAPER_ADD_CAPACITY:0]       dkl_M2_trapez_rate;
	reg  signed [SIZE_SHAPER_DATA + SIZE_SHAPER_ADD_CAPACITY:0]       dkl_M2_trapez_rate_late_0;
	reg  signed [SIZE_SHAPER_DATA + SIZE_SHAPER_ADD_CAPACITY:0]       dkl_M2_trapez_rate_late_1;
	reg  signed [SIZE_SHAPER_DATA + SIZE_SHAPER_ADD_CAPACITY:0]       dkl_M2_trapez_rate_late_2;
//-----------------------------------------------------------------------------
	wire signed [SIZE_SHAPER_DATA + SIZE_SHAPER_ADD_CAPACITY:0]       p_trapez;
	reg  signed [SIZE_SHAPER_DATA + SIZE_SHAPER_ADD_CAPACITY:0]       p_trapez_late;
//-----------------------------------------------------------------------------
	reg  signed [SIZE_SHAPER_DATA + SIZE_SHAPER_ADD_CAPACITY:0]       r_trapez;
	reg         [SIZE_SHAPER_DATA + SIZE_SHAPER_ADD_CAPACITY:0]       r_trapez_late;
//-----------------------------------------------------------------------------
	reg  signed [SIZE_SHAPER_DATA + SIZE_SHAPER_ADD_CAPACITY:0]       q_trapez;
	reg         [SIZE_SHAPER_DATA + SIZE_SHAPER_ADD_CAPACITY:0]       q_trapez_late;
//-----------------------------------------------------------------------------
	reg  signed [SIZE_SHAPER_DATA + SIZE_SHAPER_ADD_CAPACITY:0]       s_trapez;
	reg         [SIZE_SHAPER_DATA + SIZE_SHAPER_ADD_CAPACITY:0]       s_trapez_late;
	reg         [SIZE_SHAPER_DATA + SIZE_SHAPER_ADD_CAPACITY:0]       s_trapez_norm;
	reg  signed [SIZE_SHAPER_DATA + SIZE_SHAPER_ADD_CAPACITY:0]       s_trapez_norm_late;
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
		.dataa                                                    (dk_trapez_a),
		.datab                                                    (dk_trapez_b),
		.result                                                   (dk_trapez));

	shaper_add_sub ShaperAddSubDl (
		.aclr                                                     (~reset_mult),
		.add_sub                                                  (0),
		.clock                                                    (clk),
		.dataa                                                    (dl_trapez_a),
		.datab                                                    (dl_trapez_b),
		.result                                                   (dl_trapez));

	shaper_add_sub ShaperAddSubDkl (
		.aclr                                                     (~reset_mult),
		.add_sub                                                  (0),
		.clock                                                    (clk),
		.dataa                                                    (dk_trapez),
		.datab                                                    (dl_trapez),
		.result                                                   (dkl_trapez));

	shaper_mult ShaperMultM1 (
		.aclr                                                     (~reset_mult),
		.clock                                                    (clk),
		.dataa                                                    (dkl_trapez),
		.datab                                                    (M1_trapez),
		.result                                                   (dkl_M1_trapez_rate));

	shaper_mult ShaperMultM2 (
		.aclr                                                     (~reset_mult),
		.clock                                                    (clk),
		.dataa                                                    (dkl_trapez),
		.datab                                                    (M2_trapez),
		.result                                                   (dkl_M2_trapez_rate));

	shaper_add_sub ShaperAddSubP (
		.aclr                                                     (~reset_mult),
		.add_sub                                                  (1),
		.clock                                                    (clk),
		.dataa                                                    (p_trapez),
		.datab                                                    (dkl_trapez),
		.result                                                   (p_trapez));

	shaper_add_sub ShaperAddSubR (
		.aclr                                                     (~reset_mult),
		.add_sub                                                  (1),
		.clock                                                    (clk),
		.dataa                                                    (p_trapez_late),
		.datab                                                    (dkl_M1_trapez_rate_late),
		.result                                                   (r_trapez));

	shaper_add_sub ShaperAddSubQ (
		.aclr                                                     (~reset_mult),
		.add_sub                                                  (1),
		.clock                                                    (clk),
		.dataa                                                    (r_trapez_late),
		.datab                                                    (dkl_M2_trapez_rate_late_2),
		.result                                                   (q_trapez));

	shaper_add_sub ShaperAddSubS (
		.aclr                                                      (~reset_mult),
		.add_sub                                                   (1),
		.clock                                                     (clk),
		.dataa                                                     (r_trapez),
		.datab                                                     (s_trapez),
		.result                                                    (s_trapez));
//-----------------------------------------------------------------------------
// Signal Section
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// Process Section
//-----------------------------------------------------------------------------
	always_ff @ (negedge reset_mult or posedge clk) begin: SHAPER_TRAPEZ_CALCULATE
		if (!reset_mult) begin
			{dk_trapez_a, dk_trapez_b}              <= '0;
//-----------------------------------------------------------------------------
			{dl_trapez_a, dl_trapez_b}              <= '0;
//-----------------------------------------------------------------------------
			{dkl_M1_trapez_rate_late, dkl_M2_trapez_rate_late_0, dkl_M2_trapez_rate_late_1, dkl_M2_trapez_rate_late_2} <= '0;
//-----------------------------------------------------------------------------
			{p_trapez_late, r_trapez_late, q_trapez_late} <= '0;
		end else begin
			dk_trapez_a                                  <= shift_reg_input_sig[0];
			dk_trapez_b                                  <= shift_reg_input_sig[k];
//-----------------------------------------------------------------------------
			dl_trapez_a                                  <= shift_reg_input_sig[l];
			dl_trapez_b                                  <= shift_reg_input_sig[k+l];
//-----------------------------------------------------------------------------
			dkl_M1_trapez_rate_late                      <= dkl_M1_trapez_rate;
			dkl_M2_trapez_rate_late_0                    <= dkl_M2_trapez_rate;
			dkl_M2_trapez_rate_late_1                    <= dkl_M2_trapez_rate_late_0;
			dkl_M2_trapez_rate_late_2                    <= dkl_M2_trapez_rate_late_1;
//-----------------------------------------------------------------------------
			p_trapez_late                                <= p_trapez;
			r_trapez_late                                <= r_trapez;
			q_trapez_late                                <= q_trapez;
		end
	end: SHAPER_TRAPEZ_CALCULATE
//-----------------------------------------------------------------------------
	always_ff @ (negedge reset or posedge clk) begin: SHAPER_TRAPEZ_RESET_MULT
		if (!reset) begin
			reset_mult                                        <= '0;
		end else begin
			if (trapez_ena && enable && pulse_time)
				reset_mult                                <= 1'b1;
			else
				reset_mult                                <= '0;
		end
	end: SHAPER_TRAPEZ_RESET_MULT
//-----------------------------------------------------------------------------
	always_ff @ (negedge reset_mult or posedge clk) begin: SHAPER_TRAPEZ_OUTPUT_DATA
		if (!reset_mult) begin
			output_data                                      <= '0;
		end else begin
			output_data                                      <= s_trapez >>> norm;
		end
	end: SHAPER_TRAPEZ_OUTPUT_DATA
//-----------------------------------------------------------------------------
endmodule: trapez_shaper
