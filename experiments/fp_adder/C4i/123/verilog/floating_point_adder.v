`timescale 1ns/1ps

module floating_point_adder #(
    parameter WIDTH = 32,
    parameter EXP_WIDTH = 8,
    parameter MANT_WIDTH = 23
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
    wire [MANT_WIDTH-1:0] mant_a, mant_b;
    wire a_zero, b_zero, a_inf, b_inf, a_nan, b_nan, a_denorm, b_denorm;

    wire special_valid;
    wire [WIDTH-1:0] special_sum;
    wire [2:0] special_flags;

    wire [WIDTH-1:0] core_sum;
    wire [2:0] core_flags;

    fp_unpack #(
        .WIDTH(WIDTH),
        .EXP_WIDTH(EXP_WIDTH),
        .MANT_WIDTH(MANT_WIDTH)
    ) unpack_a (
        .in(a),
        .sign(sign_a),
        .exp(exp_a),
        .mant(mant_a),
        .is_zero(a_zero),
        .is_inf(a_inf),
        .is_nan(a_nan),
        .is_denorm(a_denorm)
    );

    fp_unpack #(
        .WIDTH(WIDTH),
        .EXP_WIDTH(EXP_WIDTH),
        .MANT_WIDTH(MANT_WIDTH)
    ) unpack_b (
        .in(b),
        .sign(sign_b),
        .exp(exp_b),
        .mant(mant_b),
        .is_zero(b_zero),
        .is_inf(b_inf),
        .is_nan(b_nan),
        .is_denorm(b_denorm)
    );

    fp_special_cases #(
        .WIDTH(WIDTH),
        .EXP_WIDTH(EXP_WIDTH),
        .MANT_WIDTH(MANT_WIDTH)
    ) special_cases (
        .a(a),
        .b(b),
        .rnd_mode(rnd_mode),
        .sign_a(sign_a),
        .sign_b(sign_b),
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

    fp_add_core #(
        .WIDTH(WIDTH),
        .EXP_WIDTH(EXP_WIDTH),
        .MANT_WIDTH(MANT_WIDTH)
    ) add_core (
        .sign_a(sign_a),
        .sign_b(sign_b),
        .exp_a(exp_a),
        .exp_b(exp_b),
        .mant_a(mant_a),
        .mant_b(mant_b),
        .a_denorm(a_denorm),
        .b_denorm(b_denorm),
        .rnd_mode(rnd_mode),
        .sum(core_sum),
        .exception_flags(core_flags)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sum <= {WIDTH{1'b0}};
            exception_flags <= 3'b000;
        end else if (special_valid) begin
            sum <= special_sum;
            exception_flags <= special_flags;
        end else begin
            sum <= core_sum;
            exception_flags <= core_flags;
        end
    end

endmodule