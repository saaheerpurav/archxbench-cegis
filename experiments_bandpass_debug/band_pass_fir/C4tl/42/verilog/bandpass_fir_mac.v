`timescale 1ns/1ps

module bandpass_fir_mac #(
    parameter DATA_W  = 20,
    parameter TAP_CNT = 101,
    parameter COEFF_W = 16,
    parameter ACC_W   = 64
) (
    input      [DATA_W*TAP_CNT-1:0]   sample_bus,
    input      [COEFF_W*TAP_CNT-1:0]  coeff_bus,
    output reg signed [ACC_W-1:0]     acc_sum
);

    integer i;

    reg signed [DATA_W-1:0]  sample_i;
    reg signed [COEFF_W-1:0] coeff_i;
    reg signed [DATA_W+COEFF_W-1:0] product_i;

    always @* begin
        acc_sum = {ACC_W{1'b0}};

        for (i = 0; i < TAP_CNT; i = i + 1) begin
            sample_i  = sample_bus[i*DATA_W +: DATA_W];
            coeff_i   = coeff_bus[i*COEFF_W +: COEFF_W];
            product_i = sample_i * coeff_i;
            acc_sum   = acc_sum + {{(ACC_W-(DATA_W+COEFF_W)){product_i[DATA_W+COEFF_W-1]}}, product_i};
        end
    end

endmodule