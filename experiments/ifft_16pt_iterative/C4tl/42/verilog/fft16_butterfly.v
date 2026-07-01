`timescale 1ns/1ps

module fft16_butterfly #(
    parameter DATA_W = 16,
    parameter COEFF_W = 16
) (
    input  signed [DATA_W-1:0]  a_real,
    input  signed [DATA_W-1:0]  a_imag,
    input  signed [DATA_W-1:0]  b_real,
    input  signed [DATA_W-1:0]  b_imag,
    input  signed [COEFF_W-1:0] tw_cos,
    input  signed [COEFF_W-1:0] tw_sin,
    output signed [DATA_W-1:0]  y0_real,
    output signed [DATA_W-1:0]  y0_imag,
    output signed [DATA_W-1:0]  y1_real,
    output signed [DATA_W-1:0]  y1_imag
);
    localparam MULT_W = DATA_W + COEFF_W;
    localparam ACC_W  = MULT_W + 1;

    wire signed [MULT_W-1:0] br_cos = b_real * tw_cos;
    wire signed [MULT_W-1:0] bi_sin = b_imag * tw_sin;
    wire signed [MULT_W-1:0] br_sin = b_real * tw_sin;
    wire signed [MULT_W-1:0] bi_cos = b_imag * tw_cos;

    wire signed [ACC_W-1:0] round_const = {{(ACC_W-15){1'b0}}, 15'sd16384};

    wire signed [ACC_W-1:0] tr_acc =
        {br_cos[MULT_W-1], br_cos} -
        {bi_sin[MULT_W-1], bi_sin} +
        round_const;

    wire signed [ACC_W-1:0] ti_acc =
        {br_sin[MULT_W-1], br_sin} +
        {bi_cos[MULT_W-1], bi_cos} +
        round_const;

    wire signed [DATA_W-1:0] tr = tr_acc >>> 15;
    wire signed [DATA_W-1:0] ti = ti_acc >>> 15;

    assign y0_real = a_real + tr;
    assign y0_imag = a_imag + ti;
    assign y1_real = a_real - tr;
    assign y1_imag = a_imag - ti;
endmodule