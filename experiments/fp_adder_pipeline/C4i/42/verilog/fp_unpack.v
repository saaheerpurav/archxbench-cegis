`timescale 1ns/1ps

module fp_unpack (
    input  [31:0] operand,
    output        sign,
    output [7:0]  exp,
    output [22:0] frac,
    output [7:0]  exp_eff,
    output [23:0] sig,
    output        is_zero,
    output        is_inf,
    output        is_nan
);

    // Raw IEEE-754 field extraction.
    assign sign = operand[31];
    assign exp  = operand[30:23];
    assign frac = operand[22:0];

    // IEEE-754 special-case classification.
    assign is_zero = (exp == 8'h00) && (frac == 23'b0);
    assign is_inf  = (exp == 8'hff) && (frac == 23'b0);
    assign is_nan  = (exp == 8'hff) && (frac != 23'b0);

    // For exponent alignment, subnormals use an effective exponent of 1.
    // Their hidden bit remains 0.
    assign exp_eff = (exp == 8'h00) ? 8'h01 : exp;

    // Normal numbers have an implicit leading 1.
    // Subnormal numbers and zeros have no implicit leading bit.
    assign sig = (exp == 8'h00) ? {1'b0, frac} : {1'b1, frac};

endmodule