`timescale 1ns/1ps

module fp_mult_exp_product (
    input signed [10:0] exp_a_unbiased,
    input signed [10:0] exp_b_unbiased,
    input [23:0] mant_a,
    input [23:0] mant_b,
    output signed [10:0] exp_sum_unbiased,
    output [47:0] product
);

assign exp_sum_unbiased = exp_a_unbiased + exp_b_unbiased;
assign product = mant_a * mant_b;

endmodule