`timescale 1ns/1ps

module fp_mult_pipeline #(
    parameter LATENCY = 5
) (
    input clk,
    input rst,
    input [31:0] a,
    input [31:0] b,
    input valid_in,
    output [31:0] result,
    output valid_out
);

    localparam EXP_WIDTH  = 8;
    localparam MANT_WIDTH = 23;
    localparam SIG_WIDTH  = MANT_WIDTH + 1;
    localparam PROD_WIDTH = 2 * SIG_WIDTH;

    /*
     * Combinational Stage 1: input unpack
     */
    wire        a_sign_w;
    wire [7:0]  a_exp_w;
    wire [23:0] a_mant_w;
    wire        a_zero_w;
    wire        a_inf_w;
    wire        a_nan_w;
    wire        a_subnormal_w;

    wire        b_sign_w;
    wire [7:0]  b_exp_w;
    wire [23:0] b_mant_w;
    wire        b_zero_w;
    wire        b_inf_w;
    wire        b_nan_w;
    wire        b_subnormal_w;

    fp_mult_unpack u_unpack_a (
        .operand(a),
        .sign(a_sign_w),
        .exp(a_exp_w),
        .mant(a_mant_w),
        .is_zero(a_zero_w),
        .is_inf(a_inf_w),
        .is_nan(a_nan_w),
        .is_subnormal(a_subnormal_w)
    );

    fp_mult_unpack u_unpack_b (
        .operand(b),
        .sign(b_sign_w),
        .exp(b_exp_w),
        .mant(b_mant_w),
        .is_zero(b_zero_w),
        .is_inf(b_inf_w),
        .is_nan(b_nan_w),
        .is_subnormal(b_subnormal_w)
    );

    /*
     * Pipeline stage 1 registers
     */
    reg        s1_sign;
    reg [7:0]  s1_exp_a;
    reg [7:0]  s1_exp_b;
    reg [23:0] s1_mant_a;
    reg [23:0] s1_mant_b;
    reg        s1_a_zero;
    reg        s1_b_zero;
    reg        s1_a_inf;
    reg        s1_b_inf;
    reg        s1_a_nan;
    reg        s1_b_nan;
    reg        s1_a_subnormal;
    reg        s1_b_subnormal;

    /*
     * Combinational Stage 2: significand multiply and exponent add
     */
    wire [47:0]      s2_product_w;
    wire signed [10:0] s2_exp_sum_w;

    fp_mult_mul_exp u_mul_exp (
        .exp_a(s1_exp_a),
        .exp_b(s1_exp_b),
        .mant_a(s1_mant_a),
        .mant_b(s1_mant_b),
        .a_subnormal(s1_a_subnormal),
        .b_subnormal(s1_b_subnormal),
        .product(s2_product_w),
        .exp_sum(s2_exp_sum_w)
    );

    /*
     * Pipeline stage 2 registers
     */
    reg          s2_sign;
    reg [47:0]   s2_product;
    reg signed [10:0] s2_exp_sum;
    reg          s2_a_zero;
    reg          s2_b_zero;
    reg          s2_a_inf;
    reg          s2_b_inf;
    reg          s2_a_nan;
    reg          s2_b_nan;

    /*
     * Combinational Stage 3/4: normalize and round-to-nearest-even
     */
    wire signed [10:0] s3_exp_norm_w;
    wire [22:0]        s3_frac_norm_w;
    wire               s3_overflow_w;
    wire               s3_underflow_w;

    fp_mult_norm_round u_norm_round (
        .product(s2_product),
        .exp_in(s2_exp_sum),
        .exp_out(s3_exp_norm_w),
        .frac_out(s3_frac_norm_w),
        .overflow(s3_overflow_w),
        .underflow(s3_underflow_w)
    );

    /*
     * Pipeline stage 3 registers
     */
    reg          s3_sign;
    reg signed [10:0] s3_exp_norm;
    reg [22:0]   s3_frac_norm;
    reg          s3_a_zero;
    reg          s3_b_zero;
    reg          s3_a_inf;
    reg          s3_b_inf;
    reg          s3_a_nan;
    reg          s3_b_nan;

    /*
     * Combinational Stage 5: special-case priority and IEEE pack
     */
    wire [31:0] s4_packed_w;

    fp_mult_pack_special u_pack_special (
        .sign(s3_sign),
        .a_zero(s3_a_zero),
        .b_zero(s3_b_zero),
        .a_inf(s3_a_inf),
        .b_inf(s3_b_inf),
        .a_nan(s3_a_nan),
        .b_nan(s3_b_nan),
        .exp_in(s3_exp_norm),
        .frac_in(s3_frac_norm),
        .result(s4_packed_w)
    );

    /*
     * Pipeline stage 4 and stage 5/output registers
     */
    reg [31:0] s4_result;
    reg [31:0] result_reg;

    /*
     * Valid pipeline.
     * Default LATENCY is 5, matching the five registered data stages.
     */
    reg [LATENCY-1:0] valid_pipe;
    integer i;

    assign result = result_reg;
    assign valid_out = valid_pipe[LATENCY-1];

    always @(posedge clk) begin
        if (rst) begin
            valid_pipe <= {LATENCY{1'b0}};

            s1_sign        <= 1'b0;
            s1_exp_a       <= 8'd0;
            s1_exp_b       <= 8'd0;
            s1_mant_a      <= 24'd0;
            s1_mant_b      <= 24'd0;
            s1_a_zero      <= 1'b0;
            s1_b_zero      <= 1'b0;
            s1_a_inf       <= 1'b0;
            s1_b_inf       <= 1'b0;
            s1_a_nan       <= 1'b0;
            s1_b_nan       <= 1'b0;
            s1_a_subnormal <= 1'b0;
            s1_b_subnormal <= 1'b0;

            s2_sign        <= 1'b0;
            s2_product     <= 48'd0;
            s2_exp_sum     <= 11'sd0;
            s2_a_zero      <= 1'b0;
            s2_b_zero      <= 1'b0;
            s2_a_inf       <= 1'b0;
            s2_b_inf       <= 1'b0;
            s2_a_nan       <= 1'b0;
            s2_b_nan       <= 1'b0;

            s3_sign        <= 1'b0;
            s3_exp_norm    <= 11'sd0;
            s3_frac_norm   <= 23'd0;
            s3_a_zero      <= 1'b0;
            s3_b_zero      <= 1'b0;
            s3_a_inf       <= 1'b0;
            s3_b_inf       <= 1'b0;
            s3_a_nan       <= 1'b0;
            s3_b_nan       <= 1'b0;

            s4_result      <= 32'd0;
            result_reg     <= 32'd0;
        end else begin
            valid_pipe[0] <= valid_in;
            for (i = 1; i < LATENCY; i = i + 1) begin
                valid_pipe[i] <= valid_pipe[i-1];
            end

            /*
             * Stage 1 register load
             */
            s1_sign        <= a_sign_w ^ b_sign_w;
            s1_exp_a       <= a_exp_w;
            s1_exp_b       <= b_exp_w;
            s1_mant_a      <= a_mant_w;
            s1_mant_b      <= b_mant_w;
            s1_a_zero      <= a_zero_w;
            s1_b_zero      <= b_zero_w;
            s1_a_inf       <= a_inf_w;
            s1_b_inf       <= b_inf_w;
            s1_a_nan       <= a_nan_w;
            s1_b_nan       <= b_nan_w;
            s1_a_subnormal <= a_subnormal_w;
            s1_b_subnormal <= b_subnormal_w;

            /*
             * Stage 2 register load
             */
            s2_sign        <= s1_sign;
            s2_product     <= s2_product_w;
            s2_exp_sum     <= s2_exp_sum_w;
            s2_a_zero      <= s1_a_zero;
            s2_b_zero      <= s1_b_zero;
            s2_a_inf       <= s1_a_inf;
            s2_b_inf       <= s1_b_inf;
            s2_a_nan       <= s1_a_nan;
            s2_b_nan       <= s1_b_nan;

            /*
             * Stage 3 register load
             */
            s3_sign        <= s2_sign;
            s3_exp_norm    <= s3_exp_norm_w;
            s3_frac_norm   <= s3_frac_norm_w;
            s3_a_zero      <= s2_a_zero;
            s3_b_zero      <= s2_b_zero;
            s3_a_inf       <= s2_a_inf;
            s3_b_inf       <= s2_b_inf;
            s3_a_nan       <= s2_a_nan;
            s3_b_nan       <= s2_b_nan;

            /*
             * Stage 4 and stage 5/output register load
             */
            s4_result      <= s4_packed_w;
            result_reg     <= s4_result;
        end
    end

endmodule