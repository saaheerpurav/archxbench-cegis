`timescale 1ns/1ps

module fp_mult_mul_exp (
    input [7:0] exp_a,
    input [7:0] exp_b,
    input [23:0] sig_a,
    input [23:0] sig_b,
    input sub_a,
    input sub_b,
    output [47:0] product,
    output signed [9:0] exp_sum
);

wire [8:0] eff_exp_a;
wire [8:0] eff_exp_b;

assign eff_exp_a = sub_a ? 9'd1 : {1'b0, exp_a};
assign eff_exp_b = sub_b ? 9'd1 : {1'b0, exp_b};

assign product = sig_a * sig_b;
assign exp_sum = $signed({1'b0, eff_exp_a}) + $signed({1'b0, eff_exp_b}) - 10'sd127;

endmodule