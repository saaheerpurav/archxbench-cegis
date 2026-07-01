`timescale 1ns/1ps

module ifft16_butterfly #(
    parameter DATA_W = 16,
    parameter COEFF_W = 16
) (
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
    localparam FRAC_W = COEFF_W - 1;
    localparam PROD_W = DATA_W + COEFF_W;
    localparam ACC_W  = PROD_W + 2;

    wire signed [PROD_W-1:0] br_cos = b_real * tw_cos;
    wire signed [PROD_W-1:0] bi_sin = b_imag * tw_sin;
    wire signed [PROD_W-1:0] br_sin = b_real * tw_sin;
    wire signed [PROD_W-1:0] bi_cos = b_imag * tw_cos;

    wire signed [ACC_W-1:0] br_cos_ext = {{(ACC_W-PROD_W){br_cos[PROD_W-1]}}, br_cos};
    wire signed [ACC_W-1:0] bi_sin_ext = {{(ACC_W-PROD_W){bi_sin[PROD_W-1]}}, bi_sin};
    wire signed [ACC_W-1:0] br_sin_ext = {{(ACC_W-PROD_W){br_sin[PROD_W-1]}}, br_sin};
    wire signed [ACC_W-1:0] bi_cos_ext = {{(ACC_W-PROD_W){bi_cos[PROD_W-1]}}, bi_cos};

    wire signed [ACC_W-1:0] round_const = {{(ACC_W-FRAC_W-1){1'b0}}, 1'b1, {FRAC_W-1{1'b0}}};

    wire signed [ACC_W-1:0] tr_acc = br_cos_ext - bi_sin_ext + round_const;
    wire signed [ACC_W-1:0] ti_acc = br_sin_ext + bi_cos_ext + round_const;

    wire signed [ACC_W-1:0] tr_shift = tr_acc >>> FRAC_W;
    wire signed [ACC_W-1:0] ti_shift = ti_acc >>> FRAC_W;

    wire signed [DATA_W-1:0] tr = tr_shift[DATA_W-1:0];
    wire signed [DATA_W-1:0] ti = ti_shift[DATA_W-1:0];

    wire signed [DATA_W:0] y0_real_ext = {a_real[DATA_W-1], a_real} + {tr[DATA_W-1], tr};
    wire signed [DATA_W:0] y0_imag_ext = {a_imag[DATA_W-1], a_imag} + {ti[DATA_W-1], ti};
    wire signed [DATA_W:0] y1_real_ext = {a_real[DATA_W-1], a_real} - {tr[DATA_W-1], tr};
    wire signed [DATA_W:0] y1_imag_ext = {a_imag[DATA_W-1], a_imag} - {ti[DATA_W-1], ti};

    assign y0_real = y0_real_ext[DATA_W-1:0];
    assign y0_imag = y0_imag_ext[DATA_W-1:0];
    assign y1_real = y1_real_ext[DATA_W-1:0];
    assign y1_imag = y1_imag_ext[DATA_W-1:0];
endmodule