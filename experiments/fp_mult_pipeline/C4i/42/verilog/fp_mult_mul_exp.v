`timescale 1ns/1ps

module fp_mult_mul_exp (
    input  [7:0]  exp_a,
    input  [7:0]  exp_b,
    input  [23:0] mant_a,
    input  [23:0] mant_b,
    input         a_subnormal,
    input         b_subnormal,
    output [47:0] product,
    output signed [10:0] exp_sum
);

    localparam signed [10:0] BIAS = 11'sd127;

    /*
     * For IEEE-754 single precision:
     *
     *   Normal number:
     *      value exponent = exp_field - 127
     *
     *   Subnormal number:
     *      value exponent = 1 - 127 = -126
     *
     * Therefore, for exponent addition using biased exponents, subnormal
     * operands must use an effective biased exponent of 1 rather than 0.
     */
    wire [7:0] eff_exp_a;
    wire [7:0] eff_exp_b;

    assign eff_exp_a = a_subnormal ? 8'd1 : exp_a;
    assign eff_exp_b = b_subnormal ? 8'd1 : exp_b;

    /*
     * 24-bit significand multiplication.
     *
     * The unpack stage is responsible for supplying mantissas with the
     * correct hidden-bit handling:
     *   - normal:    {1'b1, fraction}
     *   - subnormal: {1'b0, fraction}
     */
    assign product = mant_a * mant_b;

    /*
     * Preliminary biased result exponent before product normalization.
     *
     * Using biased exponents:
     *
     *   result_exp = eff_exp_a + eff_exp_b - BIAS
     *
     * This may be negative for underflow candidates or greater than 255 for
     * overflow candidates, so keep it signed and wider than 8 bits.
     */
    assign exp_sum = $signed({3'b000, eff_exp_a}) +
                     $signed({3'b000, eff_exp_b}) -
                     BIAS;

endmodule