`timescale 1ns/1ps

module ifft16_output_scale #(
    parameter IN_W  = 16,
    parameter OUT_W = 16,
    parameter SHIFT = 4
) (
    input  mode_ifft,
    input  signed [IN_W-1:0]  in_val,
    output signed [OUT_W-1:0] out_val
);

    /*
     * Final IFFT scaling.
     *
     * A 16-point IFFT requires division by 16 after the butterfly stages.
     * This is equivalent to an arithmetic right shift by 4 bits.
     *
     * For signed two's-complement values, >>> preserves the sign bit.
     * Example:
     *   +32 >>> 4 = +2
     *   -32 >>> 4 = -2
     *   -17 >>> 4 = -2  // arithmetic shift, not truncation toward zero
     *
     * In FFT mode, no final divide-by-N scaling is applied here.
     */
    wire signed [IN_W-1:0] scaled_val;
    wire signed [IN_W-1:0] selected_val;

    assign scaled_val   = in_val >>> SHIFT;
    assign selected_val = mode_ifft ? scaled_val : in_val;

    /*
     * Width adaptation.
     *
     * The default design uses IN_W == OUT_W == 16, but this generate block
     * keeps the module safe for other parameterizations by sign-extending
     * when OUT_W is wider and truncating when OUT_W is narrower.
     */
    generate
        if (OUT_W > IN_W) begin : gen_sign_extend
            assign out_val = {{(OUT_W-IN_W){selected_val[IN_W-1]}}, selected_val};
        end else if (OUT_W == IN_W) begin : gen_same_width
            assign out_val = selected_val;
        end else begin : gen_truncate
            assign out_val = selected_val[OUT_W-1:0];
        end
    endgenerate

endmodule