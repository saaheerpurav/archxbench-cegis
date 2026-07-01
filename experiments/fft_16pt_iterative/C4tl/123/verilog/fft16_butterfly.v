`timescale 1ns/1ps

module fft16_butterfly #(
    parameter DATA_W = 16,
    parameter COEFF_W = 16
) (
    input mode,
    input signed [DATA_W-1:0] a_real,
    input signed [DATA_W-1:0] a_imag,
    input signed [DATA_W-1:0] b_real,
    input signed [DATA_W-1:0] b_imag,
    input signed [COEFF_W-1:0] tw_cos,
    input signed [COEFF_W-1:0] tw_sin,
    output signed [DATA_W-1:0] y0_real,
    output signed [DATA_W-1:0] y0_imag,
    output signed [DATA_W-1:0] y1_real,
    output signed [DATA_W-1:0] y1_imag
);

    localparam EXT_COEFF_W = COEFF_W + 1;
    localparam PROD_W      = DATA_W + EXT_COEFF_W;
    localparam SUM_W       = PROD_W + 1;

    wire signed [EXT_COEFF_W-1:0] cos_ext;
    wire signed [EXT_COEFF_W-1:0] sin_ext;
    wire signed [EXT_COEFF_W-1:0] sin_eff;

    assign cos_ext = {tw_cos[COEFF_W-1], tw_cos};
    assign sin_ext = {tw_sin[COEFF_W-1], tw_sin};

    // FFT:  cos - j*sin.  IFFT: cos + j*sin = cos - j*(-sin).
    assign sin_eff = mode ? -sin_ext : sin_ext;

    wire signed [PROD_W-1:0] prod_real_cos;
    wire signed [PROD_W-1:0] prod_imag_sin;
    wire signed [PROD_W-1:0] prod_imag_cos;
    wire signed [PROD_W-1:0] prod_real_sin;

    assign prod_real_cos = b_real * cos_ext;
    assign prod_imag_sin = b_imag * sin_eff;
    assign prod_imag_cos = b_imag * cos_ext;
    assign prod_real_sin = b_real * sin_eff;

    wire signed [SUM_W-1:0] mult_real_sum;
    wire signed [SUM_W-1:0] mult_imag_sum;

    assign mult_real_sum = prod_real_cos + prod_imag_sin;
    assign mult_imag_sum = prod_imag_cos - prod_real_sin;

    wire signed [SUM_W-1:0] tr_real_ext;
    wire signed [SUM_W-1:0] tr_imag_ext;

    assign tr_real_ext = (mult_real_sum + {{(SUM_W-15){1'b0}}, 1'b1, 14'b0}) >>> 15;
    assign tr_imag_ext = (mult_imag_sum + {{(SUM_W-15){1'b0}}, 1'b1, 14'b0}) >>> 15;

    wire signed [DATA_W-1:0] tr_real;
    wire signed [DATA_W-1:0] tr_imag;

    assign tr_real = tr_real_ext[DATA_W-1:0];
    assign tr_imag = tr_imag_ext[DATA_W-1:0];

    assign y0_real = a_real + tr_real;
    assign y0_imag = a_imag + tr_imag;
    assign y1_real = a_real - tr_real;
    assign y1_imag = a_imag - tr_imag;

endmodule