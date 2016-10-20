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
	input  wire                                                       trapez_ena,
	input  wire                                                       enable,
	input  wire                                                       overflow_ena,
//-----------------------------------------------------------------------------
	input  wire [SIZE_SHAPER_CONSTANT-1:0]                            k_trapez,
	input  wire [SIZE_SHAPER_CONSTANT-1:0]                            l_trapez,
	input  wire [SIZE_SHAPER_CONSTANT-1:0]                            M1_trapez,
	input  wire [SIZE_SHAPER_CONSTANT-1:0]                            M2_trapez,
//-----------------------------------------------------------------------------
	input  wire [SIZE_SHAPER_DATA_ADD_CAPACITY:0]                     shift_reg_input_sig     [SIZE_SHAPER_SHIFT_REG],
	input  wire                                                       pulse_time,
//-----------------------------------------------------------------------------
// Output Ports
//-----------------------------------------------------------------------------
	output reg  [SIZE_SHAPER_DATA-1:0]                                output_data);
//-----------------------------------------------------------------------------
// Signal declarations
//-----------------------------------------------------------------------------
	reg  signed [SIZE_SHAPER_DATA_ADD_CAPACITY:0]                     dk_trapez_a;
	reg  signed [SIZE_SHAPER_DATA_ADD_CAPACITY:0]                     dk_trapez_b;
	wire signed [SIZE_SHAPER_DATA_ADD_CAPACITY:0]                     dk_trapez;
//-----------------------------------------------------------------------------
	reg  signed [SIZE_SHAPER_DATA_ADD_CAPACITY:0]                     dl_trapez_a;
	reg  signed [SIZE_SHAPER_DATA_ADD_CAPACITY:0]                     dl_trapez_b;
	wire signed [SIZE_SHAPER_DATA_ADD_CAPACITY:0]                     dl_trapez;
//-----------------------------------------------------------------------------
	wire signed [SIZE_SHAPER_DATA_ADD_CAPACITY:0]                     dkl_trapez;
	wire signed [SIZE_SHAPER_DATA_ADD_CAPACITY:0]                     dkl_M1_trapez_rate;
	reg  signed [SIZE_SHAPER_DATA_ADD_CAPACITY:0]                     dkl_M1_trapez_rate_late;
	wire signed [SIZE_SHAPER_DATA_ADD_CAPACITY:0]                     dkl_M2_trapez_rate;
	reg  signed [SIZE_SHAPER_DATA_ADD_CAPACITY:0]                     dkl_M2_trapez_rate_late [3];
//-----------------------------------------------------------------------------
	wire signed [SIZE_SHAPER_DATA_ADD_CAPACITY:0]                     p_trapez;
	reg  signed [SIZE_SHAPER_DATA_ADD_CAPACITY:0]                     p_trapez_late;
//-----------------------------------------------------------------------------
	reg  signed [SIZE_SHAPER_DATA_ADD_CAPACITY:0]                     r_trapez;
	reg         [SIZE_SHAPER_DATA_ADD_CAPACITY:0]                     r_trapez_late;
//-----------------------------------------------------------------------------
	reg  signed [SIZE_SHAPER_DATA_ADD_CAPACITY:0]                     q_trapez;
	reg         [SIZE_SHAPER_DATA_ADD_CAPACITY:0]                     q_trapez_late;
//-----------------------------------------------------------------------------
	reg  signed [SIZE_SHAPER_DATA_ADD_CAPACITY:0]                     s_trapez;
//-----------------------------------------------------------------------------
	reg         [SIZE_SHAPER_DATA_ADD_CAPACITY:0]                     input_data_late         [2];
	reg         [SIZE_SHAPER_DATA_ADD_CAPACITY:0]                     input_data_difference;
//-----------------------------------------------------------------------------
	reg                                                               reset_mult;
//-----------------------------------------------------------------------------
// Sub Module Section
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// Signal Section
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// Process Section
//-----------------------------------------------------------------------------
	always_ff @(negedge reset_mult or posedge clk) begin: SHAPER_TRAPEZ_CALCULATE
		if (!reset_mult) begin
			{dk_trapez_a, dk_trapez_b}                    <= '0;
//-----------------------------------------------------------------------------
			{dl_trapez_a, dl_trapez_b}                    <= '0;
//-----------------------------------------------------------------------------
			{dkl_M1_trapez_rate_late, dkl_M2_trapez_rate_late[0], dkl_M2_trapez_rate_late[1], dkl_M2_trapez_rate_late[2]} <= '0;
//-----------------------------------------------------------------------------
			{p_trapez_late, r_trapez_late, q_trapez_late} <= '0;
		end else begin
			dk_trapez_a                                  <= shift_reg_input_sig[0];
			dk_trapez_b                                  <= shift_reg_input_sig[k];
			dk_trapez                                    <= dk_trapez_a - dk_trapez_b;
//-----------------------------------------------------------------------------
			dl_trapez_a                                  <= shift_reg_input_sig[l];
			dl_trapez_b                                  <= shift_reg_input_sig[k+l];
			dl_trapez                                    <= dl_trapez_a - dl_trapez_b;
//-----------------------------------------------------------------------------
			dkl_trapez                                   <= dk_trapez - dl_trapez;
//-----------------------------------------------------------------------------
			dkl_M1_trapez_rate                           <= dkl_trapez * M1_trapez;
			dkl_M2_trapez_rate                           <= dkl_trapez * M2_trapez;
//-----------------------------------------------------------------------------
			dkl_M1_trapez_rate_late                      <= dkl_M1_trapez_rate;
			dkl_M2_trapez_rate_late[0]                   <= dkl_M2_trapez_rate;
			dkl_M2_trapez_rate_late[1]                   <= dkl_M2_trapez_rate_late[0];
			dkl_M2_trapez_rate_late[2]                   <= dkl_M2_trapez_rate_late[1];
//-----------------------------------------------------------------------------
			p_trapez                                     <= p_trapez + dkl_trapez;
			p_trapez_late                                <= p_trapez;
//-----------------------------------------------------------------------------
			r_trapez_late                                <= r_trapez;
		        r_trapez                                     <= p_trapez_late + dkl_M1_trapez_rate_late;
//-----------------------------------------------------------------------------
			q_trapez_late                                <= q_trapez;
			q_trapez                                     <= r_trapez_late + dkl_M2_trapez_rate_late[2];
//-----------------------------------------------------------------------------
			s_trapez                                     <= r_trapez + s_trapez;			
//-----------------------------------------------------------------------------
		end
	end: SHAPER_TRAPEZ_CALCULATE
//-----------------------------------------------------------------------------
	always_ff @(negedge reset or posedge clk) begin: SHAPER_TRAPEZ_RESET_MULT
		if (!reset) begin
			reset_mult                                   <= '0;
		end else begin
			if (trapez_ena && enable && pulse_time)
				reset_mult                           <= 1'b1;
			else
				reset_mult                           <= '0;
		end
	end: SHAPER_TRAPEZ_RESET_MULT
//-----------------------------------------------------------------------------
	always_ff @(negedge reset_mult or posedge clk) begin: SHAPER_TRAPEZ_OUTPUT_DATA
		if (!reset_mult) begin
			output_data                                  <= '0;
		end else begin
			output_data                                  <= s_trapez >>> norm;
		end
	end: SHAPER_TRAPEZ_OUTPUT_DATA
//-----------------------------------------------------------------------------
endmodule: trapez_shaper
