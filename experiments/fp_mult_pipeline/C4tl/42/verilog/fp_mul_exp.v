`timescale 1ns/1ps

module fp_mul_exp (
    input  [23:0] a_significand,
    input  [23:0] b_significand,
    input  signed [12:0] a_exponent,
    input  signed [12:0] b_exponent,
    output [47:0] product,
    output signed [12:0] exponent_sum
);

    /*
     * 24-bit significand multiply.
     *
     * Explicitly widen one operand to 48 bits so the multiplication expression
     * cannot be truncated to 24 bits by Verilog expression sizing rules.
     * Since both original operands are 24 bits, the mathematical product always
     * fits in 48 bits.
     */
    assign product = {24'b0, a_significand} * b_significand;

    /*
     * Add unbiased signed exponents.
     *
     * Single-precision unbiased exponent sums are well within 13 signed bits
     * for the supported datapath range.
     */
    assign exponent_sum = a_exponent + b_exponent;

endmodule