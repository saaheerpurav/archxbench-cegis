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
    output signed [DATA_W-1:0] p_real_out,
    output signed [DATA_W-1:0] p_imag_out,
    output signed [DATA_W-1:0] q_real_out,
    output signed [DATA_W-1:0] q_imag_out
);

    localparam PROD_W = DATA_W + COEFF_W;
    localparam ACC_W  = PROD_W + 2;

    wire signed [PROD_W-1:0] br_cos = b_real * tw_cos;
    wire signed [PROD_W-1:0] bi_sin = b_imag * tw_sin;
    wire signed [PROD_W-1:0] br_sin = b_real * tw_sin;
    wire signed [PROD_W-1:0] bi_cos = b_imag * tw_cos;

    wire signed [ACC_W-1:0] round_q15 = {{(ACC_W-15){1'b0}}, 15'sd16384};

    wire signed [ACC_W-1:0] tr_acc =
        {{(ACC_W-PROD_W){br_cos[PROD_W-1]}}, br_cos} -
        {{(ACC_W-PROD_W){bi_sin[PROD_W-1]}}, bi_sin} +
        round_q15;

    wire signed [ACC_W-1:0] ti_acc =
        {{(ACC_W-PROD_W){br_sin[PROD_W-1]}}, br_sin} +
        {{(ACC_W-PROD_W){bi_cos[PROD_W-1]}}, bi_cos} +
        round_q15;

    wire signed [DATA_W-1:0] tr = tr_acc >>> 15;
    wire signed [DATA_W-1:0] ti = ti_acc >>> 15;

    assign p_real_out = a_real + tr;
    assign p_imag_out = a_imag + ti;
    assign q_real_out = a_real - tr;
    assign q_imag_out = a_imag - ti;

endmodule