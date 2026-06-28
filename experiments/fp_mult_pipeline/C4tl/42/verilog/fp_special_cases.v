`timescale 1ns/1ps

module fp_special_cases (
    input  a_sign,
    input  b_sign,
    input  a_zero,
    input  b_zero,
    input  a_inf,
    input  b_inf,
    input  a_nan,
    input  b_nan,
    output result_sign,
    output result_is_nan,
    output result_is_inf,
    output result_is_zero
);

    /*
     * IEEE-754 multiplication special-case priority:
     *
     * 1. Any NaN operand produces NaN.
     * 2. 0 * infinity, or infinity * 0, is invalid and produces NaN.
     * 3. Infinity times any nonzero finite operand produces infinity.
     * 4. Zero times any finite non-infinity operand produces signed zero.
     * 5. Otherwise the normal datapath computes the result.
     */

    wire invalid_zero_inf;

    assign result_sign = a_sign ^ b_sign;

    assign invalid_zero_inf = (a_zero & b_inf) | (a_inf & b_zero);

    assign result_is_nan  = a_nan | b_nan | invalid_zero_inf;

    assign result_is_inf  = ~result_is_nan &&
                            (a_inf | b_inf);

    assign result_is_zero = ~result_is_nan &&
                            ~result_is_inf &&
                            (a_zero | b_zero);

endmodule