//(c) Alina Ivanova, alina.al.ivanova@gmail.com
//----------------------------------------------------------------------------- 
package package_settings;
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
    parameter SIZE_SHAPER_DATA                               = 16;
    parameter SIZE_SHAPER_SHIFT_REG                          = 300;
    parameter SIZE_SHAPER_CONSTANT                           = 8;
    parameter SIZE_SHAPER_ADD_CAPACITY                       = 10;
    parameter SIZE_SHAPER_DATA_ADD_CAPACITY                  = SIZE_SHAPER_DATA + SIZE_SHAPER_ADD_CAPACITY;
    parameter SHAPER_ADD_CONSTANT                            = 100;
    parameter SIZE_INTEGRAL_TIME_COUNTER                     = 16;
    parameter SIZE_DKL_M_2_TRAPEZ_RATE                       = 3;
//-----------------------------------------------------------------------------
endpackage: package_settings
