`timescale 1ns/1ps

module floating_point_adder #(
    parameter integer WIDTH = 32,
    parameter integer EXP_WIDTH = (WIDTH == 64) ? 11 : 8,
    parameter integer MANT_WIDTH = WIDTH - EXP_WIDTH - 1
)(
    input clk,
    input rst,
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    input [2:0] rnd_mode,
    output reg [WIDTH-1:0] sum,
    output reg [2:0] exception_flags
);

    wire sign_a, sign_b;
    wire [EXP_WIDTH-1:0] exp_a, exp_b;
    wire [EXP_WIDTH-1:0] exp_eff_a, exp_eff_b;
    wire [MANT_WIDTH-1:0] frac_a, frac_b;
    wire [MANT_WIDTH:0] sig_a, sig_b;
    wire is_zero_a, is_zero_b;
    wire is_inf_a, is_inf_b;
    wire is_nan_a, is_nan_b;
    wire is_denorm_a, is_denorm_b;

    wire special_case;
    wire [WIDTH-1:0] special_result;
    wire [2:0] special_flags;

    wire core_sign;
    wire [EXP_WIDTH:0] core_exp;
    wire [MANT_WIDTH+4:0] core_sig;
    wire core_zero;
    wire core_underflow_pre;

    wire [WIDTH-1:0] packed_result;
    wire [2:0] packed_flags;

    fp_unpack #(
        .WIDTH(WIDTH),
        .EXP_WIDTH(EXP_WIDTH),
        .MANT_WIDTH(MANT_WIDTH)
    ) unpack_a (
        .in(a),
        .sign(sign_a),
        .exp(exp_a),
        .exp_eff(exp_eff_a),
        .frac(frac_a),
        .sig(sig_a),
        .is_zero(is_zero_a),
        .is_inf(is_inf_a),
        .is_nan(is_nan_a),
        .is_denorm(is_denorm_a)
    );

    fp_unpack #(
        .WIDTH(WIDTH),
        .EXP_WIDTH(EXP_WIDTH),
        .MANT_WIDTH(MANT_WIDTH)
    ) unpack_b (
        .in(b),
        .sign(sign_b),
        .exp(exp_b),
        .exp_eff(exp_eff_b),
        .frac(frac_b),
        .sig(sig_b),
        .is_zero(is_zero_b),
        .is_inf(is_inf_b),
        .is_nan(is_nan_b),
        .is_denorm(is_denorm_b)
    );

    fp_special_cases #(
        .WIDTH(WIDTH),
        .EXP_WIDTH(EXP_WIDTH),
        .MANT_WIDTH(MANT_WIDTH)
    ) special_cases (
        .a(a),
        .b(b),
        .sign_a(sign_a),
        .sign_b(sign_b),
        .is_zero_a(is_zero_a),
        .is_zero_b(is_zero_b),
        .is_inf_a(is_inf_a),
        .is_inf_b(is_inf_b),
        .is_nan_a(is_nan_a),
        .is_nan_b(is_nan_b),
        .rnd_mode(rnd_mode),
        .special(special_case),
        .result(special_result),
        .flags(special_flags)
    );

    fp_align_add_norm #(
        .WIDTH(WIDTH),
        .EXP_WIDTH(EXP_WIDTH),
        .MANT_WIDTH(MANT_WIDTH)
    ) align_add_norm (
        .sign_a(sign_a),
        .sign_b(sign_b),
        .exp_a(exp_eff_a),
        .exp_b(exp_eff_b),
        .sig_a(sig_a),
        .sig_b(sig_b),
        .is_denorm_a(is_denorm_a),
        .is_denorm_b(is_denorm_b),
        .rnd_mode(rnd_mode),
        .result_sign(core_sign),
        .result_exp(core_exp),
        .result_sig(core_sig),
        .result_zero(core_zero),
        .underflow_pre(core_underflow_pre)
    );

    fp_round_pack #(
        .WIDTH(WIDTH),
        .EXP_WIDTH(EXP_WIDTH),
        .MANT_WIDTH(MANT_WIDTH)
    ) round_pack (
        .result_sign(core_sign),
        .result_exp(core_exp),
        .result_sig(core_sig),
        .result_zero(core_zero),
        .underflow_pre(core_underflow_pre),
        .rnd_mode(rnd_mode),
        .packed_result(packed_result),
        .flags(packed_flags)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sum <= {WIDTH{1'b0}};
            exception_flags <= 3'b000;
        end else begin
            if (special_case) begin
                sum <= special_result;
                exception_flags <= special_flags;
            end else begin
                sum <= packed_result;
                exception_flags <= packed_flags;
            end
        end
    end

endmodule