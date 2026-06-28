`timescale 1ns/1ps

module floating_point_multiplier #(
    parameter EXP_WIDTH  = 8,
    parameter MANT_WIDTH = 23,
    parameter WIDTH      = 1 + EXP_WIDTH + MANT_WIDTH
)(
    input                    clk,
    input                    rst,
    input  [WIDTH-1:0]       a,
    input  [WIDTH-1:0]       b,
    input  [2:0]             rnd_mode,
    output reg [WIDTH-1:0]   product,
    output reg [2:0]         exception_flags
);

    wire a_sign, b_sign;
    wire [EXP_WIDTH-1:0]  a_exp, b_exp;
    wire [MANT_WIDTH-1:0] a_mant, b_mant;
    wire a_is_zero, a_is_denormal, a_is_inf, a_is_nan;
    wire b_is_zero, b_is_denormal, b_is_inf, b_is_nan;
    wire [MANT_WIDTH:0] a_sig, b_sig;
    wire signed [EXP_WIDTH+1:0] a_unbiased_exp, b_unbiased_exp;

    wire result_sign;
    assign result_sign = a_sign ^ b_sign;

    fp_multiplier_unpack #(
        .EXP_WIDTH(EXP_WIDTH),
        .MANT_WIDTH(MANT_WIDTH),
        .WIDTH(WIDTH)
    ) u_unpack_a (
        .operand(a),
        .sign(a_sign),
        .exponent(a_exp),
        .mantissa(a_mant),
        .is_zero(a_is_zero),
        .is_denormal(a_is_denormal),
        .is_inf(a_is_inf),
        .is_nan(a_is_nan),
        .significand(a_sig),
        .unbiased_exp(a_unbiased_exp)
    );

    fp_multiplier_unpack #(
        .EXP_WIDTH(EXP_WIDTH),
        .MANT_WIDTH(MANT_WIDTH),
        .WIDTH(WIDTH)
    ) u_unpack_b (
        .operand(b),
        .sign(b_sign),
        .exponent(b_exp),
        .mantissa(b_mant),
        .is_zero(b_is_zero),
        .is_denormal(b_is_denormal),
        .is_inf(b_is_inf),
        .is_nan(b_is_nan),
        .significand(b_sig),
        .unbiased_exp(b_unbiased_exp)
    );

    wire special_valid;
    wire [WIDTH-1:0] special_result;
    wire [2:0] special_flags;

    fp_multiplier_special_cases #(
        .EXP_WIDTH(EXP_WIDTH),
        .MANT_WIDTH(MANT_WIDTH),
        .WIDTH(WIDTH)
    ) u_special (
        .sign(result_sign),
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

    wire [2*(MANT_WIDTH+1)-1:0] significand_product;
    wire signed [EXP_WIDTH+2:0] exponent_sum;

    fp_multiplier_significand_product #(
        .EXP_WIDTH(EXP_WIDTH),
        .MANT_WIDTH(MANT_WIDTH)
    ) u_sig_product (
        .sig_a(a_sig),
        .sig_b(b_sig),
        .exp_a(a_unbiased_exp),
        .exp_b(b_unbiased_exp),
        .product(significand_product),
        .exponent_sum(exponent_sum)
    );

    wire [WIDTH-1:0] normal_result;
    wire [2:0] normal_flags;

    fp_multiplier_normalize_round_pack #(
        .EXP_WIDTH(EXP_WIDTH),
        .MANT_WIDTH(MANT_WIDTH),
        .WIDTH(WIDTH)
    ) u_norm_round_pack (
        .sign(result_sign),
        .significand_product(significand_product),
        .exponent_sum(exponent_sum),
        .rnd_mode(rnd_mode),
        .packed_result(normal_result),
        .flags(normal_flags)
    );

    wire [WIDTH-1:0] final_product;
    wire [2:0] final_flags;

    assign final_product = special_valid ? special_result : normal_result;
    assign final_flags   = special_valid ? special_flags  : normal_flags;

    always @(*) begin
        if (rst) begin
            product         = {WIDTH{1'b0}};
            exception_flags = 3'b000;
        end else begin
            product         = final_product;
            exception_flags = final_flags;
        end
    end

endmodule