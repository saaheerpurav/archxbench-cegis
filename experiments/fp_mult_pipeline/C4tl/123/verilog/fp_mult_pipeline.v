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

wire        u_sign;
wire signed [10:0] u_exp_a;
wire signed [10:0] u_exp_b;
wire [23:0] u_mant_a;
wire [23:0] u_mant_b;
wire        u_a_zero, u_b_zero;
wire        u_a_inf,  u_b_inf;
wire        u_a_nan,  u_b_nan;

fp_mult_unpack u_unpack (
    .a(a),
    .b(b),
    .sign(u_sign),
    .exp_a_unbiased(u_exp_a),
    .exp_b_unbiased(u_exp_b),
    .mant_a(u_mant_a),
    .mant_b(u_mant_b),
    .a_zero(u_a_zero),
    .b_zero(u_b_zero),
    .a_inf(u_a_inf),
    .b_inf(u_b_inf),
    .a_nan(u_a_nan),
    .b_nan(u_b_nan)
);

reg        s1_valid;
reg        s1_sign;
reg signed [10:0] s1_exp_a, s1_exp_b;
reg [23:0] s1_mant_a, s1_mant_b;
reg        s1_a_zero, s1_b_zero, s1_a_inf, s1_b_inf, s1_a_nan, s1_b_nan;

wire signed [10:0] c_exp_sum;
wire [47:0]        c_product;

fp_mult_exp_product u_exp_product (
    .exp_a_unbiased(s1_exp_a),
    .exp_b_unbiased(s1_exp_b),
    .mant_a(s1_mant_a),
    .mant_b(s1_mant_b),
    .exp_sum_unbiased(c_exp_sum),
    .product(c_product)
);

reg        s2_valid;
reg        s2_sign;
reg signed [10:0] s2_exp_sum;
reg [47:0] s2_product;
reg        s2_a_zero, s2_b_zero, s2_a_inf, s2_b_inf, s2_a_nan, s2_b_nan;

wire signed [10:0] n_exp;
wire [23:0]        n_sig;
wire               n_guard, n_round, n_sticky;

fp_mult_normalize u_normalize (
    .exp_sum_unbiased(s2_exp_sum),
    .product(s2_product),
    .norm_exp_unbiased(n_exp),
    .norm_sig(n_sig),
    .guard_bit(n_guard),
    .round_bit(n_round),
    .sticky_bit(n_sticky)
);

reg        s3_valid;
reg        s3_sign;
reg signed [10:0] s3_exp;
reg [23:0] s3_sig;
reg        s3_guard, s3_round, s3_sticky;
reg        s3_a_zero, s3_b_zero, s3_a_inf, s3_b_inf, s3_a_nan, s3_b_nan;

wire signed [10:0] r_exp;
wire [23:0]        r_sig;

fp_mult_round u_round (
    .norm_exp_unbiased(s3_exp),
    .norm_sig(s3_sig),
    .guard_bit(s3_guard),
    .round_bit(s3_round),
    .sticky_bit(s3_sticky),
    .rounded_exp_unbiased(r_exp),
    .rounded_sig(r_sig)
);

reg        s4_valid;
reg        s4_sign;
reg signed [10:0] s4_exp;
reg [23:0] s4_sig;
reg        s4_a_zero, s4_b_zero, s4_a_inf, s4_b_inf, s4_a_nan, s4_b_nan;

wire [31:0] packed_result;

fp_mult_pack u_pack (
    .sign(s4_sign),
    .exp_unbiased(s4_exp),
    .sig(s4_sig),
    .a_zero(s4_a_zero),
    .b_zero(s4_b_zero),
    .a_inf(s4_a_inf),
    .b_inf(s4_b_inf),
    .a_nan(s4_a_nan),
    .b_nan(s4_b_nan),
    .result(packed_result)
);

reg        s5_valid;
reg [31:0] s5_result;

assign valid_out = s5_valid;
assign result = s5_result;

