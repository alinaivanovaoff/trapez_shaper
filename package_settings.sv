//-----------------------------------------------------------------------------
// Title       : package_settings (parameters)
//-----------------------------------------------------------------------------
// File        : package_settings.sv
// Company     : My company
// Created     : 11/03/2014
// Created by  : Alina Ivanova
//-----------------------------------------------------------------------------
// Description : settings package
//-----------------------------------------------------------------------------
// Revision    : 1.0_alpha
//-----------------------------------------------------------------------------
// Copyright (c) 2014 My company
// This work may not be copied, modified, re-published, uploaded, executed, or
// distributed in any way, in any medium, whether in whole or in part, without
// prior written permission from My company.
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
package package_settings;
//-----------------------------------------------------------------------------
// Parameter Declaration(s)
//-----------------------------------------------------------------------------
	parameter CHANNEL_SIZE                                   = 2;
//-----------------------------------------------------------------------------
	parameter k                                              = 25;
	parameter l                                              = 20;
	parameter norm                                           = 10;
//-----------------------------------------------------------------------------
	parameter SIZE_ADC_SAMPLES                               = 7;
	parameter SIZE_ADC_DATA                                  = 14;
	parameter SIZE_SPI_CS                                    = 3;
	parameter SIZE_TST                                       = 8;
	parameter SIZE_FLAG                                      = 3;
//-----------------------------------------------------------------------------
	parameter SIZE_START_REG_LATCH                           = 4;
	parameter SIZE_REG_DATA                                  = 8;
	parameter SIZE_BIT_COUNTER                               = 6;
	parameter SIZE_BIT                                       = 16;
//-----------------------------------------------------------------------------
	parameter SIZE_EN_SP_RAM_ADDR                            = 12;
	parameter SIZE_EN_SP_RAM_DATA                            = 32;
//-----------------------------------------------------------------------------
	parameter SIZE_EVENT_COUNTER                             = 32;
//-----------------------------------------------------------------------------
	parameter SIZE_TEST_DELAY                                = 8;
	parameter SIZE_TEST_RAM_ADDR                             = 9;
//-----------------------------------------------------------------------------
	parameter SIZE_MOVING_AVERAGE_MAX_WINDOW                 = 256;
	parameter SIZE_MOVING_AVERAGE_WINDOW                     = 16;
//-----------------------------------------------------------------------------
	parameter SIZE_SHAPER_DATA                               = 16;
	parameter SIZE_SHAPER_SHIFT_REG                          = 300;
	parameter SIZE_SHAPER_CONSTANT                           = 8;
	parameter SIZE_SHAPER_ADD_CAPACITY                       = 9;
	parameter SHAPER_ADD_CONSTANT                            = 100;
	parameter SIZE_INTEGRAL_TIME_COUNTER                     = 16;
//-----------------------------------------------------------------------------
	parameter SIZE_WORK_TIME                                 = 64;
//-----------------------------------------------------------------------------
	parameter SIZE_MEASURING_ZERO_LINE_COUNTER               = 9;
	parameter MEASURING_ZERO_LINE_TIME                       = 254;
//-----------------------------------------------------------------------------
	parameter SIZE_COUNTER_PILE_UP_TIME                      = 9;  //убрать
//-----------------------------------------------------------------------------
	parameter SIZE_REGISTER                                  = 16;
	parameter SIZE_COMMAND                                   = 8;
	parameter NUMBER_REGISTER                                = 128;
//-----------------------------------------------------------------------------
	parameter SIZE_GAIN_BIAS                                 = 12;
//-----------------------------------------------------------------------------
	parameter SIZE_TIME_WINDOW_REGISTRATION                  = 16;
	parameter SIZE_COUNTER_STATISTIC_SHORT                   = 32;
//-----------------------------------------------------------------------------
	parameter SIZE_WAVEFORM_RAM_TIME_WINDOW                  = 12;
//-----------------------------------------------------------------------------
	parameter SIZE_BUFFER_RAM_DATA_LATE                      = 3;
//-----------------------------------------------------------------------------
	parameter SIZE_OVERFLOW_TIME_COUNTER                     = 8;
//-----------------------------------------------------------------------------
	parameter NUMBER_UNIT                                    = 1;
////-----------------------------------------------------------------------------
//	parameter SIZE_NG_RAM_DATA                               = 32;
//	parameter SIZE_NG_RAM_ADDR                               = 11;
//	parameter SIZE_NG_TIME                                   = 8;
//-----------------------------------------------------------------------------
	parameter SIZE_PULSE_TIME                                = 16;
	parameter SIZE_TRIGGER_TIME                              = 4;
	parameter SIZE_PREHISTORY_TIME                           = 4;
//-----------------------------------------------------------------------------
	parameter SIZE_TIME_MAXIMUM_SEARCH                       = 8;
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
	parameter TYPE_FIRMWARE                                  = 0;
	parameter VERSION                                        = 0;
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
endpackage
