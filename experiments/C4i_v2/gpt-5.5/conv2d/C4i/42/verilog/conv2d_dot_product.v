`timescale 1ns/1ps

module conv2d_dot_product #(
    parameter DATA_W      = 8,
    parameter KERNEL_SIZE = 3,
    parameter GAIN_W      = 4,
    parameter COEFF_W     = 16,
    parameter ACC_W       = DATA_W + GAIN_W + 16
) (
    input  [KERNEL_SIZE*KERNEL_SIZE*DATA_W-1:0]   window_flat,
    input  [KERNEL_SIZE*KERNEL_SIZE*COEFF_W-1:0]  coeffs_flat,
    output reg [DATA_W+GAIN_W-1:0]                pixel_out
);

    localparam K2    = KERNEL_SIZE * KERNEL_SIZE;
    localparam OUT_W = DATA_W + GAIN_W;

    integer i;

    reg [DATA_W-1:0]         pix;
    reg signed [COEFF_W-1:0] coeff;

    reg signed [ACC_W-1:0] acc;
    reg signed [ACC_W-1:0] term;
    reg signed [ACC_W-1:0] coeff_sum;
    reg signed [ACC_W-1:0] scaled_acc;
    reg signed [ACC_W-1:0] max_val;

    always @* begin
        acc       = {ACC_W{1'b0}};
        coeff_sum = {ACC_W{1'b0}};

        for (i = 0; i < K2; i = i + 1) begin
            pix   = window_flat[(i*DATA_W) +: DATA_W];
            coeff = coeffs_flat[(i*COEFF_W) +: COEFF_W];

            /*
             * Pixels are unsigned image samples.  Coefficients are signed.
             * Extend the pixel with a leading zero before signed multiply.
             */
            term = $signed({1'b0, pix}) * coeff;
            acc  = acc + term;

            coeff_sum = coeff_sum + coeff;
        end

        /*
         * The default coefficient ROM supplies integer binomial/Gaussian-style
         * kernels.  For the default 3x3 kernel:
         *
         *   1 2 1
         *   2 4 2
         *   1 2 1
         *
         * the coefficient sum is 16.  The golden output expects the normalized
         * convolution value, so divide by the coefficient sum when nonzero.
         *
         * For zero-sum kernels, leave the raw accumulator unchanged.
         */
        if ((coeff_sum != 0) && (coeff_sum != 1))
            scaled_acc = acc / coeff_sum;
        else
            scaled_acc = acc;

        max_val = {{(ACC_W-OUT_W){1'b0}}, {OUT_W{1'b1}}};

        if (scaled_acc < 0) begin
            pixel_out = {OUT_W{1'b0}};
        end else if (scaled_acc > max_val) begin
            pixel_out = {OUT_W{1'b1}};
        end else begin
            pixel_out = scaled_acc[OUT_W-1:0];
        end
    end

endmodule