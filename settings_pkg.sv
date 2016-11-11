//-----------------------------------------------------------------------------
// Original Author: Alina Ivanova
// email: alina.al.ivanova@gmail.com
// web: alinaivanovaoff.com
// settings_pkg.sv
// Created: 11.10.2016
//
// Settings package.
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
package settings_pkg;
//-----------------------------------------------------------------------------
// Parameter Declaration(s)
//-----------------------------------------------------------------------------
    parameter CHANNEL_SIZE                                   = 2;
//-----------------------------------------------------------------------------
    parameter K                                              = 25;
    parameter L                                              = 20;
    parameter NORM                                           = 10;
    parameter M_1                                            = 3;
    parameter M_2                                            = 17;
//-----------------------------------------------------------------------------
    parameter DATA_SIZE                                      = 16;
    parameter SHIFT_REG_SIZE                                 = 300;
    parameter CONSTANT_SIZE                                  = 8;
    parameter EXTRA_BITS                                     = 10; //for current constant K, L, M_1, M_2
    parameter FULL_SIZE                                      = DATA_SIZE + EXTRA_BITS;
    parameter DKL_M_2_TRAPEZ_RATE_SIZE                       = 3;
    parameter PIPELINE_STAGES                                = 8;
//-----------------------------------------------------------------------------
endpackage: settings_pkg
