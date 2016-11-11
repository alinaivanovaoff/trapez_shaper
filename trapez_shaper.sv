//-----------------------------------------------------------------------------
// Original Author: Alina Ivanova
// email: alina.al.ivanova@gmail.com
// web: alinaivanovaoff.com
// trapez_shaper.sv
// Created: 11.10.2016
//
// Trapezoidal Shaper 
//
//-----------------------------------------------------------------------------
// dkl(n) = v(n)   - v(n-k) - v(n-l) + v(n-k-l)
//   p(n) = p(n-1) + dkl(n), n<=0
//   r(n) = p(n)   + M_1*dkl(n)
//   q(n) = r(n)   + M_2*dkl(n)
//   s(n) = s(n-1) + q(n),   n<=0
//   M    = 1/(exp(Tclk/tau) - 1)
//   M    = M_1 / M_2
//-----------------------------------------------------------------------------
// Copyright (c) 2016 by Alina Ivanova
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>. 
//-----------------------------------------------------------------------------
`timescale 1ns / 1ps
//-----------------------------------------------------------------------------
`include "settings_pkg.sv"
//-----------------------------------------------------------------------------
module trapez_shaper import settings_pkg::*; (
//-----------------------------------------------------------------------------
// Input Ports
//-----------------------------------------------------------------------------
    input  wire                                           clk,
    input  wire                                           reset,
//-----------------------------------------------------------------------------
    input  wire signed [DATA_SIZE-1:0]                    input_data,
    input  wire                                           enable,
//-----------------------------------------------------------------------------
// Output Ports
//-----------------------------------------------------------------------------
    output reg         [FULL_SIZE-1:0]                    output_data,
    output reg                                            output_data_valid);
//-----------------------------------------------------------------------------
// Signal declarations
//-----------------------------------------------------------------------------
    reg                                                   reset_synch;
    reg                [2:0]                              reset_z;
//-----------------------------------------------------------------------------
    reg                                                   enable_z             [PIPELINE_STAGES];
//-----------------------------------------------------------------------------
    reg                [FULL_SIZE-1:0]                    shift_reg            [SHIFT_REG_SIZE];
//-----------------------------------------------------------------------------
    reg  signed        [FULL_SIZE-1:0]                    dk_trapez_a;
    reg  signed        [FULL_SIZE-1:0]                    dk_trapez_b;
    reg  signed        [FULL_SIZE-1:0]                    dk_trapez;
//-----------------------------------------------------------------------------
    reg  signed        [FULL_SIZE-1:0]                    dl_trapez_a;
    reg  signed        [FULL_SIZE-1:0]                    dl_trapez_b;
    reg  signed        [FULL_SIZE-1:0]                    dl_trapez;
//-----------------------------------------------------------------------------
    reg  signed        [FULL_SIZE-1:0]                    dkl_trapez;
    reg  signed        [FULL_SIZE-1:0]                    dkl_M_1_trapez_rate;
    reg  signed        [FULL_SIZE-1:0]                    dkl_M_2_trapez_rate;
    reg  signed        [FULL_SIZE-1:0]                    dkl_M_2_trapez_rate_z;
//-----------------------------------------------------------------------------
    reg  signed        [FULL_SIZE-1:0]                    p_trapez;
//-----------------------------------------------------------------------------
    reg  signed        [FULL_SIZE-1:0]                    r_trapez;
//-----------------------------------------------------------------------------
    reg  signed        [FULL_SIZE-1:0]                    q_trapez;
//-----------------------------------------------------------------------------
    reg  signed        [FULL_SIZE-1:0]                    s_trapez;
//-----------------------------------------------------------------------------
// Sub Module Section
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// Signal Section
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// Process Section
//-----------------------------------------------------------------------------
    always_ff @(posedge clk) begin: SHAPER_TRAPEZ_RESET_SYNCH
        reset_z                                          <= {reset_z[1:0], reset};
        reset_synch                                      <= (reset_z[1] & (~reset_z[2])) ? '1 : '0 ;
    end: SHAPER_TRAPEZ_RESET_SYNCH