always @(posedge clk) begin
    if (rst) begin
        s1_valid <= 1'b0;
        s2_valid <= 1'b0;
        s3_valid <= 1'b0;
        s4_valid <= 1'b0;
        s5_valid <= 1'b0;

        s1_sign <= 1'b0;
        s1_exp_a <= 11'sd0;
        s1_exp_b <= 11'sd0;
        s1_mant_a <= 24'd0;
        s1_mant_b <= 24'd0;
        s1_a_zero <= 1'b0;
        s1_b_zero <= 1'b0;
        s1_a_inf <= 1'b0;
        s1_b_inf <= 1'b0;
        s1_a_nan <= 1'b0;
        s1_b_nan <= 1'b0;

        s2_sign <= 1'b0;
        s2_exp_sum <= 11'sd0;
        s2_product <= 48'd0;
        s2_a_zero <= 1'b0;
        s2_b_zero <= 1'b0;
        s2_a_inf <= 1'b0;
        s2_b_inf <= 1'b0;
        s2_a_nan <= 1'b0;
        s2_b_nan <= 1'b0;

        s3_sign <= 1'b0;
        s3_exp <= 11'sd0;
        s3_sig <= 24'd0;
        s3_guard <= 1'b0;
        s3_round <= 1'b0;
        s3_sticky <= 1'b0;
        s3_a_zero <= 1'b0;
        s3_b_zero <= 1'b0;
        s3_a_inf <= 1'b0;
        s3_b_inf <= 1'b0;
        s3_a_nan <= 1'b0;
        s3_b_nan <= 1'b0;

        s4_sign <= 1'b0;
        s4_exp <= 11'sd0;
        s4_sig <= 24'd0;
        s4_a_zero <= 1'b0;
        s4_b_zero <= 1'b0;
        s4_a_inf <= 1'b0;
        s4_b_inf <= 1'b0;
        s4_a_nan <= 1'b0;
        s4_b_nan <= 1'b0;

        s5_result <= 32'd0;
    end else begin
        s1_valid <= valid_in;
        s1_sign <= u_sign;
        s1_exp_a <= u_exp_a;
        s1_exp_b <= u_exp_b;
        s1_mant_a <= u_mant_a;
        s1_mant_b <= u_mant_b;
        s1_a_zero <= u_a_zero;
        s1_b_zero <= u_b_zero;
        s1_a_inf <= u_a_inf;
        s1_b_inf <= u_b_inf;
        s1_a_nan <= u_a_nan;
        s1_b_nan <= u_b_nan;

        s2_valid <= s1_valid;
        s2_sign <= s1_sign;
        s2_exp_sum <= c_exp_sum;
        s2_product <= c_product;
        s2_a_zero <= s1_a_zero;
        s2_b_zero <= s1_b_zero;
        s2_a_inf <= s1_a_inf;
        s2_b_inf <= s1_b_inf;
        s2_a_nan <= s1_a_nan;
        s2_b_nan <= s1_b_nan;

        s3_valid <= s2_valid;
        s3_sign <= s2_sign;
        s3_exp <= n_exp;
        s3_sig <= n_sig;
        s3_guard <= n_guard;
        s3_round <= n_round;
        s3_sticky <= n_sticky;
        s3_a_zero <= s2_a_zero;
        s3_b_zero <= s2_b_zero;
        s3_a_inf <= s2_a_inf;
        s3_b_inf <= s2_b_inf;
        s3_a_nan <= s2_a_nan;
        s3_b_nan <= s2_b_nan;

        s4_valid <= s3_valid;
        s4_sign <= s3_sign;
        s4_exp <= r_exp;
        s4_sig <= r_sig;
        s4_a_zero <= s3_a_zero;
        s4_b_zero <= s3_b_zero;
        s4_a_inf <= s3_a_inf;
        s4_b_inf <= s3_b_inf;
        s4_a_nan <= s3_a_nan;
        s4_b_nan <= s3_b_nan;

        s5_valid <= s4_valid;
        if (s4_valid)
            s5_result <= packed_result;
    end
end

endmodule