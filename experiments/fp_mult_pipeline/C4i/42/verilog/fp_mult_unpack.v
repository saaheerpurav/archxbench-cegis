`timescale 1ns/1ps

module fp_mult_unpack (
    input  [31:0] operand,
    output        sign,
    output [7:0]  exp,
    output [23:0] mant,
    output        is_zero,
    output        is_inf,
    output        is_nan,
    output        is_subnormal
);

    wire [22:0] frac;

    assign sign = operand[31];
    assign exp  = operand[30:23];
    assign frac = operand[22:0];

    assign is_zero      = (exp == 8'h00) && (frac == 23'd0);
    assign is_inf       = (exp == 8'hFF) && (frac == 23'd0);
    assign is_nan       = (exp == 8'hFF) && (frac != 23'd0);
    assign is_subnormal = (exp == 8'h00) && (frac != 23'd0);

    /*
     * IEEE-754 single precision significand unpacking:
     *
     * Normal numbers:
     *   value = (-1)^sign * 1.frac * 2^(exp - 127)
     *   so the multiplier receives {1'b1, frac}.
     *
     * Zero and subnormal numbers:
     *   exponent field is zero and there is no implicit hidden 1,
     *   so the multiplier receives {1'b0, frac}.
     *
     * Inf/NaN:
     *   mantissa is not used by the final special-case result path.
     *   Keeping the same exponent-nonzero hidden-bit rule is harmless and
     *   keeps the unpacking logic simple.
     */
    assign mant = (exp == 8'h00) ? {1'b0, frac} : {1'b1, frac};

endmodule