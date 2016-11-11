//-----------------------------------------------------------------------------
// Original Author: Alina Ivanova
// email: alina.al.ivanova@gmail.com
// web: www.alinaivanovaoff.com
// interfaces_pkg.sv
// Created: 11.11.2016
//
// Interfaces package.
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
interface trapez_shaper_data_intf import settings_pkg::*; (
    input wire                                            clk,
    input wire                                            reset);
    wire signed [DATA_SIZE-1:0]                           input_data;
    wire                                                  enable;
    modport master                                        (output input_data, enable);
    modport slave                                         (input  input_data, enable);
endinterface: trapez_shaper_data_intf
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
interface trapez_shaper_result_intf import settings_pkg::*; ();
    wire signed [FULL_SIZE-1:0]                           output_data;
    wire                                                  output_data_valid;
    modport master                                        (output output_data, output_data_valid);
    modport slave                                         (input  output_data, output_data_valid);
endinterface: trapez_shaper_result_intf
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------