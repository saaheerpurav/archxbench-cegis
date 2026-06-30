`timescale 1ns/1ps

module floating_point_multiplier #(
    parameter EXP_WIDTH  = 8,
    parameter MANT_WIDTH = 23,
    parameter WIDTH      = 1 + EXP_WIDTH + MANT_WIDTH
)(
    input clk,
    input rst,
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    input [2:0] rnd_mode,
    output reg [WIDTH-1:0] product,
    output reg [2:0] exception_flags
);

    localparam SIG_WIDTH = MANT_WIDTH + 1;
    localparam PROD_WIDTH = 2 * SIG_WIDTH;

    wire sign_a, sign_b;
    wire [EXP_WIDTH-1:0] exp_a, exp_b;
    wire [MANT_WIDTH-1:0] mant_a, mant_b;
    wire [SIG_WIDTH-1:0] sig_a, sig_b;
    wire signed [EXP_WIDTH+1:0] unbiased_exp_a, unbiased_exp_b;
    wire is_zero_a, is_zero_b, is_inf_a, is_inf_b, is_nan_a, is_nan_b, is_denorm_a, is_denorm_b;

    wire special_valid;
    wire [WIDTH-1:0] special_result;
    wire [2:0] special_exception_flags;

    wire result_sign;
    wire signed [EXP_WIDTH+2:0] exp_sum;
    wire [PROD_WIDTH-1:0] sig_product;

    wire [WIDTH-1:0] normal_result;
    wire [2:0] normal_exception_flags;

    fp_unpack #(
        .EXP_WIDTH(EXP_WIDTH),
        .MANT_WIDTH(MANT_WIDTH)
    ) unpack_a (
        .operand(a),
        .sign(sign_a),
        .exponent(exp_a),
        .mantissa(mant_a),
        .significand(sig_a),
        .unbiased_exponent(unbiased_exp_a),
        .is_zero(is_zero_a),
        .is_inf(is_inf_a),
        .is_nan(is_nan_a),
        .is_denorm(is_denorm_a)
    );

    fp_unpack #(
        .EXP_WIDTH(EXP_WIDTH),
        .MANT_WIDTH(MANT_WIDTH)
    ) unpack_b (
        .operand(b),
        .sign(sign_b),
        .exponent(exp_b),
        .mantissa(mant_b),
        .significand(sig_b),
        .unbiased_exponent(unbiased_exp_b),
        .is_zero(is_zero_b),
        .is_inf(is_inf_b),
        .is_nan(is_nan_b),
        .is_denorm(is_denorm_b)
    );

    fp_special_cases #(
        .EXP_WIDTH(EXP_WIDTH),
        .MANT_WIDTH(MANT_WIDTH)
    ) special_cases (
        .sign_a(sign_a),
        .sign_b(sign_b),
        .is_zero_a(is_zero_a),
        .is_zero_b(is_zero_b),
        .is_inf_a(is_inf_a),
        .is_inf_b(is_inf_b),
        .is_nan_a(is_nan_a),
        .is_nan_b(is_nan_b),
        .special_valid(special_valid),
        .special_result(special_result),
        .exception_flags(special_exception_flags)
    );

    fp_multiply_core #(
        .EXP_WIDTH(EXP_WIDTH),
        .MANT_WIDTH(MANT_WIDTH)
    ) multiply_core (
        .sign_a(sign_a),
        .sign_b(sign_b),
        .unbiased_exp_a(unbiased_exp_a),
        .unbiased_exp_b(unbiased_exp_b),
        .sig_a(sig_a),
        .sig_b(sig_b),
        .result_sign(result_sign),
        .exp_sum(exp_sum),
        .sig_product(sig_product)
    );

    fp_normalize_round #(
        .EXP_WIDTH(EXP_WIDTH),
        .MANT_WIDTH(MANT_WIDTH)
    ) normalize_round (
        .result_sign(result_sign),
        .exp_sum(exp_sum),
        .sig_product(sig_product),
        .rnd_mode(rnd_mode),
        .result(normal_result),
        .exception_flags(normal_exception_flags)
    );

    always @(*) begin
        if (rst) begin
            product = {WIDTH{1'b0}};
            exception_flags = 3'b000;
        end else if (special_valid) begin
            product = special_result;
            exception_flags = special_exception_flags;
        end else begin
            product = normal_result;
            exception_flags = normal_exception_flags;
        end
    end

endmodule