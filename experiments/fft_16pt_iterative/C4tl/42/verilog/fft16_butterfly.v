`timescale 1ns/1ps

module fft16_butterfly #(
    parameter DATA_W = 16,
    parameter COEFF_W = 16
) (
    input signed [DATA_W-1:0] a_real,
    input signed [DATA_W-1:0] a_imag,
    input signed [DATA_W-1:0] b_real,
    input signed [DATA_W-1:0] b_imag,
    input signed [COEFF_W-1:0] tw_cos,
    input signed [COEFF_W-1:0] tw_sin,
    input ifft_mode,
    output signed [DATA_W-1:0] y0_real,
    output signed [DATA_W-1:0] y0_imag,
    output signed [DATA_W-1:0] y1_real,
    output signed [DATA_W-1:0] y1_imag
);
    localparam TW_EXT_W = COEFF_W + 1;
    localparam PROD_W   = DATA_W + TW_EXT_W;
    localparam ACC_W    = PROD_W + 1;

    wire signed [TW_EXT_W-1:0] cos_ext;
    wire signed [TW_EXT_W-1:0] sin_ext;
    wire signed [TW_EXT_W-1:0] sin_eff;

    assign cos_ext = {tw_cos[COEFF_W-1], tw_cos};
    assign sin_ext = {tw_sin[COEFF_W-1], tw_sin};

    // FFT:  cos - j*sin.  IFFT: cos + j*sin, equivalent to sin_eff = -sin.
    assign sin_eff = ifft_mode ? -sin_ext : sin_ext;

    wire signed [PROD_W-1:0] br_cos;
    wire signed [PROD_W-1:0] bi_sin;
    wire signed [PROD_W-1:0] bi_cos;
    wire signed [PROD_W-1:0] br_sin;

    assign br_cos = b_real * cos_ext;
    assign bi_sin = b_imag * sin_eff;
    assign bi_cos = b_imag * cos_ext;
    assign br_sin = b_real * sin_eff;

    wire signed [ACC_W-1:0] real_acc;
    wire signed [ACC_W-1:0] imag_acc;
    wire signed [ACC_W-1:0] round_q15;

    assign round_q15 = {{(ACC_W-15){1'b0}}, 15'sd16384};

    assign real_acc = {br_cos[PROD_W-1], br_cos} + {bi_sin[PROD_W-1], bi_sin};
    assign imag_acc = {bi_cos[PROD_W-1], bi_cos} - {br_sin[PROD_W-1], br_sin};

    wire signed [ACC_W-1:0] tr_real_wide;
    wire signed [ACC_W-1:0] tr_imag_wide;

    assign tr_real_wide = (real_acc + round_q15) >>> 15;
    assign tr_imag_wide = (imag_acc + round_q15) >>> 15;

    wire signed [DATA_W-1:0] tr_real;
    wire signed [DATA_W-1:0] tr_imag;

    assign tr_real = tr_real_wide[DATA_W-1:0];
    assign tr_imag = tr_imag_wide[DATA_W-1:0];

    assign y0_real = a_real + tr_real;
    assign y0_imag = a_imag + tr_imag;
    assign y1_real = a_real - tr_real;
    assign y1_imag = a_imag - tr_imag;
endmodule