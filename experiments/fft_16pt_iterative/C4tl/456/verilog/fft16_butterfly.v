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
    input mode,
    output signed [DATA_W-1:0] y0_real,
    output signed [DATA_W-1:0] y0_imag,
    output signed [DATA_W-1:0] y1_real,
    output signed [DATA_W-1:0] y1_imag
);

    localparam FRAC_W = 15;
    localparam SIN_W  = COEFF_W + 1;
    localparam PROD_W = DATA_W + SIN_W;
    localparam ACC_W  = PROD_W + 1;

    wire signed [SIN_W-1:0] tw_cos_ext;
    wire signed [SIN_W-1:0] tw_sin_ext;
    wire signed [SIN_W-1:0] tw_sin_eff;

    wire signed [PROD_W-1:0] prod_real_cos;
    wire signed [PROD_W-1:0] prod_imag_sin;
    wire signed [PROD_W-1:0] prod_imag_cos;
    wire signed [PROD_W-1:0] prod_real_sin;

    wire signed [ACC_W-1:0] mult_real_acc;
    wire signed [ACC_W-1:0] mult_imag_acc;
    wire signed [ACC_W-1:0] mult_real_round;
    wire signed [ACC_W-1:0] mult_imag_round;

    wire signed [DATA_W-1:0] tr_real;
    wire signed [DATA_W-1:0] tr_imag;

    assign tw_cos_ext = {tw_cos[COEFF_W-1], tw_cos};
    assign tw_sin_ext = {tw_sin[COEFF_W-1], tw_sin};

    // FFT uses cos - j*sin; IFFT uses the conjugate cos + j*sin.
    assign tw_sin_eff = mode ? -tw_sin_ext : tw_sin_ext;

    assign prod_real_cos = b_real * tw_cos_ext;
    assign prod_imag_sin = b_imag * tw_sin_eff;
    assign prod_imag_cos = b_imag * tw_cos_ext;
    assign prod_real_sin = b_real * tw_sin_eff;

    assign mult_real_acc = prod_real_cos + prod_imag_sin;
    assign mult_imag_acc = prod_imag_cos - prod_real_sin;

    assign mult_real_round = mult_real_acc + ({{(ACC_W-1){1'b0}}, 1'b1} <<< (FRAC_W-1));
    assign mult_imag_round = mult_imag_acc + ({{(ACC_W-1){1'b0}}, 1'b1} <<< (FRAC_W-1));

    assign tr_real = mult_real_round >>> FRAC_W;
    assign tr_imag = mult_imag_round >>> FRAC_W;

    assign y0_real = a_real + tr_real;
    assign y0_imag = a_imag + tr_imag;
    assign y1_real = a_real - tr_real;
    assign y1_imag = a_imag - tr_imag;

endmodule