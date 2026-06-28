`timescale 1ns/1ps

module lowpass_fir #(
    parameter DATA_W  = 20,
    parameter TAP_CNT = 101,
    parameter GAIN_W  = 4
) (
    input                           clk,
    input                           rst,
    input                           valid_in,
    input      [DATA_W-1:0]         data_in,
    output                          valid_out,
    output     [DATA_W+GAIN_W-1:0]  data_out
);

    localparam OUT_W    = DATA_W + GAIN_W;
    localparam PAIR_CNT = (TAP_CNT - 1) / 2;
    localparam SUM_W    = DATA_W + 1;
    localparam COEFF_W  = 16;
    localparam PROD_W   = 64;
    localparam SHIFT    = 15;  // Coefficients are quantized with scale=32768.

    reg  [DATA_W*TAP_CNT-1:0] sample_taps_r;
    reg                       valid_out_r;
    reg  signed [OUT_W-1:0]   data_out_r;

    wire [DATA_W*TAP_CNT-1:0] next_sample_taps;
    wire [SUM_W*PAIR_CNT-1:0] pair_sums;
    wire signed [DATA_W-1:0]  center_sample;
    wire [COEFF_W*PAIR_CNT-1:0] pair_coeffs;
    wire signed [COEFF_W-1:0] center_coeff;
    wire [PROD_W*PAIR_CNT-1:0] products;
    wire signed [PROD_W-1:0]  center_product;
    wire signed [PROD_W-1:0]  acc_value;
    wire signed [OUT_W-1:0]   scaled_value;

    fir_tap_shift_next #(
        .DATA_W(DATA_W),
        .TAP_CNT(TAP_CNT)
    ) u_tap_shift_next (
        .data_in(data_in),
        .taps_cur(sample_taps_r),
        .taps_next(next_sample_taps)
    );

    fir_sym_preadd #(
        .DATA_W(DATA_W),
        .TAP_CNT(TAP_CNT)
    ) u_sym_preadd (
        .taps_in(next_sample_taps),
        .pair_sums(pair_sums),
        .center_sample(center_sample)
    );

    fir_coeff_rom_101 #(
        .COEFF_W(COEFF_W),
        .PAIR_CNT(PAIR_CNT)
    ) u_coeff_rom (
        .pair_coeffs(pair_coeffs),
        .center_coeff(center_coeff)
    );

    fir_product_bank #(
        .DATA_W(DATA_W),
        .SUM_W(SUM_W),
        .COEFF_W(COEFF_W),
        .PAIR_CNT(PAIR_CNT),
        .PROD_W(PROD_W)
    ) u_product_bank (
        .pair_sums(pair_sums),
        .center_sample(center_sample),
        .pair_coeffs(pair_coeffs),
        .center_coeff(center_coeff),
        .products(products),
        .center_product(center_product)
    );

    fir_accumulator_tree #(
        .PAIR_CNT(PAIR_CNT),
        .PROD_W(PROD_W)
    ) u_accumulator (
        .products(products),
        .center_product(center_product),
        .acc_out(acc_value)
    );

    fir_output_scale #(
        .IN_W(PROD_W),
        .OUT_W(OUT_W),
        .SHIFT(SHIFT)
    ) u_output_scale (
        .acc_in(acc_value),
        .data_out(scaled_value)
    );

    always @(posedge clk) begin
        if (rst) begin
            sample_taps_r <= {DATA_W*TAP_CNT{1'b0}};
            valid_out_r   <= 1'b0;
            data_out_r    <= {OUT_W{1'b0}};
        end else begin
            valid_out_r <= valid_in;

            if (valid_in) begin
                sample_taps_r <= next_sample_taps;
                data_out_r    <= scaled_value;
            end
        end
    end

    assign valid_out = valid_out_r;
    assign data_out  = data_out_r;

endmodule