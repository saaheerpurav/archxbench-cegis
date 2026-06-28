`timescale 1ns/1ps

module fft16_butterfly #(
    parameter IN_W    = 16,
    parameter COEFF_W = 16
) (
    input  signed [IN_W-1:0]    xp_real,
    input  signed [IN_W-1:0]    xp_imag,
    input  signed [IN_W-1:0]    xq_real,
    input  signed [IN_W-1:0]    xq_imag,
    input  signed [COEFF_W-1:0] tw_cos,
    input  signed [COEFF_W-1:0] tw_sin,
    output signed [IN_W-1:0]    yp_real,
    output signed [IN_W-1:0]    yp_imag,
    output signed [IN_W-1:0]    yq_real,
    output signed [IN_W-1:0]    yq_imag
);

    localparam integer FRAC_W = COEFF_W - 1;
    localparam integer PROD_W = IN_W + COEFF_W;
    localparam integer ACC_W  = PROD_W + 1;

    // Q1.(COEFF_W-1) rounding constant.
    // For COEFF_W=16 this is 2^14.
    localparam signed [ACC_W-1:0] ROUND_CONST =
        {{(ACC_W-COEFF_W+1){1'b0}}, 1'b1, {(COEFF_W-2){1'b0}}};

    // Complex twiddle multiply:
    //   (xq_real + j*xq_imag) * (tw_cos - j*tw_sin)
    //
    //   tr_real = xq_real*tw_cos + xq_imag*tw_sin
    //   tr_imag = xq_imag*tw_cos - xq_real*tw_sin
    //
    // Products are IN_W + COEFF_W bits.
    wire signed [PROD_W-1:0] prod_xr_cos = xq_real * tw_cos;
    wire signed [PROD_W-1:0] prod_xi_sin = xq_imag * tw_sin;
    wire signed [PROD_W-1:0] prod_xi_cos = xq_imag * tw_cos;
    wire signed [PROD_W-1:0] prod_xr_sin = xq_real * tw_sin;

    // Extend by one bit before adding/subtracting two full-width products.
    wire signed [ACC_W-1:0] prod_xr_cos_ext = {prod_xr_cos[PROD_W-1], prod_xr_cos};
    wire signed [ACC_W-1:0] prod_xi_sin_ext = {prod_xi_sin[PROD_W-1], prod_xi_sin};
    wire signed [ACC_W-1:0] prod_xi_cos_ext = {prod_xi_cos[PROD_W-1], prod_xi_cos};
    wire signed [ACC_W-1:0] prod_xr_sin_ext = {prod_xr_sin[PROD_W-1], prod_xr_sin};

    // Add the Q1.15 rounding constant before the arithmetic right shift.
    wire signed [ACC_W-1:0] tr_real_acc =
        prod_xr_cos_ext + prod_xi_sin_ext + ROUND_CONST;

    wire signed [ACC_W-1:0] tr_imag_acc =
        prod_xi_cos_ext - prod_xr_sin_ext + ROUND_CONST;

    wire signed [ACC_W-1:0] tr_real_shifted = tr_real_acc >>> FRAC_W;
    wire signed [ACC_W-1:0] tr_imag_shifted = tr_imag_acc >>> FRAC_W;

    // Keep IN_W bits. No saturation is specified.
    wire signed [IN_W-1:0] tr_real = tr_real_shifted[IN_W-1:0];
    wire signed [IN_W-1:0] tr_imag = tr_imag_shifted[IN_W-1:0];

    // Radix-2 butterfly outputs.
    assign yp_real = xp_real + tr_real;
    assign yp_imag = xp_imag + tr_imag;
    assign yq_real = xp_real - tr_real;
    assign yq_imag = xp_imag - tr_imag;

endmodule