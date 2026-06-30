`timescale 1ns/1ps

module fp_unpack #(
    parameter integer WIDTH = 32,
    parameter integer EXP_WIDTH = 8,
    parameter integer MANT_WIDTH = WIDTH - EXP_WIDTH - 1
)(
    input  [WIDTH-1:0]      a,
    input  [WIDTH-1:0]      b,

    output                  a_sign,
    output                  b_sign,

    output [EXP_WIDTH-1:0]  a_exp,
    output [EXP_WIDTH-1:0]  b_exp,

    output [MANT_WIDTH-1:0] a_frac,
    output [MANT_WIDTH-1:0] b_frac,

    output                  a_zero,
    output                  b_zero,

    output                  a_inf,
    output                  b_inf,

    output                  a_nan,
    output                  b_nan,

    output                  a_denorm,
    output                  b_denorm
);

    localparam [EXP_WIDTH-1:0] EXP_ZERO     = {EXP_WIDTH{1'b0}};
    localparam [EXP_WIDTH-1:0] EXP_ALL_ONES = {EXP_WIDTH{1'b1}};
    localparam [MANT_WIDTH-1:0] FRAC_ZERO   = {MANT_WIDTH{1'b0}};

    assign a_sign = a[WIDTH-1];
    assign b_sign = b[WIDTH-1];

    assign a_exp = a[WIDTH-2:MANT_WIDTH];
    assign b_exp = b[WIDTH-2:MANT_WIDTH];

    assign a_frac = a[MANT_WIDTH-1:0];
    assign b_frac = b[MANT_WIDTH-1:0];

    assign a_zero = (a_exp == EXP_ZERO) && (a_frac == FRAC_ZERO);
    assign b_zero = (b_exp == EXP_ZERO) && (b_frac == FRAC_ZERO);

    assign a_inf = (a_exp == EXP_ALL_ONES) && (a_frac == FRAC_ZERO);
    assign b_inf = (b_exp == EXP_ALL_ONES) && (b_frac == FRAC_ZERO);

    assign a_nan = (a_exp == EXP_ALL_ONES) && (a_frac != FRAC_ZERO);
    assign b_nan = (b_exp == EXP_ALL_ONES) && (b_frac != FRAC_ZERO);

    assign a_denorm = (a_exp == EXP_ZERO) && (a_frac != FRAC_ZERO);
    assign b_denorm = (b_exp == EXP_ZERO) && (b_frac != FRAC_ZERO);

endmodule