`timescale 1ns/1ps

module fft16_butterfly #(
    parameter DATA_W  = 16,
    parameter COEFF_W = 16
) (
    input  wire                         mode,   // 0: FFT, 1: IFFT
    input  wire signed [DATA_W-1:0]     a_re,
    input  wire signed [DATA_W-1:0]     a_im,
    input  wire signed [DATA_W-1:0]     b_re,
    input  wire signed [DATA_W-1:0]     b_im,
    input  wire signed [COEFF_W-1:0]    tw_cos,
    input  wire signed [COEFF_W-1:0]    tw_sin,
    output wire signed [DATA_W-1:0]     y0_re,
    output wire signed [DATA_W-1:0]     y0_im,
    output wire signed [DATA_W-1:0]     y1_re,
    output wire signed [DATA_W-1:0]     y1_im
);

    localparam PROD_W = DATA_W + COEFF_W;
    localparam ACC_W  = PROD_W + 2;

    wire signed [PROD_W-1:0] br_cos = b_re * tw_cos;
    wire signed [PROD_W-1:0] bi_sin = b_im * tw_sin;
    wire signed [PROD_W-1:0] bi_cos = b_im * tw_cos;
    wire signed [PROD_W-1:0] br_sin = b_re * tw_sin;

    wire signed [ACC_W-1:0] br_cos_ext = {{(ACC_W-PROD_W){br_cos[PROD_W-1]}}, br_cos};
    wire signed [ACC_W-1:0] bi_sin_ext = {{(ACC_W-PROD_W){bi_sin[PROD_W-1]}}, bi_sin};
    wire signed [ACC_W-1:0] bi_cos_ext = {{(ACC_W-PROD_W){bi_cos[PROD_W-1]}}, bi_cos};
    wire signed [ACC_W-1:0] br_sin_ext = {{(ACC_W-PROD_W){br_sin[PROD_W-1]}}, br_sin};

    wire signed [ACC_W-1:0] round_const = {{(ACC_W-15){1'b0}}, 15'sd16384};

    wire signed [ACC_W-1:0] tr_re_pre =
        mode ? (br_cos_ext - bi_sin_ext + round_const)
             : (br_cos_ext + bi_sin_ext + round_const);

    wire signed [ACC_W-1:0] tr_im_pre =
        mode ? (bi_cos_ext + br_sin_ext + round_const)
             : (bi_cos_ext - br_sin_ext + round_const);

    wire signed [DATA_W-1:0] tr_re = tr_re_pre >>> 15;
    wire signed [DATA_W-1:0] tr_im = tr_im_pre >>> 15;

    assign y0_re = a_re + tr_re;
    assign y0_im = a_im + tr_im;
    assign y1_re = a_re - tr_re;
    assign y1_im = a_im - tr_im;

endmodule