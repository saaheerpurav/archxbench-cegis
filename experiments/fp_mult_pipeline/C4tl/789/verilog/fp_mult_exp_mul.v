`timescale 1ns/1ps

module fp_mult_exp_mul (
    input [7:0] exp_a,
    input [7:0] exp_b,
    input [23:0] sig_a,
    input [23:0] sig_b,
    input sub_a,
    input sub_b,
    output [47:0] product,
    output signed [10:0] exp_unbiased
);

wire signed [10:0] eff_exp_a;
wire signed [10:0] eff_exp_b;

assign eff_exp_a = sub_a ? 11'sd1 : {3'b000, exp_a};
assign eff_exp_b = sub_b ? 11'sd1 : {3'b000, exp_b};

assign product = sig_a * sig_b;
assign exp_unbiased = eff_exp_a + eff_exp_b - 11'sd127;

endmodule