//-----------------------------------------------------------------------------
    always_ff @(posedge clk) begin: SHAPER_TRAPEZ_SHIFT_REG
        if (reset_synch) begin
            for (int i = 0; i < SHIFT_REG_SIZE; i++) begin
                shift_reg[i]                              <= '0;
            end
            enable_z[0]                                   <= '0;
        end else begin
            shift_reg[0]                                  <= input_data[DATA_SIZE-1] ? {{EXTRA_BITS{1'b1}}, input_data} : {{EXTRA_BITS{1'b0}}, input_data};
            for (int i = 1; i < SHIFT_REG_SIZE; i++) begin
                shift_reg[i]                              <= shift_reg[i-1];
            end
            enable_z[0]                                   <= enable;
        end
    end: SHAPER_TRAPEZ_SHIFT_REG
//-----------------------------------------------------------------------------
    always_ff @(posedge clk) begin: SHAPER_TRAPEZ_CALCULATE
        if (reset_synch) begin
            {dk_trapez_a, dk_trapez_b, dk_trapez}         <= '0;
            {dl_trapez_a, dl_trapez_b, dl_trapez}         <= '0;
            dkl_trapez                                    <= '0;
//-----------------------------------------------------------------------------
            dkl_M_1_trapez_rate                           <= '0;
            {dkl_M_2_trapez_rate, dkl_M_2_trapez_rate_z}  <= '0;
//-----------------------------------------------------------------------------
            {p_trapez, r_trapez, q_trapez, s_trapez}      <= '0;
//-----------------------------------------------------------------------------
            for (int i = 1; i < PIPELINE_STAGES; i++) begin
                enable_z[i]                               <= '0;
            end
        end else begin
            dk_trapez_a                                   <= shift_reg[0];
            dk_trapez_b                                   <= shift_reg[K];
            dk_trapez                                     <= dk_trapez_a - dk_trapez_b;
            enable_z[1]                                   <= enable_z[0];
            enable_z[2]                                   <= enable_z[1];
//-----------------------------------------------------------------------------
            dl_trapez_a                                   <= shift_reg[L];
            dl_trapez_b                                   <= shift_reg[K + L];
            dl_trapez                                     <= dl_trapez_a - dl_trapez_b;
//-----------------------------------------------------------------------------
            dkl_trapez                                    <= dk_trapez - dl_trapez;
            enable_z[3]                                   <= enable_z[2];
//-----------------------------------------------------------------------------
            dkl_M_1_trapez_rate                           <= dkl_trapez * M_1;
            dkl_M_2_trapez_rate                           <= dkl_trapez * M_2;
//-----------------------------------------------------------------------------
            dkl_M_2_trapez_rate_z                         <= dkl_M_2_trapez_rate;
//-----------------------------------------------------------------------------
            p_trapez                                      <= p_trapez + dkl_trapez;
            enable_z[4]                                   <= enable_z[3];
//-----------------------------------------------------------------------------
            r_trapez                                      <= p_trapez + dkl_M_1_trapez_rate;
            enable_z[5]                                   <= enable_z[4];
//-----------------------------------------------------------------------------
            q_trapez                                      <= r_trapez + dkl_M_2_trapez_rate_z;
            enable_z[6]                                   <= enable_z[5];
//-----------------------------------------------------------------------------
            s_trapez                                      <= q_trapez + s_trapez;
            enable_z[7]                                   <= enable_z[6];           
        end
    end: SHAPER_TRAPEZ_CALCULATE
//-----------------------------------------------------------------------------
    always_ff @(posedge clk) begin: SHAPER_TRAPEZ_OUTPUT_DATA
        if (reset_synch) begin
            output_data                                   <= '0;
            output_data_valid                             <= '0;
        end else begin
            output_data                                   <= s_trapez;
            output_data_valid                             <= enable_z[7];
        end
    end: SHAPER_TRAPEZ_OUTPUT_DATA
//-----------------------------------------------------------------------------
endmodule: trapez_shaper
