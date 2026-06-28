`timescale 1ns/1ps

module fp_multiplier_significand_product #(
    parameter EXP_WIDTH  = 8,
    parameter MANT_WIDTH = 23
)(
    input  [MANT_WIDTH:0] sig_a,
    input  [MANT_WIDTH:0] sig_b,

    input  signed [EXP_WIDTH+1:0] exp_a,
    input  signed [EXP_WIDTH+1:0] exp_b,

    output reg [2*(MANT_WIDTH+1)-1:0] product,
    output reg signed [EXP_WIDTH+2:0] exponent_sum
);

    /*
     * The significands are already prepared by the previous stage.
     * For IEEE single precision, these are 24-bit values:
     *
     *   sig = {implicit_hidden_bit, mantissa}
     *
     * Their raw product is therefore 48 bits wide.
     */

    /*
     * exp_a and exp_b are signed unbiased exponents.
     *
     * Each exponent input is EXP_WIDTH+2 bits wide.  The sum of two signed
     * values of that width requires one additional bit, so exponent_sum is
     * EXP_WIDTH+3 bits wide.
     *
     * Explicit sign-extension is required before addition.  Otherwise Verilog
     * evaluates exp_a + exp_b using only the operand width, then extends the
     * already-truncated result to the destination width.
     */

    always @(*) begin
        product = sig_a * sig_b;

        exponent_sum =
            {exp_a[EXP_WIDTH+1], exp_a} +
            {exp_b[EXP_WIDTH+1], exp_b};
    end

endmodule