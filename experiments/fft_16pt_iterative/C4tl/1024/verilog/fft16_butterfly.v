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
    output signed [DATA_W-1:0] a_real_out,
    output signed [DATA_W-1:0] a_imag_out,
    output signed [DATA_W-1:0] b_real_out,
    output signed [DATA_W-1:0] b_imag_out
);

    localparam SHIFT = COEFF_W - 1;
    localparam PROD_W = DATA_W + COEFF_W;
    localparam ACC_W = PROD_W + 2;

    wire signed [PROD_W-1:0] prod_rr = b_real * tw_cos;
    wire signed [PROD_W-1:0] prod_is = b_imag * tw_sin;
    wire signed [PROD_W-1:0] prod_ic = b_imag * tw_cos;
    wire signed [PROD_W-1:0] prod_rs = b_real * tw_sin;

    wire signed [ACC_W-1:0] round_const = {{(ACC_W-COEFF_W){1'b0}}, 1'b1, {(COEFF_W-2){1'b0}}};

    wire signed [ACC_W-1:0] tr_real_acc =
        {{(ACC_W-PROD_W){prod_rr[PROD_W-1]}}, prod_rr} +
        {{(ACC_W-PROD_W){prod_is[PROD_W-1]}}, prod_is} +
        round_const;

    wire signed [ACC_W-1:0] tr_imag_acc =
        {{(ACC_W-PROD_W){prod_ic[PROD_W-1]}}, prod_ic} -
        {{(ACC_W-PROD_W){prod_rs[PROD_W-1]}}, prod_rs} +
        round_const;

    wire signed [ACC_W-1:0] tr_real = tr_real_acc >>> SHIFT;
    wire signed [ACC_W-1:0] tr_imag = tr_imag_acc >>> SHIFT;

    assign a_real_out = a_real + tr_real;
    assign a_imag_out = a_imag + tr_imag;
    assign b_real_out = a_real - tr_real;
    assign b_imag_out = a_imag - tr_imag;

endmodule