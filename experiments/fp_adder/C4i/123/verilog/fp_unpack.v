`timescale 1ns/1ps

module fp_unpack #(
    parameter WIDTH = 32,
    parameter EXP_WIDTH = 8,
    parameter MANT_WIDTH = 23
)(
    input  [WIDTH-1:0] in,
    output sign,
    output [EXP_WIDTH-1:0] exp,
    output [MANT_WIDTH-1:0] mant,
    output is_zero,
    output is_inf,
    output is_nan,
    output is_denorm
);

    localparam [EXP_WIDTH-1:0] EXP_ZERO = {EXP_WIDTH{1'b0}};
    localparam [EXP_WIDTH-1:0] EXP_MAX  = {EXP_WIDTH{1'b1}};
    localparam [MANT_WIDTH-1:0] MANT_ZERO = {MANT_WIDTH{1'b0}};

    assign sign = in[WIDTH-1];
    assign exp  = in[WIDTH-2:MANT_WIDTH];
    assign mant = in[MANT_WIDTH-1:0];

    assign is_zero   = (exp == EXP_ZERO) && (mant == MANT_ZERO);
    assign is_denorm = (exp == EXP_ZERO) && (mant != MANT_ZERO);
    assign is_inf    = (exp == EXP_MAX)  && (mant == MANT_ZERO);
    assign is_nan    = (exp == EXP_MAX)  && (mant != MANT_ZERO);

endmodule