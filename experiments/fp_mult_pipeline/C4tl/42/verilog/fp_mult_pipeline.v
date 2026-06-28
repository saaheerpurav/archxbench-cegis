`timescale 1ns/1ps

module fp_mult_pipeline #(
    parameter LATENCY = 5
) (
    input clk,
    input rst,
    input [31:0] a,
    input [31:0] b,
    input valid_in,
    output reg [31:0] result,
    output reg valid_out
);

    /*
     * Stage 0 combinational unpack and early special-case classification
     */
    wire        a_sign_w;
    wire [7:0]  a_exp_w;
    wire [22:0] a_frac_w;
    wire [23:0] a_sig_w;
    wire signed [12:0] a_unbiased_exp_w;
    wire        a_zero_w;
    wire        a_subnormal_w;
    wire        a_inf_w;
    wire        a_nan_w;

    wire        b_sign_w;
    wire [7:0]  b_exp_w;
    wire [22:0] b_frac_w;
    wire [23:0] b_sig_w;
    wire signed [12:0] b_unbiased_exp_w;
    wire        b_zero_w;
    wire        b_subnormal_w;
    wire        b_inf_w;
    wire        b_nan_w;

    wire special_sign_w;
    wire special_nan_w;
    wire special_inf_w;
    wire special_zero_w;

    fp_unpack u_unpack_a (
        .x(a),
        .sign(a_sign_w),
        . exponent(a_exp_w),
        .fraction(a_frac_w),
        .significand(a_sig_w),
        .unbiased_exponent(a_unbiased_exp_w),
        .is_zero(a_zero_w),
        .is_subnormal(a_subnormal_w),
        .is_inf(a_inf_w),
        .is_nan(a_nan_w)
    );

    fp_unpack u_unpack_b (
        .x(b),
        .sign(b_sign_w),
        .exponent(b_exp_w),
        .fraction(b_frac_w),
        .significand(b_sig_w),
        .unbiased_exponent(b_unbiased_exp_w),
        .is_zero(b_zero_w),
        .is_subnormal(b_subnormal_w),
        .is_inf(b_inf_w),
        .is_nan(b_nan_w)
    );

    fp_special_cases u_special_cases (
        .a_sign(a_sign_w),
        .b_sign(b_sign_w),
        .a_zero(a_zero_w),
        .b_zero(b_zero_w),
        .a_inf(a_inf_w),
        .b_inf(b_inf_w),
        .a_nan(a_nan_w),
        .b_nan(b_nan_w),
        .result_sign(special_sign_w),
        .result_is_nan(special_nan_w),
        .result_is_inf(special_inf_w),
        .result_is_zero(special_zero_w)
    );

    /*
     * Stage 1 registers: unpacked operands and special flags
     */
    reg s1_valid;
    reg s1_sign;
    reg s1_is_nan;
    reg s1_is_inf;
    reg s1_is_zero;
    reg [23:0] s1_sig_a;
    reg [23:0] s1_sig_b;
    reg signed [12:0] s1_exp_a;
    reg signed [12:0] s1_exp_b;

    /*
     * Stage 2 combinational: significand multiply and exponent addition
     */
    wire [47:0] product_w;
    wire signed [12:0] exp_sum_w;

    fp_mul_exp u_mul_exp (
        .a_significand(s1_sig_a),
        .b_significand(s1_sig_b),
        .a_exponent(s1_exp_a),
        .b_exponent(s1_exp_b),
        .product(product_w),
        .exponent_sum(exp_sum_w)
    );

    /*
     * Stage 2 registers
     */
    reg s2_valid;
    reg s2_sign;
    reg s2_is_nan;
    reg s2_is_inf;
    reg s2_is_zero;
    reg [47:0] s2_product;
    reg signed [12:0] s2_exp_sum;

    /*
     * Stage 3 combinational: normalization
     */
    wire [23:0] norm_sig_w;
    wire signed [12:0] norm_exp_w;
    wire guard_w;
    wire round_w;
    wire sticky_w;

    fp_normalize u_normalize (
        .product(s2_product),
        .exponent_sum(s2_exp_sum),
        .significand_norm(norm_sig_w),
        .exponent_norm(norm_exp_w),
        .guard_bit(guard_w),
        .round_bit(round_w),
        .sticky_bit(sticky_w)
    );

    /*
     * Stage 3 registers
     */
    reg s3_valid;
    reg s3_sign;
    reg s3_is_nan;
    reg s3_is_inf;
    reg s3_is_zero;
    reg [23:0] s3_sig_norm;
    reg signed [12:0] s3_exp_norm;
    reg s3_guard;
    reg s3_round;
    reg s3_sticky;

    /*
     * Stage 4 combinational: round-to-nearest-even
     */
    wire [23:0] rounded_sig_w;
    wire signed [12:0] rounded_exp_w;

    fp_round_nearest_even u_round (
        .significand_norm(s3_sig_norm),
        .exponent_norm(s3_exp_norm),
        .guard_bit(s3_guard),
        .round_bit(s3_round),
        .sticky_bit(s3_sticky),
        .significand_rounded(rounded_sig_w),
        .exponent_rounded(rounded_exp_w)
    );

    /*
     * Stage 4 registers
     */
    reg s4_valid;
    reg s4_sign;
    reg s4_is_nan;
    reg s4_is_inf;
    reg s4_is_zero;
    reg [23:0] s4_sig_rounded;
    reg signed [12:0] s4_exp_rounded;

    /*
     * Stage 5 combinational pack
     */
    wire [31:0] packed_result_w;

    fp_pack_result u_pack (
        .sign(s4_sign),
        .is_nan(s4_is_nan),
        .is_inf(s4_is_inf),
        .is_zero(s4_is_zero),
        .significand_rounded(s4_sig_rounded),
        .exponent_rounded(s4_exp_rounded),
        .result(packed_result_w)
    );

    always @(posedge clk) begin
        if (rst) begin
            s1_valid <= 1'b0;
            s1_sign <= 1'b0;
            s1_is_nan <= 1'b0;
            s1_is_inf <= 1'b0;
            s1_is_zero <= 1'b0;
            s1_sig_a <= 24'd0;
            s1_sig_b <= 24'd0;
            s1_exp_a <= 13'sd0;
            s1_exp_b <= 13'sd0;

            s2_valid <= 1'b0;
            s2_sign <= 1'b0;
            s2_is_nan <= 1'b0;
            s2_is_inf <= 1'b0;
            s2_is_zero <= 1'b0;
            s2_product <= 48'd0;
            s2_exp_sum <= 13'sd0;

            s3_valid <= 1'b0;
            s3_sign <= 1'b0;
            s3_is_nan <= 1'b0;
            s3_is_inf <= 1'b0;
            s3_is_zero <= 1'b0;
            s3_sig_norm <= 24'd0;
            s3_exp_norm <= 13'sd0;
            s3_guard <= 1'b0;
            s3_round <= 1'b0;
            s3_sticky <= 1'b0;

            s4_valid <= 1'b0;
            s4_sign <= 1'b0;
            s4_is_nan <= 1'b0;
            s4_is_inf <= 1'b0;
            s4_is_zero <= 1'b0;
            s4_sig_rounded <= 24'd0;
            s4_exp_rounded <= 13'sd0;

            result <= 32'd0;
            valid_out <= 1'b0;
        end else begin
            /*
             * Stage 1 capture
             */
            s1_valid <= valid_in;
            s1_sign <= special_sign_w;
            s1_is_nan <= special_nan_w;
            s1_is_inf <= special_inf_w;
            s1_is_zero <= special_zero_w;
            s1_sig_a <= a_sig_w;
            s1_sig_b <= b_sig_w;
            s1_exp_a <= a_unbiased_exp_w;
            s1_exp_b <= b_unbiased_exp_w;

            /*
             * Stage 2 capture
             */
            s2_valid <= s1_valid;
            s2_sign <= s1_sign;
            s2_is_nan <= s1_is_nan;
            s2_is_inf <= s1_is_inf;
            s2_is_zero <= s1_is_zero;
            s2_product <= product_w;
            s2_exp_sum <= exp_sum_w;

            /*
             * Stage 3 capture
             */
            s3_valid <= s2_valid;
            s3_sign <= s2_sign;
            s3_is_nan <= s2_is_nan;
            s3_is_inf <= s2_is_inf;
            s3_is_zero <= s2_is_zero;
            s3_sig_norm <= norm_sig_w;
            s3_exp_norm <= norm_exp_w;
            s3_guard <= guard_w;
            s3_round <= round_w;
            s3_sticky <= sticky_w;

            /*
             * Stage 4 capture
             */
            s4_valid <= s3_valid;
            s4_sign <= s3_sign;
            s4_is_nan <= s3_is_nan;
            s4_is_inf <= s3_is_inf;
            s4_is_zero <= s3_is_zero;
            s4_sig_rounded <= rounded_sig_w;
            s4_exp_rounded <= rounded_exp_w;

            /*
             * Stage 5 output capture.
             * Hold result when invalid so a consumer/testbench may sample it
             * on the clock following valid_out.
             */
            valid_out <= s4_valid;
            if (s4_valid) begin
                result <= packed_result_w;
            end
        end
    end

endmodule