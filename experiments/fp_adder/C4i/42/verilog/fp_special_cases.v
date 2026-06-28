`timescale 1ns/1ps

module fp_special_cases #(
    parameter integer WIDTH      = 32,
    parameter integer EXP_WIDTH  = 8,
    parameter integer MANT_WIDTH = 23
)(
    input  [WIDTH-1:0] a,
    input  [WIDTH-1:0] b,

    input              sign_a,
    input              sign_b,

    input              is_zero_a,
    input              is_zero_b,
    input              is_inf_a,
    input              is_inf_b,
    input              is_nan_a,
    input              is_nan_b,

    input      [2:0]   rnd_mode,

    output reg         special,
    output reg [WIDTH-1:0] result,
    output reg [2:0]   flags
);

    /*
     * Flag convention used by the surrounding design/testbench:
     *   flags[2] : invalid operation
     *   flags[1] : overflow
     *   flags[0] : underflow
     *
     * This module only raises invalid-operation for NaN handling and
     * opposite-signed infinity addition. Overflow/underflow are handled
     * by later arithmetic/rounding stages.
     */

    localparam [2:0] RND_TOWARD_NEG = 3'd3;

    wire [WIDTH-1:0] canonical_qnan;
    wire [WIDTH-1:0] pos_inf;
    wire [WIDTH-1:0] neg_inf;

    wire zero_sign;

    assign canonical_qnan = {
        1'b0,
        {EXP_WIDTH{1'b1}},
        1'b1,
        {(MANT_WIDTH-1){1'b0}}
    };

    assign pos_inf = {
        1'b0,
        {EXP_WIDTH{1'b1}},
        {MANT_WIDTH{1'b0}}
    };

    assign neg_inf = {
        1'b1,
        {EXP_WIDTH{1'b1}},
        {MANT_WIDTH{1'b0}}
    };

    /*
     * IEEE-style signed-zero result for exact zero + zero:
     *
     *   +0 + +0 => +0
     *   -0 + -0 => -0
     *   +0 + -0 => +0 normally
     *   +0 + -0 => -0 only for round toward -infinity
     *
     * The expression below preserves same-signed zeros and selects -0
     * for mixed signs only in round-toward-negative mode.
     */
    assign zero_sign =
        (rnd_mode == RND_TOWARD_NEG) ? (sign_a | sign_b) :
                                       (sign_a & sign_b);

    always @* begin
        special = 1'b0;
        result  = {WIDTH{1'b0}};
        flags   = 3'b000;

        /*
         * NaN propagation / invalid handling.
         *
         * The surrounding unpack stage supplies only a general is_nan flag,
         * not separate quiet/signaling NaN classification. For this design,
         * any NaN input produces a canonical quiet NaN and raises invalid,
         * matching the expected project flag behavior.
         */
        if (is_nan_a || is_nan_b) begin
            special = 1'b1;
            result  = canonical_qnan;
            flags   = 3'b100;
        end

        /*
         * +inf + -inf and -inf + +inf are invalid operations.
         */
        else if (is_inf_a && is_inf_b && (sign_a != sign_b)) begin
            special = 1'b1;
            result  = canonical_qnan;
            flags   = 3'b100;
        end

        /*
         * Same-signed infinities, or one finite operand plus infinity.
         */
        else if (is_inf_a) begin
            special = 1'b1;
            result  = sign_a ? neg_inf : pos_inf;
            flags   = 3'b000;
        end

        else if (is_inf_b) begin
            special = 1'b1;
            result  = sign_b ? neg_inf : pos_inf;
            flags   = 3'b000;
        end

        /*
         * Exact zero plus exact zero.
         */
        else if (is_zero_a && is_zero_b) begin
            special = 1'b1;
            result  = {zero_sign, {(WIDTH-1){1'b0}}};
            flags   = 3'b000;
        end

        /*
         * Exact zero plus non-special finite operand.
         * Return the non-zero operand unchanged, preserving sign and payload.
         */
        else if (is_zero_a) begin
            special = 1'b1;
            result  = b;
            flags   = 3'b000;
        end

        else if (is_zero_b) begin
            special = 1'b1;
            result  = a;
            flags   = 3'b000;
        end
    end

endmodule