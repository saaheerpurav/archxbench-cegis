`timescale 1ns/1ps

module ifft16_butterfly_q15 #(
    parameter IN_W    = 16,
    parameter COEFF_W = 16
) (
    input  signed [IN_W-1:0]    a_re,
    input  signed [IN_W-1:0]    a_im,
    input  signed [IN_W-1:0]    b_re,
    input  signed [IN_W-1:0]    b_im,
    input  signed [COEFF_W-1:0] w_re,
    input  signed [COEFF_W-1:0] w_im,
    output signed [IN_W-1:0]    y0_re,
    output signed [IN_W-1:0]    y0_im,
    output signed [IN_W-1:0]    y1_re,
    output signed [IN_W-1:0]    y1_im
);

    localparam PROD_W = IN_W + COEFF_W;
    localparam ACC_W  = PROD_W + 2;
    localparam SHIFT  = COEFF_W - 1;

    /*
     * Explicitly sign-extend operands before multiplication.
     * This avoids any ambiguity from expression sizing rules and guarantees
     * enough width for an IN_W by COEFF_W signed product.
     */
    wire signed [PROD_W-1:0] b_re_ext = {{COEFF_W{b_re[IN_W-1]}}, b_re};
    wire signed [PROD_W-1:0] b_im_ext = {{COEFF_W{b_im[IN_W-1]}}, b_im};
    wire signed [PROD_W-1:0] w_re_ext = {{IN_W{w_re[COEFF_W-1]}}, w_re};
    wire signed [PROD_W-1:0] w_im_ext = {{IN_W{w_im[COEFF_W-1]}}, w_im};

    wire signed [PROD_W-1:0] prod_rr = b_re_ext * w_re_ext;
    wire signed [PROD_W-1:0] prod_ii = b_im_ext * w_im_ext;
    wire signed [PROD_W-1:0] prod_ri = b_re_ext * w_im_ext;
    wire signed [PROD_W-1:0] prod_ir = b_im_ext * w_re_ext;

    wire signed [ACC_W-1:0] rr_ext = {{(ACC_W-PROD_W){prod_rr[PROD_W-1]}}, prod_rr};
    wire signed [ACC_W-1:0] ii_ext = {{(ACC_W-PROD_W){prod_ii[PROD_W-1]}}, prod_ii};
    wire signed [ACC_W-1:0] ri_ext = {{(ACC_W-PROD_W){prod_ri[PROD_W-1]}}, prod_ri};
    wire signed [ACC_W-1:0] ir_ext = {{(ACC_W-PROD_W){prod_ir[PROD_W-1]}}, prod_ir};

    /*
     * Q1.(COEFF_W-1) rounding constant.
     * For COEFF_W=16 this is 2^14, matching the required Q1.15 rounding:
     *
     *   rounded = (value + 2^14) >>> 15
     */
    wire signed [ACC_W-1:0] round_const =
        ({{(ACC_W-1){1'b0}}, 1'b1} <<< (COEFF_W - 2));

    wire signed [ACC_W-1:0] tr_full =
        (rr_ext - ii_ext + round_const) >>> SHIFT;

    wire signed [ACC_W-1:0] ti_full =
        (ri_ext + ir_ext + round_const) >>> SHIFT;

    wire signed [IN_W-1:0] tr = tr_full[IN_W-1:0];
    wire signed [IN_W-1:0] ti = ti_full[IN_W-1:0];

    /*
     * Final butterfly add/subtract.
     * Outputs are intentionally IN_W wide to match the iterative datapath.
     * If values exceed IN_W, normal two's-complement truncation/wrap occurs.
     */
    wire signed [IN_W:0] y0_re_full = {a_re[IN_W-1], a_re} + {tr[IN_W-1], tr};
    wire signed [IN_W:0] y0_im_full = {a_im[IN_W-1], a_im} + {ti[IN_W-1], ti};
    wire signed [IN_W:0] y1_re_full = {a_re[IN_W-1], a_re} - {tr[IN_W-1], tr};
    wire signed [IN_W:0] y1_im_full = {a_im[IN_W-1], a_im} - {ti[IN_W-1], ti};

    assign y0_re = y0_re_full[IN_W-1:0];
    assign y0_im = y0_im_full[IN_W-1:0];
    assign y1_re = y1_re_full[IN_W-1:0];
    assign y1_im = y1_im_full[IN_W-1:0];

endmodule