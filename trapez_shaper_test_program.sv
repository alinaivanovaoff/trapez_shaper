//-----------------------------------------------------------------------------
// Original Author: Alina Ivanova
// email: alina.al.ivanova@gmail.com
// web: www.alinaivanovaoff.com
// trapez_shaper_test_program.sv
// Created: 10.26.2016
//
// Program for trapez_shaper Testbench.
//
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
`timescale 1 ns / 1 ps
//-----------------------------------------------------------------------------
program trapez_shaper_test_program import settings_pkg::*; (
    interface ICKData,
    interface ICKResult);
//-----------------------------------------------------------------------------
    logic signed [FULL_SIZE-1:0]                       data_gm_fifo[$] = '{70, 150, -5, -150, 14, 93, -55, -16, 79, -15};
    logic signed [FULL_SIZE-1:0]                       data_gm;
    logic signed [DATA_SIZE-1:0]                       data_in_fifo[$] = '{10,  20,  5,   -5,  7,  8,  -3,   5,  8,   1};
    logic signed [DATA_SIZE-1:0]                       input_data;
    logic                                              enable;
//-----------------------------------------------------------------------------
    assign ICKData.input_data                          = input_data;
    assign ICKData.enable                              = enable;
//-----------------------------------------------------------------------------
    initial begin: TRAPEZ_SHAPER_TEST_PROGRAM_INITIAL
        $display("Running program");
        input_data                                     = 0;
        enable                                         = 0;
        @(posedge ICKData.reset);
//        $display("After reset");
        #12;
        input_data                                     = 10;
        enable                                         = 1;
//-----------------------------------------------------------------------------
        fork
            fork
                begin
                    while (data_in_fifo.size() != 0) begin
//                        $display("Inside cycle in");
//                        $stop;
                        @(posedge ICKData.clk);
//                        $display("Inside clk in");
//                        $stop;
                        input_data                     = data_in_fifo.pop_front();
                        enable                         = 1;
//                        $display("Input data: %d; Enable: %d", input_data, enable);
//                        $stop;
                    end
                    @(posedge ICKData.clk);
                    enable                             = 0;
                end
                begin
                    while (data_gm_fifo.size() != 0) begin
//                        $display("Inside cycle");
//                        $stop;
                        @(posedge ICKData.clk);
//                        $display("Inside clk");
//                      $stop;
//                        $display("Data valid = %d", ICKResult.output_data_valid);
                        if (ICKResult.output_data_valid) begin
//                          $display("Inside if");
//                          $stop;
                            data_gm                     = data_gm_fifo.pop_front();
//                          $display("Data in golden mode: %d", data_gm);
//                          $stop;
//                            if ((data_gm - ICKResult.output_data) != 0) begin
//                                $display("Error! Expetcted DATA: %d != received DATA: %d", data_gm, ICKResult.output_data);
//                            end
//                            else
                                $display("Expetcted DATA = %d; received DATA = %d", data_gm, ICKResult.output_data);
                        end
                    end
                    $display("Test finished.");
                    $stop;
                end
            join
            begin
                while ($time < 5000) begin
                    @(posedge ICKData.clk);
                end
                $display("Timeout!");
                $stop;
            end
        join_any
    end: TRAPEZ_SHAPER_TEST_PROGRAM_INITIAL
//-----------------------------------------------------------------------------
endprogram: trapez_shaper_test_program
