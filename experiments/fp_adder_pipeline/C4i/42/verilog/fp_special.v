`timescale 1ns/1ps

module fp_special (
    input        a_sign,
    input  [7:0] a_exp,
    input [22:0] a_frac,
    input        a_zero,
    input        a_inf,
    input        a_nan,

    input        b_sign,
    input  [7:0] b_exp,
    input [22:0] b_frac,
    input        b_zero,
    input        b_inf,
    input        b_nan,

    output reg        special_valid,
    output reg [31:0] special_result
);

    localparam [31:0] CANONICAL_QNAN = 32'h7fc00000;

    always @* begin
        special_valid  = 1'b0;
        special_result = 32'b0;

        /*
         * NaNs have highest priority.  This unit returns a canonical quiet NaN
         * rather than attempting payload propagation.
         */
        if (a_nan || b_nan) begin
            special_valid  = 1'b1;
            special_result = CANONICAL_QNAN;
        end

        /*
         * Infinity handling.
         *
         * b_sign is assumed to be the subtraction-adjusted/effective sign.
         * Therefore, for subtraction, +INF - +INF is seen here as
         * +INF + -INF and correctly produces NaN.
         */
        else if (a_inf && b_inf) begin
            special_valid = 1'b1;

            if (a_sign != b_sign)
                special_result = CANONICAL_QNAN;
            else
                special_result = {a_sign, 8'hff, 23'b0};
        end

        else if (a_inf) begin
            special_valid  = 1'b1;
            special_result = {a_sign, 8'hff, 23'b0};
        end

        else if (b_inf) begin
            special_valid  = 1'b1;
            special_result = {b_sign, 8'hff, 23'b0};
        end

        /*
         * Zero handling.
         *
         * For exact zero under round-to-nearest-even:
         *   - equal signs preserve the common sign
         *   - opposite signs produce +0
         *
         * Since b_sign is effective, this also covers subtraction cases.
         */
        else if (a_zero && b_zero) begin
            special_valid = 1'b1;

            if (a_sign == b_sign)
                special_result = {a_sign, 31'b0};
            else
                special_result = 32'h00000000;
        end

        /*
         * One zero operand: bypass the nonzero operand.
         * For B passthrough, use the effective B sign.
         */
        else if (a_zero) begin
            special_valid  = 1'b1;
            special_result = {b_sign, b_exp, b_frac};
        end

        else if (b_zero) begin
            special_valid  = 1'b1;
            special_result = {a_sign, a_exp, a_frac};
        end
    end

endmodule