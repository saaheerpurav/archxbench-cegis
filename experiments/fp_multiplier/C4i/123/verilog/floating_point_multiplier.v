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

    wire sign_a, sign_b;
    wire [EXP_WIDTH-1:0] exp_a, exp_b;
    wire [MANT_WIDTH-1:0] mant_a, mant_b;
    wire a_is_zero, a_is_inf, a_is_nan;
    wire b_is_zero, b_is_inf, b_is_nan;

    wire special_valid;
    wire [WIDTH-1:0] special_result;
    wire [2:0] special_flags;

    wire result_sign;
    wire signed [EXP_WIDTH+2:0] raw_exp;
    wire [(2*(MANT_WIDTH+1))-1:0] sig_product;

    wire [WIDTH-1:0] normal_result;
    wire [2:0] normal_flags;

    fp_unpack_classify #(
        .EXP_WIDTH(EXP_WIDTH),
        .MANT_WIDTH(MANT_WIDTH),
        .WIDTH(WIDTH)
    ) unpack_a (
        .operand(a),
        .sign(sign_a),
        .exponent(exp_a),
        .mantissa(mant_a),
        .is_zero(a_is_zero),
        .is_inf(a_is_inf),
        .is_nan(a_is_nan)
    );

    fp_unpack_classify #(
        .EXP_WIDTH(EXP_WIDTH),
        .MANT_WIDTH(MANT_WIDTH),
        .WIDTH(WIDTH)
    ) unpack_b (
        .operand(b),
        .sign(sign_b),
        .exponent(exp_b),
        .mantissa(mant_b),
        .is_zero(b_is_zero),
        .is_inf(b_is_inf),
        .is_nan(b_is_nan)
    );

    fp_special_cases #(
        .EXP_WIDTH(EXP_WIDTH),
        .MANT_WIDTH(MANT_WIDTH),
        .WIDTH(WIDTH)
    ) special_cases (
        .sign_a(sign_a),
        .sign_b(sign_b),
        .a_is_zero(a_is_zero),
        .a_is_inf(a_is_inf),
        .a_is_nan(a_is_nan),
        .b_is_zero(b_is_zero),
        .b_is_inf(b_is_inf),
        .b_is_nan(b_is_nan),
        .special_valid(special_valid),
        .special_result(special_result),
        .special_flags(special_flags)
    );

    fp_significand_multiply #(
        .EXP_WIDTH(EXP_WIDTH),
        .MANT_WIDTH(MANT_WIDTH)
    ) multiply_core (
        .sign_a(sign_a),
        .sign_b(sign_b),
        .exp_a(exp_a),
        .exp_b(exp_b),
        .mant_a(mant_a),
        .mant_b(mant_b),
        .result_sign(result_sign),
        .raw_exp(raw_exp),
        .sig_product(sig_product)
    );

    fp_normalize_round_pack #(
        .EXP_WIDTH(EXP_WIDTH),
        .MANT_WIDTH(MANT_WIDTH),
        .WIDTH(WIDTH)
    ) normalize_pack (
        .result_sign(result_sign),
        .raw_exp(raw_exp),
        .sig_product(sig_product),
        .rnd_mode(rnd_mode),
        .result(normal_result),
        .flags(normal_flags)
    );

    always @(*) begin
        if (rst) begin
            product = {WIDTH{1'b0}};
            exception_flags = 3'b000;
        end else if (special_valid) begin
            product = special_result;
            exception_flags = special_flags;
        end else begin
            product = normal_result;
            exception_flags = normal_flags;
        end
    end

endmodule