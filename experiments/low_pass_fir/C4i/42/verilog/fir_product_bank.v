`timescale 1ns/1ps

module fir_product_bank #(
    parameter DATA_W   = 20,
    parameter SUM_W    = 21,
    parameter COEFF_W  = 16,
    parameter PAIR_CNT = 50,
    parameter PROD_W   = 64
) (
    input      [SUM_W*PAIR_CNT-1:0]    pair_sums,
    input signed [DATA_W-1:0]          center_sample,
    input      [COEFF_W*PAIR_CNT-1:0]  pair_coeffs,
    input signed [COEFF_W-1:0]         center_coeff,
    output     [PROD_W*PAIR_CNT-1:0]   products,
    output signed [PROD_W-1:0]         center_product
);

    genvar i;

    generate
        for (i = 0; i < PAIR_CNT; i = i + 1) begin : g_mult
            wire signed [SUM_W-1:0]   sum_i;
            wire signed [COEFF_W-1:0] coeff_i;

            wire signed [PROD_W-1:0]  sum_ext_i;
            wire signed [PROD_W-1:0]  coeff_ext_i;
            wire signed [PROD_W-1:0]  product_i;

            assign sum_i   = pair_sums[i*SUM_W +: SUM_W];
            assign coeff_i = pair_coeffs[i*COEFF_W +: COEFF_W];

            assign sum_ext_i   = {{(PROD_W-SUM_W){sum_i[SUM_W-1]}}, sum_i};
            assign coeff_ext_i = {{(PROD_W-COEFF_W){coeff_i[COEFF_W-1]}}, coeff_i};

            assign product_i = sum_ext_i * coeff_ext_i;

            assign products[i*PROD_W +: PROD_W] = product_i;
        end
    endgenerate

    wire signed [PROD_W-1:0] center_sample_ext;
    wire signed [PROD_W-1:0] center_coeff_ext;

    assign center_sample_ext = {{(PROD_W-DATA_W){center_sample[DATA_W-1]}}, center_sample};
    assign center_coeff_ext  = {{(PROD_W-COEFF_W){center_coeff[COEFF_W-1]}}, center_coeff};

    assign center_product = center_sample_ext * center_coeff_ext;

endmodule