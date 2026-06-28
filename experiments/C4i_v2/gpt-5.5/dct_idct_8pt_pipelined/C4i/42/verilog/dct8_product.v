`timescale 1ns/1ps

module dct8_product #(
    parameter DATA_W  = 12,
    parameter COEFF_W = 16,
    parameter PROD_W  = DATA_W + COEFF_W
) (
    input  signed [DATA_W-1:0]  sample,
    input  signed [COEFF_W-1:0] coeff,
    output signed [PROD_W-1:0]  product
);

    localparam FULL_W = DATA_W + COEFF_W;

    wire signed [FULL_W-1:0] sample_ext;
    wire signed [FULL_W-1:0] coeff_ext;
    wire signed [FULL_W-1:0] product_full;

    /*
     * Explicitly sign-extend both operands to the natural product width before
     * multiplication.  This avoids relying on tool-specific multiplication
     * expression sizing.
     */
    assign sample_ext = {{COEFF_W{sample[DATA_W-1]}}, sample};
    assign coeff_ext  = {{DATA_W{coeff[COEFF_W-1]}}, coeff};

    /*
     * The mathematical product of a DATA_W signed value and a COEFF_W signed
     * value fits in DATA_W + COEFF_W bits.
     */
    assign product_full = sample_ext * coeff_ext;

    /*
     * Signed assignment handles the normal case, truncation if PROD_W is
     * smaller, and sign-extension if PROD_W is larger.
     */
    assign product = product_full;

endmodule