`timescale 1ns/1ps

module fp_unpack_classify #(
    parameter EXP_WIDTH  = 8,
    parameter MANT_WIDTH = 23,
    parameter WIDTH      = 1 + EXP_WIDTH + MANT_WIDTH
)(
    input  [WIDTH-1:0] operand,
    output             sign,
    output [EXP_WIDTH-1:0] exponent,
    output [MANT_WIDTH-1:0] mantissa,
    output             is_zero,
    output             is_inf,
    output             is_nan
);

    wire exp_all_zero;
    wire exp_all_one;
    wire mant_all_zero;

    assign sign     = operand[WIDTH-1];
    assign exponent = operand[WIDTH-2:MANT_WIDTH];
    assign mantissa = operand[MANT_WIDTH-1:0];

    assign exp_all_zero  = (exponent == {EXP_WIDTH{1'b0}});
    assign exp_all_one   = (exponent == {EXP_WIDTH{1'b1}});
    assign mant_all_zero = (mantissa == {MANT_WIDTH{1'b0}});

    assign is_zero = exp_all_zero;
    assign is_inf  = exp_all_one && mant_all_zero;
    assign is_nan  = exp_all_one && !mant_all_zero;

endmodule