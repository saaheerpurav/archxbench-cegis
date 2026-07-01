`timescale 1ns/1ps

module fft16_complex_mult_q15 #(
    parameter DATA_W = 16,
    parameter COEFF_W = 16
) (
    input  signed [DATA_W-1:0]  x_real,
    input  signed [DATA_W-1:0]  x_imag,
    input  signed [COEFF_W-1:0] tw_cos,
    input  signed [COEFF_W-1:0] tw_sin,
    output signed [DATA_W-1:0]  y_real,
    output signed [DATA_W-1:0]  y_imag
);
    localparam PROD_W = DATA_W + COEFF_W;
    localparam SUM_W  = PROD_W + 2;

    wire signed [PROD_W-1:0] prod_rr = x_real * tw_cos;
    wire signed [PROD_W-1:0] prod_is = x_imag * tw_sin;
    wire signed [PROD_W-1:0] prod_rs = x_real * tw_sin;
    wire signed [PROD_W-1:0] prod_ic = x_imag * tw_cos;

    wire signed [SUM_W-1:0] prod_rr_ext = {{(SUM_W-PROD_W){prod_rr[PROD_W-1]}}, prod_rr};
    wire signed [SUM_W-1:0] prod_is_ext = {{(SUM_W-PROD_W){prod_is[PROD_W-1]}}, prod_is};
    wire signed [SUM_W-1:0] prod_rs_ext = {{(SUM_W-PROD_W){prod_rs[PROD_W-1]}}, prod_rs};
    wire signed [SUM_W-1:0] prod_ic_ext = {{(SUM_W-PROD_W){prod_ic[PROD_W-1]}}, prod_ic};

    wire signed [SUM_W-1:0] round_q15 = 16384;

    wire signed [SUM_W-1:0] real_acc = prod_rr_ext - prod_is_ext + round_q15;
    wire signed [SUM_W-1:0] imag_acc = prod_rs_ext + prod_ic_ext + round_q15;

    wire signed [SUM_W-1:0] real_shifted = real_acc >>> 15;
    wire signed [SUM_W-1:0] imag_shifted = imag_acc >>> 15;

    assign y_real = real_shifted[DATA_W-1:0];
    assign y_imag = imag_shifted[DATA_W-1:0];
endmodule