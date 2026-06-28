`timescale 1ns/1ps

module fft16_butterfly #(
    parameter DATA_W  = 12,
    parameter GAIN_W  = 4,
    parameter COEFF_W = 16
) (
    input mode, // 0: FFT, 1: IFFT

    input  signed [DATA_W+GAIN_W-1:0] a_real,
    input  signed [DATA_W+GAIN_W-1:0] a_imag,
    input  signed [DATA_W+GAIN_W-1:0] b_real,
    input  signed [DATA_W+GAIN_W-1:0] b_imag,

    input  signed [COEFF_W-1:0] tw_cos,
    input  signed [COEFF_W-1:0] tw_sin,

    output reg signed [DATA_W+GAIN_W-1:0] y0_real,
    output reg signed [DATA_W+GAIN_W-1:0] y0_imag,
    output reg signed [DATA_W+GAIN_W-1:0] y1_real,
    output reg signed [DATA_W+GAIN_W-1:0] y1_imag
);

    localparam OUT_W  = DATA_W + GAIN_W;
    localparam PROD_W = OUT_W + COEFF_W;
    localparam ACC_W  = PROD_W + 2;

    localparam signed [ACC_W-1:0] Q15_ROUND =
        {{(ACC_W-15){1'b0}}, 1'b1, {14{1'b0}}};

    reg signed [PROD_W-1:0] br_cos;
    reg signed [PROD_W-1:0] bi_sin;
    reg signed [PROD_W-1:0] bi_cos;
    reg signed [PROD_W-1:0] br_sin;

    reg signed [ACC_W-1:0] acc_real;
    reg signed [ACC_W-1:0] acc_imag;

    reg signed [OUT_W-1:0] t_real;
    reg signed [OUT_W-1:0] t_imag;

    always @(*) begin
        br_cos = $signed(b_real) * $signed(tw_cos);
        bi_sin = $signed(b_imag) * $signed(tw_sin);
        bi_cos = $signed(b_imag) * $signed(tw_cos);
        br_sin = $signed(b_real) * $signed(tw_sin);

        if (mode == 1'b0) begin
            acc_real =
                {{(ACC_W-PROD_W){br_cos[PROD_W-1]}}, br_cos} +
                {{(ACC_W-PROD_W){bi_sin[PROD_W-1]}}, bi_sin} +
                Q15_ROUND;

            acc_imag =
                {{(ACC_W-PROD_W){bi_cos[PROD_W-1]}}, bi_cos} -
                {{(ACC_W-PROD_W){br_sin[PROD_W-1]}}, br_sin} +
                Q15_ROUND;
        end else begin
            acc_real =
                {{(ACC_W-PROD_W){br_cos[PROD_W-1]}}, br_cos} -
                {{(ACC_W-PROD_W){bi_sin[PROD_W-1]}}, bi_sin} +
                Q15_ROUND;

            acc_imag =
                {{(ACC_W-PROD_W){bi_cos[PROD_W-1]}}, bi_cos} +
                {{(ACC_W-PROD_W){br_sin[PROD_W-1]}}, br_sin} +
                Q15_ROUND;
        end

        t_real = acc_real >>> 15;
        t_imag = acc_imag >>> 15;

        y0_real = a_real + t_real;
        y0_imag = a_imag + t_imag;
        y1_real = a_real - t_real;
        y1_imag = a_imag - t_imag;
    end

endmodule