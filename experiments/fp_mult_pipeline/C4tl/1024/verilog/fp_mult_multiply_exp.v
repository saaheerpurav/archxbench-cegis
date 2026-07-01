`timescale 1ns/1ps

module fp_mult_multiply_exp (
    input [7:0] exp_a,
    input [7:0] exp_b,
    input [23:0] mant_a,
    input [23:0] mant_b,
    input sub_a,
    input sub_b,
    output [47:0] product,
    output signed [10:0] exp_unbiased
);

wire signed [10:0] exp_a_unbiased;
wire signed [10:0] exp_b_unbiased;

assign product = mant_a * mant_b;

assign exp_a_unbiased = sub_a ? -11'sd126 : ({3'b000, exp_a} - 11'sd127);
assign exp_b_unbiased = sub_b ? -11'sd126 : ({3'b000, exp_b} - 11'sd127);

assign exp_unbiased = exp_a_unbiased + exp_b_unbiased;

endmodule