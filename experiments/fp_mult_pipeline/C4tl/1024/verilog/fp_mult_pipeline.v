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
localparam PROD_WIDTH = 48;

wire s1_sign_c;
wire [7:0] s1_exp_a_c, s1_exp_b_c;
wire [23:0] s1_mant_a_c, s1_mant_b_c;
wire s1_zero_a_c, s1_zero_b_c;
wire s1_inf_a_c, s1_inf_b_c;
wire s1_nan_a_c, s1_nan_b_c;
wire s1_sub_a_c, s1_sub_b_c;

fp_mult_unpack u_unpack (
    .a(a),
    .b(b),
    .sign(s1_sign_c),
    .exp_a(s1_exp_a_c),
    .exp_b(s1_exp_b_c),
    .mant_a(s1_mant_a_c),
    .mant_b(s1_mant_b_c),
    .zero_a(s1_zero_a_c),
    .zero_b(s1_zero_b_c),
    .inf_a(s1_inf_a_c),
    .inf_b(s1_inf_b_c),
    .nan_a(s1_nan_a_c),
    .nan_b(s1_nan_b_c),
    .sub_a(s1_sub_a_c),
    .sub_b(s1_sub_b_c)
);

reg s1_sign;
reg [7:0] s1_exp_a, s1_exp_b;
reg [23:0] s1_mant_a, s1_mant_b;
reg s1_zero_a, s1_zero_b, s1_inf_a, s1_inf_b, s1_nan_a, s1_nan_b, s1_sub_a, s1_sub_b;

wire [47:0] s2_product_c;
wire signed [10:0] s2_exp_c;

fp_mult_multiply_exp u_mult_exp (
    .exp_a(s1_exp_a),
    .exp_b(s1_exp_b),
    .mant_a(s1_mant_a),
    .mant_b(s1_mant_b),
    .sub_a(s1_sub_a),
    .sub_b(s1_sub_b),
    .product(s2_product_c),
    .exp_unbiased(s2_exp_c)
);

reg s2_sign;
reg [47:0] s2_product;
reg signed [10:0] s2_exp;
reg s2_zero_a, s2_zero_b, s2_inf_a, s2_inf_b, s2_nan_a, s2_nan_b;

wire [23:0] s3_mant_c;
wire signed [10:0] s3_exp_c;
wire s3_guard_c, s3_round_c, s3_sticky_c;

fp_mult_normalize u_normalize (
    .product(s2_product),
    .exp_in(s2_exp),
    .mantissa(s3_mant_c),
    .exp_out(s3_exp_c),
    .guard_bit(s3_guard_c),
    .round_bit(s3_round_c),
    .sticky_bit(s3_sticky_c)
);

reg s3_sign;
reg [23:0] s3_mant;
reg signed [10:0] s3_exp;
reg s3_guard, s3_round, s3_sticky;
reg s3_zero_a, s3_zero_b, s3_inf_a, s3_inf_b, s3_nan_a, s3_nan_b;

wire [23:0] s4_mant_c;
wire signed [10:0] s4_exp_c;

fp_mult_round_rne u_round (
    .mantissa_in(s3_mant),
    .exp_in(s3_exp),
    .guard_bit(s3_guard),
    .round_bit(s3_round),
    .sticky_bit(s3_sticky),
    .mantissa_out(s4_mant_c),
    .exp_out(s4_exp_c)
);

reg s4_sign;
reg [23:0] s4_mant;
reg signed [10:0] s4_exp;
reg s4_zero_a, s4_zero_b, s4_inf_a, s4_inf_b, s4_nan_a, s4_nan_b;

wire [31:0] s5_result_c;

fp_mult_pack u_pack (
    .sign(s4_sign),
    .mantissa(s4_mant),
    .exp_unbiased(s4_exp),
    .zero_a(s4_zero_a),
    .zero_b(s4_zero_b),
    .inf_a(s4_inf_a),
    .inf_b(s4_inf_b),
    .nan_a(s4_nan_a),
    .nan_b(s4_nan_b),
    .result(s5_result_c)
);

reg [31:0] result_r;
reg [LATENCY-1:0] valid_pipe;

