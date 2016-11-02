//(c) Alina Ivanova, alina.al.ivanova@gmail.com
//-----------------------------------------------------------------------------
// dkl(n) = v(n)   - v(n-k) - v(n-l) + v(n-k-l)
//   p(n) = p(n-1) + dkl(n), n<=0
//   r(n) = p(n)   + M_1*dkl(n)
//   q(n) = r(n)   + M_2*dkl(n)
//   s(n) = s(n-1) + q(n),   n<=0
//   M    = 1/(exp(Tclk/tau) - 1)
//   M    = M_1 / M_2
//-----------------------------------------------------------------------------
`timescale 1ns/1ps
//-----------------------------------------------------------------------------
import package_settings::*;
//-----------------------------------------------------------------------------
module trapez_shaper (
//-----------------------------------------------------------------------------
// Input Ports
//-----------------------------------------------------------------------------
    input  wire                                           clk,
    input  wire                                           reset,
//-----------------------------------------------------------------------------
    input  wire [SIZE_DATA-1:0]                           input_data,
    input  wire                                           enable,
    input  wire                                           trapez_ena,
    input  wire                                           overflow_ena,
    input  wire                                           pulse_time,
//-----------------------------------------------------------------------------
// Output Ports
//-----------------------------------------------------------------------------
    output reg  [SIZE_SHAPER_DATA-1:0]                    output_data);
//-----------------------------------------------------------------------------
// Signal declarations
//-----------------------------------------------------------------------------
    reg         [SIZE_SHAPER_DATA_ADD_CAPACITY-1:0]       shift_reg            [SIZE_SHAPER_SHIFT_REG];
//-----------------------------------------------------------------------------
    reg  signed [SIZE_SHAPER_DATA_ADD_CAPACITY-1:0]       dk_trapez_a;
    reg  signed [SIZE_SHAPER_DATA_ADD_CAPACITY-1:0]       dk_trapez_b;
    wire signed [SIZE_SHAPER_DATA_ADD_CAPACITY-1:0]       dk_trapez;
//-----------------------------------------------------------------------------
    reg  signed [SIZE_SHAPER_DATA_ADD_CAPACITY-1:0]       dl_trapez_a;
    reg  signed [SIZE_SHAPER_DATA_ADD_CAPACITY-1:0]       dl_trapez_b;
    wire signed [SIZE_SHAPER_DATA_ADD_CAPACITY-1:0]       dl_trapez;
//-----------------------------------------------------------------------------
    wire signed [SIZE_SHAPER_DATA_ADD_CAPACITY-1:0]       dkl_trapez;
    wire signed [SIZE_SHAPER_DATA_ADD_CAPACITY-1:0]       dkl_M_1_trapez_rate;
    reg  signed [SIZE_SHAPER_DATA_ADD_CAPACITY-1:0]       dkl_M_1_trapez_rate_z;
    wire signed [SIZE_SHAPER_DATA_ADD_CAPACITY-1:0]       dkl_M_2_trapez_rate;
    reg  signed [SIZE_SHAPER_DATA_ADD_CAPACITY-1:0]       dkl_M_2_trapez_rate_z[SIZE_DKL_M_2_TRAPEZ_RATE];
//-----------------------------------------------------------------------------
    wire signed [SIZE_SHAPER_DATA_ADD_CAPACITY-1:0]       p_trapez;
    reg  signed [SIZE_SHAPER_DATA_ADD_CAPACITY-1:0]       p_trapez_z;
//-----------------------------------------------------------------------------
    reg  signed [SIZE_SHAPER_DATA_ADD_CAPACITY-1:0]       r_trapez;
    reg         [SIZE_SHAPER_DATA_ADD_CAPACITY-1:0]       r_trapez_z;
//-----------------------------------------------------------------------------
    reg  signed [SIZE_SHAPER_DATA_ADD_CAPACITY-1:0]       q_trapez;
    reg         [SIZE_SHAPER_DATA_ADD_CAPACITY-1:0]       q_trapez_z;
//-----------------------------------------------------------------------------
    reg  signed [SIZE_SHAPER_DATA_ADD_CAPACITY-1:0]       s_trapez;
//-----------------------------------------------------------------------------
    reg                                                   reset_mult;
//-----------------------------------------------------------------------------
// Sub Module Section
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// Signal Section
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// Process Section
//-----------------------------------------------------------------------------
    always_ff @(negedge reset or posedge clk) begin: SHAPER_TRAPEZ_SHIFT_REG
        if (!reset) begin
            for (int i = 0; i < SIZE_SHAPER_SHIFT_REG; i++) begin
                shift_reg[i]                              <= '0;
            end
        end else begin
            shift_reg[0]                                  <= {{SIZE_SHAPER_ADD_CAPACITY{0}}, input_data};
            for (int i = 1; i < SIZE_SHAPER_SHIFT_REG; i++) begin
                shift_reg[i]                              <= shift_reg[i-1];
            end
        end
    end: SHAPER_TRAPEZ_SHIFT_REG
//-----------------------------------------------------------------------------
    always_ff @(negedge reset or posedge clk) begin: SHAPER_TRAPEZ_RESET_MULT
        if (!reset) begin
            reset_mult                                    <= '0;
        end else begin
            reset_mult                                    <= (trapez_ena & enable & pulse_time) ? '1 : '0;
        end
    end: SHAPER_TRAPEZ_RESET_MULT
//-----------------------------------------------------------------------------
    always_ff @(posedge clk) begin: SHAPER_TRAPEZ_CALCULATE
        if (!reset_mult) begin
            {dk_trapez_a, dk_trapez_b, dk_trapez}         <= '0;
            {dl_trapez_a, dl_trapez_b, dl_trapez}         <= '0;
            dkl_trapez                                    <= '0;
//-----------------------------------------------------------------------------
            {dkl_M_1_trapez_rate, dkl_M_1_trapez_rate_z}  <= '0;
            {dkl_M_2_trapez_rate, dkl_M_2_trapez_rate_z}  <= '0;
            for (int i = 0; i < SIZE_DKL_M_2_TRAPEZ_RATE; i++) begin
                dkl_M_2_trapez_rate_z[i]                  <= '0;
            end
//-----------------------------------------------------------------------------
            {p_trapez, p_trapez_z}                        <= '0;
            {r_trapez_z, r_trapez_z}                      <= '0;
            {q_trapez_z, q_trapez_z}                      <= '0;
            s_trapez                                      <= '0;
        end else begin
            dk_trapez_a                                   <= shift_reg[0];
            dk_trapez_b                                   <= shift_reg[K];
            dk_trapez                                     <= dk_trapez_a - dk_trapez_b;
//-----------------------------------------------------------------------------
            dl_trapez_a                                   <= shift_reg[L];
            dl_trapez_b                                   <= shift_reg[K + L];
            dl_trapez                                     <= dl_trapez_a - dl_trapez_b;
//-----------------------------------------------------------------------------
            dkl_trapez                                    <= dk_trapez - dl_trapez;
//-----------------------------------------------------------------------------
            dkl_M_1_trapez_rate                           <= dkl_trapez * M_1;
            dkl_M_2_trapez_rate                           <= dkl_trapez * M_2;
//-----------------------------------------------------------------------------
            dkl_M_1_trapez_rate_z                         <= dkl_M_1_trapez_rate;
            dkl_M_2_trapez_rate_z[0]                      <= dkl_M_2_trapez_rate;
            for (int i = 1; i < SIZE_DKL_M_2_TRAPEZ_RATE; i++) begin
                dkl_M_2_trapez_rate_z[i]                  <= dkl_M_2_trapez_rate_z[i - 1];
            end
//-----------------------------------------------------------------------------
            p_trapez                                      <= p_trapez + dkl_trapez;
            p_trapez_z                                    <= p_trapez;
//-----------------------------------------------------------------------------
            r_trapez_z                                    <= r_trapez;
            r_trapez                                      <= p_trapez_z + dkl_M_1_trapez_rate_z;
//-----------------------------------------------------------------------------
            q_trapez_z                                    <= q_trapez;
            q_trapez                                      <= r_trapez_z + dkl_M_2_trapez_rate_z[SIZE_DKL_M_2_TRAPEZ_RATE - 1];
//-----------------------------------------------------------------------------
            s_trapez                                      <= r_trapez + s_trapez;           
        end
    end: SHAPER_TRAPEZ_CALCULATE
//-----------------------------------------------------------------------------
    always_ff @(posedge clk) begin: SHAPER_TRAPEZ_OUTPUT_DATA
        if (!reset_mult) begin
            output_data                                   <= '0;
        end else begin
            output_data                                   <= s_trapez >>> NORM;
        end
    end: SHAPER_TRAPEZ_OUTPUT_DATA
//-----------------------------------------------------------------------------
endmodule: trapez_shaper
