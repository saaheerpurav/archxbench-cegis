`timescale 1ns/1ps

module ifft16_butterfly #(
    parameter DATA_W  = 16,
    parameter COEFF_W = 16
) (
    input  signed [DATA_W-1:0]  xp_real,
    input  signed [DATA_W-1:0]  xp_imag,
    input  signed [DATA_W-1:0]  xq_real,
    input  signed [DATA_W-1:0]  xq_imag,
    input  signed [COEFF_W-1:0] tw_cos,
    input  signed [COEFF_W-1:0] tw_sin,
    output signed [DATA_W-1:0]  yp_real,
    output signed [DATA_W-1:0]  yp_imag,
    output signed [DATA_W-1:0]  yq_real,
    output signed [DATA_W-1:0]  yq_imag
);

    localparam MULT_W = DATA_W + COEFF_W;
    localparam ACC_W  = MULT_W + 1;
    localparam SHIFT  = COEFF_W - 1;

    wire signed [MULT_W-1:0] mult_rr;
    wire signed [MULT_W-1:0] mult_ii;
    wire signed [MULT_W-1:0] mult_ri;
    wire signed [MULT_W-1:0] mult_ic;

    assign mult_rr = xq_real * tw_cos;
    assign mult_ii = xq_imag * tw_sin;
    assign mult_ri = xq_real * tw_sin;
    assign mult_ic = xq_imag * tw_cos;

    wire signed [ACC_W-1:0] round_const;
    assign round_const = {{(ACC_W-SHIFT-1){1'b0}}, 1'b1, {(SHIFT-1){1'b0}}};

    wire signed [ACC_W-1:0] real_acc;
    wire signed [ACC_W-1:0] imag_acc;

    assign real_acc = {mult_rr[MULT_W-1], mult_rr}
                    - {mult_ii[MULT_W-1], mult_ii}
                    + round_const;

    assign imag_acc = {mult_ri[MULT_W-1], mult_ri}
                    + {mult_ic[MULT_W-1], mult_ic}
                    + round_const;

    wire signed [ACC_W-1:0] tr_ext;
    wire signed [ACC_W-1:0] ti_ext;

    assign tr_ext = real_acc >>> SHIFT;
    assign ti_ext = imag_acc >>> SHIFT;

    wire signed [DATA_W-1:0] tr;
    wire signed [DATA_W-1:0] ti;

    assign tr = tr_ext[DATA_W-1:0];
    assign ti = ti_ext[DATA_W-1:0];

    assign yp_real = xp_real + tr;
    assign yp_imag = xp_imag + ti;
    assign yq_real = xp_real - tr;
    assign yq_imag = xp_imag - ti;

endmodule