assign result = result_r;
assign valid_out = valid_pipe[LATENCY-1];

always @(posedge clk) begin
    if (rst) begin
        valid_pipe <= {LATENCY{1'b0}};
        result_r <= 32'b0;

        s1_sign <= 1'b0;
        s1_exp_a <= 8'b0;
        s1_exp_b <= 8'b0;
        s1_mant_a <= 24'b0;
        s1_mant_b <= 24'b0;
        s1_zero_a <= 1'b0;
        s1_zero_b <= 1'b0;
        s1_inf_a <= 1'b0;
        s1_inf_b <= 1'b0;
        s1_nan_a <= 1'b0;
        s1_nan_b <= 1'b0;
        s1_sub_a <= 1'b0;
        s1_sub_b <= 1'b0;

        s2_sign <= 1'b0;
        s2_product <= 48'b0;
        s2_exp <= 11'sd0;
        s2_zero_a <= 1'b0;
        s2_zero_b <= 1'b0;
        s2_inf_a <= 1'b0;
        s2_inf_b <= 1'b0;
        s2_nan_a <= 1'b0;
        s2_nan_b <= 1'b0;

        s3_sign <= 1'b0;
        s3_mant <= 24'b0;
        s3_exp <= 11'sd0;
        s3_guard <= 1'b0;
        s3_round <= 1'b0;
        s3_sticky <= 1'b0;
        s3_zero_a <= 1'b0;
        s3_zero_b <= 1'b0;
        s3_inf_a <= 1'b0;
        s3_inf_b <= 1'b0;
        s3_nan_a <= 1'b0;
        s3_nan_b <= 1'b0;

        s4_sign <= 1'b0;
        s4_mant <= 24'b0;
        s4_exp <= 11'sd0;
        s4_zero_a <= 1'b0;
        s4_zero_b <= 1'b0;
        s4_inf_a <= 1'b0;
        s4_inf_b <= 1'b0;
        s4_nan_a <= 1'b0;
        s4_nan_b <= 1'b0;
    end else begin
        valid_pipe <= {valid_pipe[LATENCY-2:0], valid_in};

        s1_sign <= s1_sign_c;
        s1_exp_a <= s1_exp_a_c;
        s1_exp_b <= s1_exp_b_c;
        s1_mant_a <= s1_mant_a_c;
        s1_mant_b <= s1_mant_b_c;
        s1_zero_a <= s1_zero_a_c;
        s1_zero_b <= s1_zero_b_c;
        s1_inf_a <= s1_inf_a_c;
        s1_inf_b <= s1_inf_b_c;
        s1_nan_a <= s1_nan_a_c;
        s1_nan_b <= s1_nan_b_c;
        s1_sub_a <= s1_sub_a_c;
        s1_sub_b <= s1_sub_b_c;

        s2_sign <= s1_sign;
        s2_product <= s2_product_c;
        s2_exp <= s2_exp_c;
        s2_zero_a <= s1_zero_a;
        s2_zero_b <= s1_zero_b;
        s2_inf_a <= s1_inf_a;
        s2_inf_b <= s1_inf_b;
        s2_nan_a <= s1_nan_a;
        s2_nan_b <= s1_nan_b;

        s3_sign <= s2_sign;
        s3_mant <= s3_mant_c;
        s3_exp <= s3_exp_c;
        s3_guard <= s3_guard_c;
        s3_round <= s3_round_c;
        s3_sticky <= s3_sticky_c;
        s3_zero_a <= s2_zero_a;
        s3_zero_b <= s2_zero_b;
        s3_inf_a <= s2_inf_a;
        s3_inf_b <= s2_inf_b;
        s3_nan_a <= s2_nan_a;
        s3_nan_b <= s2_nan_b;

        s4_sign <= s3_sign;
        s4_mant <= s4_mant_c;
        s4_exp <= s4_exp_c;
        s4_zero_a <= s3_zero_a;
        s4_zero_b <= s3_zero_b;
        s4_inf_a <= s3_inf_a;
        s4_inf_b <= s3_inf_b;
        s4_nan_a <= s3_nan_a;
        s4_nan_b <= s3_nan_b;

        result_r <= s5_result_c;
    end
end

endmodule