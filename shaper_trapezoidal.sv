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
	output reg  [SIZE_SHAPER_DATA-1:0]                                output_data,
	output reg  [SIZE_SHAPER_DATA-1:0]                                output_signal);
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
	.aclr                                                             (~reset_mult),
	.add_sub                                                          (0),
	.clock                                                            (clk),
	.dataa                                                            (dk_trapezoidal_a),
	.datab                                                            (dk_trapezoidal_b),
	.result                                                           (dk_trapezoidal));

	shaper_add_sub ShaperAddSubDl (
	.aclr                                                             (~reset_mult),
	.add_sub                                                          (0),
	.clock                                                            (clk),
	.dataa                                                            (dl_trapezoidal_a),
	.datab                                                            (dl_trapezoidal_b),
	.result                                                           (dl_trapezoidal));

	shaper_add_sub ShaperAddSubDkl (
	.aclr                                                             (~reset_mult),
	.add_sub                                                          (0),
	.clock                                                            (clk),
	.dataa                                                            (dk_trapezoidal),
	.datab                                                            (dl_trapezoidal),
	.result                                                           (dkl_trapezoidal));

	shaper_mult ShaperMultM1 (
	.aclr                                                             (~reset_mult),
	.clock                                                            (clk),
	.dataa                                                            (dkl_trapezoidal),
	.datab                                                            (M1_trapezoidal),
	.result                                                           (dkl_M1_trapezoidal_rate));

	shaper_mult ShaperMultM2 (
	.aclr                                                             (~reset_mult),
	.clock                                                            (clk),
	.dataa                                                            (dkl_trapezoidal),
	.datab                                                            (M2_trapezoidal),
	.result                                                           (dkl_M2_trapezoidal_rate));

	shaper_add_sub ShaperAddSubP (
	.aclr                                                             (~reset_mult),
	.add_sub                                                          (1),
	.clock                                                            (clk),
	.dataa                                                            (p_trapezoidal),
	.datab                                                            (dkl_trapezoidal),
	.result                                                           (p_trapezoidal));

	shaper_add_sub ShaperAddSubR (
	.aclr                                                             (~reset_mult),
	.add_sub                                                          (1),
	.clock                                                            (clk),
	.dataa                                                            (p_trapezoidal_late),
	.datab                                                            (dkl_M1_trapezoidal_rate_late),
	.result                                                           (r_trapezoidal));

	shaper_add_sub ShaperAddSubQ (
	.aclr                                                             (~reset_mult),
	.add_sub                                                          (1),
	.clock                                                            (clk),
	.dataa                                                            (r_trapezoidal_late),
	.datab                                                            (dkl_M2_trapezoidal_rate_late_2),
	.result                                                           (q_trapezoidal));

	shaper_add_sub ShaperAddSubS (
	.aclr                                                             (~reset_mult),
	.add_sub                                                          (1),
	.clock                                                            (clk),
	.dataa                                                            (r_trapezoidal),
	.datab                                                            (s_trapezoidal),
	.result                                                           (s_trapezoidal));
//-----------------------------------------------------------------------------
// Signal Section
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// Process Section
//-----------------------------------------------------------------------------
	always @ (negedge reset_mult or posedge clk)
	begin: SHAPER_TRAPEZOIDAL_CALCULATE
		if (!reset_mult)
		begin
			dk_trapezoidal_a                                 <= 0;
			dk_trapezoidal_b                                 <= 0;
//			dk_trapezoidal                                   <= 0;
//-----------------------------------------------------------------------------
			dl_trapezoidal_a                                 <= 0;
			dl_trapezoidal_b                                 <= 0;
//			dl_trapezoidal                                   <= 0;
//-----------------------------------------------------------------------------
//			dkl_trapezoidal                                  <= 0;
//			dkl_trapezoidal_rate                             <= 0;
			dkl_M1_trapezoidal_rate_late                     <= 0;
			dkl_M2_trapezoidal_rate_late_0                   <= 0;
			dkl_M2_trapezoidal_rate_late_1                   <= 0;
			dkl_M2_trapezoidal_rate_late_2                   <= 0;
