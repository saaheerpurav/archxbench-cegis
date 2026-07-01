`timescale 1ns/1ps

module fft16_ifft_butterfly #(
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
    localparam PROD_W = DATA_W + COEFF_W;
    localparam ACC_W  = PROD_W + 2;
    localparam SHIFT  = COEFF_W - 1;

    wire signed [PROD_W-1:0] br_cos = b_real * tw_cos;
    wire signed [PROD_W-1:0] bi_sin = b_imag * tw_sin;
    wire signed [PROD_W-1:0] br_sin = b_real * tw_sin;
    wire signed [PROD_W-1:0] bi_cos = b_imag * tw_cos;

    wire signed [ACC_W-1:0] round_bias = {{(ACC_W-1){1'b0}}, 1'b1} <<< (SHIFT-1);

    wire signed [ACC_W-1:0] rot_real_acc =
        {{(ACC_W-PROD_W){br_cos[PROD_W-1]}}, br_cos} -
        {{(ACC_W-PROD_W){bi_sin[PROD_W-1]}}, bi_sin} +
        round_bias;

    wire signed [ACC_W-1:0] rot_imag_acc =
        {{(ACC_W-PROD_W){br_sin[PROD_W-1]}}, br_sin} +
        {{(ACC_W-PROD_W){bi_cos[PROD_W-1]}}, bi_cos} +
        round_bias;

    wire signed [ACC_W-1:0] rot_real_full = rot_real_acc >>> SHIFT;
    wire signed [ACC_W-1:0] rot_imag_full = rot_imag_acc >>> SHIFT;

    wire signed [DATA_W-1:0] rot_real = rot_real_full[DATA_W-1:0];
    wire signed [DATA_W-1:0] rot_imag = rot_imag_full[DATA_W-1:0];

    assign y0_real = a_real + rot_real;
    assign y0_imag = a_imag + rot_imag;
    assign y1_real = a_real - rot_real;
    assign y1_imag = a_imag - rot_imag;
endmodule