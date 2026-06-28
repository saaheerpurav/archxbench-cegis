`timescale 1ns/1ps

module fp_unpack (
    input  [31:0] x,
    output        sign,
    output [7:0]  exponent,
    output [22:0] fraction,
    output [23:0] significand,
    output signed [12:0] unbiased_exponent,
    output        is_zero,
    output        is_subnormal,
    output        is_inf,
    output        is_nan
);

    wire exponent_is_zero;
    wire exponent_is_all_ones;
    wire fraction_is_zero;

    assign sign     = x[31];
    assign exponent = x[30:23];
    assign fraction = x[22:0];

    assign exponent_is_zero     = (exponent == 8'h00);
    assign exponent_is_all_ones = (exponent == 8'hFF);
    assign fraction_is_zero     = (fraction == 23'd0);

    assign is_zero      = exponent_is_zero && fraction_is_zero;
    assign is_subnormal = exponent_is_zero && !fraction_is_zero;
    assign is_inf       = exponent_is_all_ones && fraction_is_zero;
    assign is_nan       = exponent_is_all_ones && !fraction_is_zero;

    /*
     * IEEE-754 single precision:
     *   normal    : significand = 1.fraction, exponent = biased_exp - 127
     *   subnormal : significand = 0.fraction, exponent = -126
     *   zero      : significand = 0.0,        exponent = -126 for pipeline use
     */
    assign significand =
        exponent_is_zero ? {1'b0, fraction} :
                           {1'b1, fraction};

    assign unbiased_exponent =
        exponent_is_zero ? -13'sd126 :
                           ($signed({5'd0, exponent}) - 13'sd127);

endmodule