`timescale 1ns/1ps

module fp_mult_mul_exp (
    input [23:0] sig_a,
    input [23:0] sig_b,
    input [7:0] exp_a,
    input [7:0] exp_b,
    output [47:0] product,
    output signed [10:0] exp_sum
);
    wire signed [10:0] eff_exp_a;
    wire signed [10:0] eff_exp_b;

    assign eff_exp_a = (exp_a == 8'd0) ? 11'sd1 : {3'b000, exp_a};
    assign eff_exp_b = (exp_b == 8'd0) ? 11'sd1 : {3'b000, exp_b};

    assign product = sig_a * sig_b;
    assign exp_sum = eff_exp_a + eff_exp_b - 11'sd127;
endmodule