//-----------------------------------------------------------------------------
//			p_trapezoidal                                    <= 0;
			p_trapezoidal_late                               <= 0;
//			r_trapezoidal                                    <= 0;
			r_trapezoidal_late                               <= 0;
			q_trapezoidal_late                               <= 0;
//			s_trapezoidal                                    <= 0;
		end
		else
		begin
			dk_trapezoidal_a                                 <= shift_reg_input_sig[0];//k 8//l 5
			dk_trapezoidal_b                                 <= shift_reg_input_sig[25];//[k_trapezoidal];//k 8//l 5
//			dk_trapezoidal                                   <= dk_trapezoidal_a - dk_trapezoidal_b;
//-----------------------------------------------------------------------------
			dl_trapezoidal_a                                 <= shift_reg_input_sig[20];//[l_trapezoidal];
			dl_trapezoidal_b                                 <= shift_reg_input_sig[45];//[k_trapezoidal + l_trapezoidal];
//			dl_trapezoidal                                   <= dl_trapezoidal_a       - dl_trapezoidal_b;
//-----------------------------------------------------------------------------
//			dkl_trapezoidal                                  <= dk_trapezoidal         - dl_trapezoidal;
//			dkl_trapezoidal_rate                             <= dkl_trapezoidal        * M_trapezoidal;
			dkl_M1_trapezoidal_rate_late                     <= dkl_M1_trapezoidal_rate;
			dkl_M2_trapezoidal_rate_late_0                   <= dkl_M2_trapezoidal_rate;
			dkl_M2_trapezoidal_rate_late_1                   <= dkl_M2_trapezoidal_rate_late_0;
			dkl_M2_trapezoidal_rate_late_2                   <= dkl_M2_trapezoidal_rate_late_1;
//-----------------------------------------------------------------------------
//			p_trapezoidal                                    <= p_trapezoidal          + dkl_trapezoidal;
			p_trapezoidal_late                               <= p_trapezoidal;
//			r_trapezoidal                                    <= p_trapezoidal_late     + dkl_M1_trapezoidal_rate_late;
			r_trapezoidal_late                               <= r_trapezoidal;
//			q_trapezoidal                                    <= r_trapezoidal_late     + dkl_M2_trapezoidal_rate_late;
			q_trapezoidal_late                               <= q_trapezoidal;
//			s_trapezoidal                                    <= s_trapezoidal          + r_trapezoidal;
		end
	end
