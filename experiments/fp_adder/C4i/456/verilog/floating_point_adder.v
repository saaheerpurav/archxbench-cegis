`timescale 1ns/1ps

module floating_point_adder #(
    parameter integer WIDTH = 32,
    parameter integer EXP_WIDTH = 8,
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

    wire a_sign, b_sign;
    wire [EXP_WIDTH-1:0] a_exp, b_exp;
    wire [MANT_WIDTH-1:0] a_frac, b_frac;
    wire a_zero, b_zero, a_inf, b_inf, a_nan, b_nan;
    wire a_denorm, b_denorm;

    wire special_valid;
    wire [WIDTH-1:0] special_sum;
    wire [2:0] special_flags;

    wire [EXP_WIDTH:0] aligned_exp;
    wire aligned_sign_large, aligned_sign_small;
    wire [MANT_WIDTH+3:0] aligned_large_sig;
    wire [MANT_WIDTH+3:0] aligned_small_sig;

    wire raw_sign;
    wire raw_zero;
    wire [EXP_WIDTH:0] raw_exp;
    wire [MANT_WIDTH+4:0] raw_sig;

    wire [WIDTH-1:0] normal_sum;
    wire [2:0] normal_flags;

    fp_unpack #(
        .WIDTH(WIDTH),
        .EXP_WIDTH(EXP_WIDTH),
        .MANT_WIDTH(MANT_WIDTH)
    ) u_unpack (
        .a(a),
        .b(b),
        .a_sign(a_sign),
        .b_sign(b_sign),
        .a_exp(a_exp),
        .b_exp(b_exp),
        .a_frac(a_frac),
        .b_frac(b_frac),
        .a_zero(a_zero),
        .b_zero(b_zero),
        .a_inf(a_inf),
        .b_inf(b_inf),
        .a_nan(a_nan),
        .b_nan(b_nan),
        .a_denorm(a_denorm),
        .b_denorm(b_denorm)
    );

    fp_special_cases #(
        .WIDTH(WIDTH),
        .EXP_WIDTH(EXP_WIDTH),
        .MANT_WIDTH(MANT_WIDTH)
    ) u_special (
        .a(a),
        .b(b),
        .rnd_mode(rnd_mode),
        .a_sign(a_sign),
        .b_sign(b_sign),
        .a_zero(a_zero),
        .b_zero(b_zero),
        .a_inf(a_inf),
        .b_inf(b_inf),
        .a_nan(a_nan),
        .b_nan(b_nan),
        .special_valid(special_valid),
        .special_sum(special_sum),
        .special_flags(special_flags)
    );

    fp_align #(
        .WIDTH(WIDTH),
        .EXP_WIDTH(EXP_WIDTH),
        .MANT_WIDTH(MANT_WIDTH)
    ) u_align (
        .a_sign(a_sign),
        .b_sign(b_sign),
        .a_exp(a_exp),
        .b_exp(b_exp),
        .a_frac(a_frac),
        .b_frac(b_frac),
        .aligned_exp(aligned_exp),
        .large_sign(aligned_sign_large),
        .small_sign(aligned_sign_small),
        .large_sig(aligned_large_sig),
        .small_sig(aligned_small_sig)
    );

    fp_addsub #(
        .EXP_WIDTH(EXP_WIDTH),
        .MANT_WIDTH(MANT_WIDTH)
    ) u_addsub (
        .aligned_exp(aligned_exp),
        .large_sign(aligned_sign_large),
        .small_sign(aligned_sign_small),
        .large_sig(aligned_large_sig),
        .small_sig(aligned_small_sig),
        .raw_sign(raw_sign),
        .raw_zero(raw_zero),
        .raw_exp(raw_exp),
        .raw_sig(raw_sig)
    );

    fp_normalize_round #(
        .WIDTH(WIDTH),
        .EXP_WIDTH(EXP_WIDTH),
        .MANT_WIDTH(MANT_WIDTH)
    ) u_norm_round (
        .raw_sign(raw_sign),
        .raw_zero(raw_zero),
        .raw_exp(raw_exp),
        .raw_sig(raw_sig),
        .rnd_mode(rnd_mode),
        .input_denorm(a_denorm | b_denorm),
        .result(normal_sum),
        .flags(normal_flags)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sum <= {WIDTH{1'b0}};
            exception_flags <= 3'b000;
        end else begin
            if (special_valid) begin
                sum <= special_sum;
                exception_flags <= special_flags;
            end else begin
                sum <= normal_sum;
                exception_flags <= normal_flags;
            end
        end
    end

endmodule