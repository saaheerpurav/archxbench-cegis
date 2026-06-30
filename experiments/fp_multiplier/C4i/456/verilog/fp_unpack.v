`timescale 1ns/1ps

module fp_unpack #(
    parameter EXP_WIDTH  = 8,
    parameter MANT_WIDTH = 23,
    parameter WIDTH      = 1 + EXP_WIDTH + MANT_WIDTH
)(
    input  [WIDTH-1:0] operand,
    output sign,
    output [EXP_WIDTH-1:0] exponent,
    output [MANT_WIDTH-1:0] mantissa,
    output [MANT_WIDTH:0] significand,
    output signed [EXP_WIDTH+1:0] unbiased_exponent,
    output is_zero,
    output is_inf,
    output is_nan,
    output is_denorm
);

    localparam [EXP_WIDTH-1:0] EXP_ZERO = {EXP_WIDTH{1'b0}};
    localparam [EXP_WIDTH-1:0] EXP_MAX  = {EXP_WIDTH{1'b1}};
    localparam [MANT_WIDTH-1:0] MANT_ZERO = {MANT_WIDTH{1'b0}};

    localparam signed [EXP_WIDTH+1:0] BIAS =
        (1 << (EXP_WIDTH - 1)) - 1;

    wire exp_is_zero;
    wire exp_is_max;
    wire mant_is_zero;

    assign sign     = operand[WIDTH-1];
    assign exponent = operand[WIDTH-2:MANT_WIDTH];
    assign mantissa = operand[MANT_WIDTH-1:0];

    assign exp_is_zero  = (exponent == EXP_ZERO);
    assign exp_is_max   = (exponent == EXP_MAX);
    assign mant_is_zero = (mantissa == MANT_ZERO);

    assign is_zero   = exp_is_zero && mant_is_zero;
    assign is_denorm = exp_is_zero && !mant_is_zero;
    assign is_inf    = exp_is_max  && mant_is_zero;
    assign is_nan    = exp_is_max  && !mant_is_zero;

    assign significand = exp_is_zero ? {1'b0, mantissa}
                                     : {1'b1, mantissa};

    assign unbiased_exponent = exp_is_zero
                             ? ($signed({{(EXP_WIDTH+1){1'b0}}, 1'b1}) - BIAS)
                             : ($signed({2'b00, exponent}) - BIAS);

endmodule