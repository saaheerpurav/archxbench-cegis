`timescale 1ns/1ps

module bandpass_fir #(
    parameter DATA_W  = 20,
    parameter TAP_CNT = 101,
    parameter GAIN_W  = 4
) (
    input                          clk,
    input                          rst,
    input                          valid_in,
    input      [DATA_W-1:0]        data_in,
    output                         valid_out,
    output     [DATA_W+GAIN_W-1:0] data_out
);

    localparam OUT_W   = DATA_W + GAIN_W;
    localparam COEFF_W = 16;
    localparam PROD_W  = 64;
    localparam ACC_W   = 64;

    reg signed [DATA_W-1:0] samples [0:TAP_CNT-1];
    reg                     valid_out_r;
    reg signed [OUT_W-1:0]  data_out_r;

    wire signed [DATA_W-1:0] data_in_s;
    wire signed [COEFF_W-1:0] coeff [0:TAP_CNT-1];
    wire signed [PROD_W-1:0]  product [0:TAP_CNT-1];
    wire signed [PROD_W*TAP_CNT-1:0] product_bus;
    wire signed [ACC_W-1:0] acc_sum;
    wire signed [ACC_W-1:0] scaled_sum;

    integer i;

    assign data_in_s  = data_in;
    assign scaled_sum = acc_sum >>> 20;
    assign valid_out  = valid_out_r;
    assign data_out   = data_out_r;

    genvar g;
    generate
        for (g = 0; g < TAP_CNT; g = g + 1) begin : GEN_TAPS
            wire signed [DATA_W-1:0] tap_sample;

            assign tap_sample = (g == 0) ? data_in_s : samples[g-1];
            assign product_bus[(g*PROD_W) +: PROD_W] = product[g];

            bpf_coeff_rom #(
                .COEFF_W(COEFF_W)
            ) coeff_i (
                .addr(g[7:0]),
                .coeff(coeff[g])
            );

            bpf_tap_product #(
                .DATA_W(DATA_W),
                .COEFF_W(COEFF_W),
                .PROD_W(PROD_W)
            ) product_i (
                .sample(tap_sample),
                .coeff(coeff[g]),
                .product(product[g])
            );
        end
    endgenerate

    bpf_mac_sum #(
        .TAP_CNT(TAP_CNT),
        .PROD_W(PROD_W),
        .ACC_W(ACC_W)
    ) mac_sum_i (
        .products(product_bus),
        .sum(acc_sum)
    );

    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < TAP_CNT; i = i + 1)
                samples[i] <= {DATA_W{1'b0}};
            valid_out_r <= 1'b0;
            data_out_r  <= {OUT_W{1'b0}};
        end else begin
            valid_out_r <= valid_in;

            if (valid_in) begin
                samples[0] <= data_in_s;
                for (i = 1; i < TAP_CNT; i = i + 1)
                    samples[i] <= samples[i-1];

                data_out_r <= scaled_sum[OUT_W-1:0];
            end
        end
    end

endmodule