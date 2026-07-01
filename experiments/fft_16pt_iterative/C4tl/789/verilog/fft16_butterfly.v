`timescale 1ns/1ps

module fft16_butterfly #(
    parameter DATA_W = 16,
    parameter COEFF_W = 16
) (
    input signed [DATA_W-1:0] a_real,
    input signed [DATA_W-1:0] a_imag,
    input signed [DATA_W-1:0] b_real,
    input signed [DATA_W-1:0] b_imag,
    input signed [COEFF_W-1:0] tw_cos_q15,
    input signed [COEFF_W-1:0] tw_sin_q15,
    output signed [DATA_W-1:0] y0_real,
    output signed [DATA_W-1:0] y0_imag,
    output signed [DATA_W-1:0] y1_real,
    output signed [DATA_W-1:0] y1_imag
);

    localparam PROD_W = DATA_W + COEFF_W + 2;
    localparam signed [PROD_W-1:0] ROUND = {{(PROD_W-15){1'b0}}, 15'sd16384};

    wire signed [PROD_W-1:0] prod_rr;
    wire signed [PROD_W-1:0] prod_is;
    wire signed [PROD_W-1:0] prod_ic;
    wire signed [PROD_W-1:0] prod_rs;

    wire signed [PROD_W-1:0] rot_real_w;
    wire signed [PROD_W-1:0] rot_imag_w;

    wire signed [DATA_W-1:0] rot_real;
    wire signed [DATA_W-1:0] rot_imag;

    assign prod_rr = b_real * tw_cos_q15;
    assign prod_is = b_imag * tw_sin_q15;
    assign prod_ic = b_imag * tw_cos_q15;
    assign prod_rs = b_real * tw_sin_q15;

    assign rot_real_w = (prod_rr - prod_is + ROUND) >>> 15;
    assign rot_imag_w = (prod_ic + prod_rs + ROUND) >>> 15;

    assign rot_real = rot_real_w[DATA_W-1:0];
    assign rot_imag = rot_imag_w[DATA_W-1:0];

    assign y0_real = a_real + rot_real;
    assign y0_imag = a_imag + rot_imag;
    assign y1_real = a_real - rot_real;
    assign y1_imag = a_imag - rot_imag;

endmodule