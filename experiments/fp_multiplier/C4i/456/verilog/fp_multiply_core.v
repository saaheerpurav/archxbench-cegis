`timescale 1ns/1ps

module fp_multiply_core #(
    parameter EXP_WIDTH  = 8,
    parameter MANT_WIDTH = 23,
    parameter SIG_WIDTH  = MANT_WIDTH + 1,
    parameter PROD_WIDTH = 2 * SIG_WIDTH
)(
    input  wire                         sign_a,
    input  wire                         sign_b,
    input  wire signed [EXP_WIDTH+1:0]  unbiased_exp_a,
    input  wire signed [EXP_WIDTH+1:0]  unbiased_exp_b,
    input  wire [SIG_WIDTH-1:0]         sig_a,
    input  wire [SIG_WIDTH-1:0]         sig_b,

    output wire                         result_sign,
    output wire signed [EXP_WIDTH+2:0]  exp_sum,
    output wire [PROD_WIDTH-1:0]        sig_product
);

    assign result_sign = sign_a ^ sign_b;

    assign exp_sum =
        $signed({unbiased_exp_a[EXP_WIDTH+1], unbiased_exp_a}) +
        $signed({unbiased_exp_b[EXP_WIDTH+1], unbiased_exp_b});

    assign sig_product = sig_a * sig_b;

endmodule