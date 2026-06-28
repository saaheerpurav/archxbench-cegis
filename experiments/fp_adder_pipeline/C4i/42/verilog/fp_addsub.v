`timescale 1ns/1ps

module fp_addsub (
    input        large_sign,
    input        small_sign,
    input  [7:0] large_exp,
    input [26:0] large_sig,
    input [26:0] small_sig,

    output reg        result_sign,
    output reg [7:0]  result_exp,
    output reg [27:0] result_mant
);

always @* begin
    /*
     * The alignment stage has already selected the larger-magnitude operand
     * and shifted the smaller operand.  Therefore the result exponent starts
     * as the larger operand exponent.  Any later exponent adjustment due to
     * carry-out or leading-zero normalization is handled downstream.
     */
    result_exp = large_exp;

    if (large_sign == small_sign) begin
        /*
         * Same effective signs: add significands.
         *
         * Extend both operands to 28 bits so a carry out of bit 26 is
         * preserved in result_mant[27].
         */
        result_mant = {1'b0, large_sig} + {1'b0, small_sig};
        result_sign = large_sign;
    end else begin
        /*
         * Different effective signs: subtract magnitudes.
         *
         * fp_align guarantees large_sig represents the larger-magnitude
         * operand after alignment, so this subtraction should not underflow.
         */
        result_mant = {1'b0, large_sig} - {1'b0, small_sig};

        /*
         * Exact cancellation should produce +0 for round-to-nearest-even.
         */
        if (result_mant == 28'b0)
            result_sign = 1'b0;
        else
            result_sign = large_sign;
    end
end

endmodule