//-----------------------------------------------------------------------------
//	always @ (negedge reset_mult or posedge clk)
//	begin: SHAPER_TRAPEZOIDAL_S_TRAPEZOIDAL_NORM
//		if (!reset_mult)
//		begin
//			s_trapezoidal_norm                               <= 0;
//			ena_plus_one                                     <= 0;
//		end
//		else
//		begin
//			if (l_trapezoidal <= 1)
//			begin
//				if (!s_trapezoidal[SIZE_SHAPER_DATA + SIZE_SHAPER_ADD_CAPACITY])
//				begin
//					if (!s_trapezoidal[4])
//					begin
//						s_trapezoidal_norm                   <= s_trapezoidal >>> 5;
//						ena_plus_one                         <= 0;
//					end
//					else if (s_trapezoidal[4])
//					begin
//						s_trapezoidal_norm                   <= s_trapezoidal >>> 5;//(s_trapezoidal_sig >>> 5) + 1;
//						ena_plus_one                         <= 1;
//					end
//					else
//						;
//				end
//				else if (s_trapezoidal[SIZE_SHAPER_DATA + SIZE_SHAPER_ADD_CAPACITY])
//				begin
//					if (|s_trapezoidal[4:1])
//					begin
//						s_trapezoidal_norm                   <= s_trapezoidal >>> 5;//(s_trapezoidal_sig >>> 5) + 1;
//						ena_plus_one                         <= 1;
//					end
//					else if ((~|s_trapezoidal[4:1]) && s_trapezoidal[0])
//					begin
//						s_trapezoidal_norm                   <= s_trapezoidal >>> 5;
//						ena_plus_one                         <= 0;
//					end
//					else
//						;
//				end
//				else
//					;
//			end
//			else if ((l_trapezoidal > 1) && (l_trapezoidal <= 3))
//			begin
//				if (!s_trapezoidal[SIZE_SHAPER_DATA + SIZE_SHAPER_ADD_CAPACITY])
//				begin
//					if (!s_trapezoidal[5])
//					begin
//						s_trapezoidal_norm                   <= s_trapezoidal >>> 6;
//						ena_plus_one                         <= 0;
//					end
//					else if (s_trapezoidal[5])
//					begin
//						s_trapezoidal_norm                   <= s_trapezoidal >>> 6;//(s_trapezoidal_sig >>> 6) + 1;
//						ena_plus_one                         <= 1;
//					end
//					else
//						;
//				end
//				else if (s_trapezoidal[SIZE_SHAPER_DATA + SIZE_SHAPER_ADD_CAPACITY])
//				begin
//					if (|s_trapezoidal[5:1])
//					begin
//						s_trapezoidal_norm                   <= s_trapezoidal >>> 6;//(s_trapezoidal_sig >>> 6) + 1;
//						ena_plus_one                         <= 1;
//					end
//					else if ((~|s_trapezoidal[5:1]) && s_trapezoidal[0])
//					begin
//						s_trapezoidal_norm                   <= s_trapezoidal >>> 6;
//						ena_plus_one                         <= 0;
//					end
//					else
//						;
//				end
//				else
//					;
//			end
//			else if ((l_trapezoidal > 3) && (l_trapezoidal <= 7))
//			begin
//				if (!s_trapezoidal[SIZE_SHAPER_DATA + SIZE_SHAPER_ADD_CAPACITY])
//				begin
//					if (!s_trapezoidal[6])
//					begin
//						s_trapezoidal_norm                   <= s_trapezoidal >>> 7;
//						ena_plus_one                         <= 0;
//					end
//					else if (s_trapezoidal[6])
//					begin
//						s_trapezoidal_norm                   <= s_trapezoidal >>> 7;//(s_trapezoidal_sig >>> 7) + 1;
//						ena_plus_one                         <= 1;
//					end
//					else
//						;
//				end
//				else if (s_trapezoidal[SIZE_SHAPER_DATA + SIZE_SHAPER_ADD_CAPACITY])
//				begin
//					if (|s_trapezoidal[6:1])
//					begin
//						s_trapezoidal_norm                   <= s_trapezoidal >>> 7;//(s_trapezoidal_sig >>> 7) + 1;
//						ena_plus_one                         <= 1;
//					end
//					else if ((~|s_trapezoidal[6:1]) && s_trapezoidal[0])
//					begin
//						s_trapezoidal_norm                   <= s_trapezoidal >>> 7;
//						ena_plus_one                         <= 0;
//					end
//					else
//						;
//				end
//				else
//					;
//			end
//			else if ((l_trapezoidal > 7) && (l_trapezoidal <= 15))
//			begin
//				if (!s_trapezoidal[SIZE_SHAPER_DATA + SIZE_SHAPER_ADD_CAPACITY])
//				begin
//					if (!s_trapezoidal[7])
//					begin
//						s_trapezoidal_norm                   <= s_trapezoidal >>> 8;
//						ena_plus_one                         <= 0;
//					end
//					else if (s_trapezoidal[7])
//					begin
//						s_trapezoidal_norm                   <= s_trapezoidal >>> 8;//(s_trapezoidal_sig >>> 8) + 1;
//						ena_plus_one                         <= 1;
//					end
//					else
//						;
//				end
//				else if (s_trapezoidal[SIZE_SHAPER_DATA + SIZE_SHAPER_ADD_CAPACITY])
//				begin
//					if (|s_trapezoidal[7:1])
//					begin
//						s_trapezoidal_norm                   <= s_trapezoidal >>> 8;//(s_trapezoidal_sig >>> 8) + 1;
//						ena_plus_one                         <= 1;
//					end
//					else if ((~|s_trapezoidal[7:1]) && s_trapezoidal[0])
//					begin
//						s_trapezoidal_norm                   <= s_trapezoidal >>> 8;
//						ena_plus_one                         <= 0;
//					end
//					else
//						;
//				end
//				else
//					;
//			end
//			else if ((l_trapezoidal > 15) && (l_trapezoidal <= 30))
//			begin
//				if (!s_trapezoidal[SIZE_SHAPER_DATA + SIZE_SHAPER_ADD_CAPACITY])
//				begin
//					if (!s_trapezoidal[8])
//					begin
//						s_trapezoidal_norm                   <= s_trapezoidal >>> 9;
//						ena_plus_one                         <= 0;
//					end
//					else if (s_trapezoidal[8])
//					begin
//						s_trapezoidal_norm                   <= s_trapezoidal >>> 9;//(s_trapezoidal_sig >>> 9) + 1;
//						ena_plus_one                         <= 1;
//					end
//					else
//						;
//				end
//				else if (s_trapezoidal[SIZE_SHAPER_DATA + SIZE_SHAPER_ADD_CAPACITY])
//				begin
//					if (|s_trapezoidal[8:1])
//					begin
//						s_trapezoidal_norm                   <= s_trapezoidal >>> 9;//(s_trapezoidal_sig >>> 9) + 1;
//						ena_plus_one                         <= 1;
//					end
//					else if ((~|s_trapezoidal[8:1]) && s_trapezoidal[0])
//					begin
//						s_trapezoidal_norm                   <= s_trapezoidal >>> 9;
//						ena_plus_one                         <= 0;
//					end
//					else
//						;
//				end
//				else
//					;
//			end
//			else
//				;
//		end
//	end
//-----------------------------------------------------------------------------
//	always @ (negedge reset_mult or posedge clk)
//	begin: SHAPER_TRAPEZOIDAL_S_NORM
//		if (!reset_mult)
//		begin
//			s_trapezoidal_norm                                           <= 0;
//			ena_plus_one                                                 <= 0;
//		end
//		else
//		begin
//			casex (l_trapezoidal)
//				8'b0000000x:
//				begin
//					s_trapezoidal_norm                                     <= s_trapezoidal >>> 6;
//					if (s_trapezoidal[SIZE_SHAPER_DATA-1 + SIZE_SHAPER_ADD_CAPACITY-1])
//						ena_plus_one                                        <= (s_trapezoidal[5] && (|s_trapezoidal[4:0])) ? 1'd1: 1'd0;
//					else
//						ena_plus_one                                        <=  s_trapezoidal[5] ? 1'd1: 1'd0;
//				end
//				8'b0000001x:
//				begin
//					s_trapezoidal_norm                                     <= s_trapezoidal >>> 7;
//					if (s_trapezoidal[SIZE_SHAPER_DATA-1 + SIZE_SHAPER_ADD_CAPACITY-1])
//						ena_plus_one                                        <= (s_trapezoidal[6] && (|s_trapezoidal[5:0])) ? 1'd1: 1'd0;
//					else
//						ena_plus_one                                        <=  s_trapezoidal[6] ? 1'd1: 1'd0;
//				end
//				8'b000001xx:
//				begin
//					s_trapezoidal_norm                                     <= s_trapezoidal >>> 8;
//					if (s_trapezoidal[SIZE_SHAPER_DATA-1 + SIZE_SHAPER_ADD_CAPACITY-1])
//						ena_plus_one                                        <= (s_trapezoidal[7] && (|s_trapezoidal[6:0])) ? 1'd1: 1'd0;
//					else
//						ena_plus_one                                        <=  s_trapezoidal[7] ? 1'd1: 1'd0;
//				end
//				8'b00001xxx:
//				begin
//					s_trapezoidal_norm                                     <= s_trapezoidal >>> 9;
//					if (s_trapezoidal[SIZE_SHAPER_DATA-1 + SIZE_SHAPER_ADD_CAPACITY-1])
//						ena_plus_one                                        <= (s_trapezoidal[8] && (|s_trapezoidal[7:0])) ? 1'd1: 1'd0;
//					else
//						ena_plus_one                                        <=  s_trapezoidal[8] ? 1'd1: 1'd0;
//				end
//				8'b0001xxxx:
//				begin
//					s_trapezoidal_norm                                     <= s_trapezoidal >>> 10;
//					if (s_trapezoidal[SIZE_SHAPER_DATA-1 + SIZE_SHAPER_ADD_CAPACITY-1])
//						ena_plus_one                                        <= (s_trapezoidal[9] && (|s_trapezoidal[8:0])) ? 1'd1: 1'd0;
//					else
//						ena_plus_one                                        <=  s_trapezoidal[9] ? 1'd1: 1'd0;
//				end
//				8'b001xxxxx:
//				begin
//					s_trapezoidal_norm                                     <= s_trapezoidal >>> 11;
//					if (s_trapezoidal[SIZE_SHAPER_DATA-1 + SIZE_SHAPER_ADD_CAPACITY-1])
//						ena_plus_one                                        <= (s_trapezoidal[10] && (|s_trapezoidal[9:0])) ? 1'd1: 1'd0;
//					else
//						ena_plus_one                                        <=  s_trapezoidal[10] ? 1'd1: 1'd0;
//				end
//				8'b01xxxxxx:
//				begin
//					s_trapezoidal_norm                                     <= s_trapezoidal >>> 12;
//					if (s_trapezoidal[SIZE_SHAPER_DATA-1 + SIZE_SHAPER_ADD_CAPACITY-1])
//						ena_plus_one                                        <= (s_trapezoidal[11] && (|s_trapezoidal[10:0])) ? 1'd1: 1'd0;
//					else
//						ena_plus_one                                        <=  s_trapezoidal[11] ? 1'd1: 1'd0;
//				end
//				8'b1xxxxxxx:
//				begin
//					s_trapezoidal_norm                                     <= s_trapezoidal >>> 13;
//					if (s_trapezoidal[SIZE_SHAPER_DATA-1 + SIZE_SHAPER_ADD_CAPACITY-1])
//						ena_plus_one                                        <= (s_trapezoidal[12] && (|s_trapezoidal[11:0])) ? 1'd1: 1'd0;
//					else
//						ena_plus_one                                        <=  s_trapezoidal[12] ? 1'd1: 1'd0;
//				end
//				default: ;
//			endcase
//		end
//	end
//-----------------------------------------------------------------------------
	always @ (negedge reset_mult or posedge clk)
	begin: SHAPER_TRAPEZOIDAL_S_TRAPEZOIDAL_NORM_LATE
		if (!reset_mult)
		begin
			s_trapezoidal_norm_late                          <= 0;
		end
		else
		begin
			if (ena_plus_one)
				s_trapezoidal_norm_late                       <= s_trapezoidal_norm + 1;
			else
				s_trapezoidal_norm_late                       <= s_trapezoidal_norm;
		end
	end
//-----------------------------------------------------------------------------
	always @ (negedge reset or posedge clk)
	begin: SHAPER_TRAPEZOIDAL_RESET_MULT
		if (!reset)
		begin
			reset_mult                                       <= 0;
		end
		else
		begin
			if (trapezoidal_ena && enable && pulse_time)// & !end_impuls)
				reset_mult                                    <= 1;
			else
				reset_mult                                    <= 0;
		end
	end
//-----------------------------------------------------------------------------
	always @ (negedge reset_mult or posedge clk)
	begin: SHAPER_TRAPEZOIDAL_OUTPUT_DATA
		if (!reset_mult)
		begin
			output_data                                      <= 0;
			output_signal                                    <= 0;
		end
		else
		begin
			output_data                                      <= s_trapezoidal >>> 10;//dkl_trapezoidal;//>>>9;//r_trapezoidal>>>6;//s_trapezoidal>>>12;
			output_signal                                    <= shift_reg_input_sig[12];
		end
	end
//-----------------------------------------------------------------------------
endmodule
