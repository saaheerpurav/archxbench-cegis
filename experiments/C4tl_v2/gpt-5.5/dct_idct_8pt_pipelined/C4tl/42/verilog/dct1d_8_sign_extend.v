`timescale 1ns/1ps

module dct1d_8_sign_extend #(
    parameter DATA_W = 12
) (
    input  [DATA_W-1:0] din,
    output signed [DATA_W-1:0] dout
);

    /*
     * Preserve the exact input bit pattern while explicitly interpreting it
     * as a signed two's-complement fixed-point value for downstream arithmetic.
     *
     * Since din and dout have the same width, no bits are added or removed.
     * The cast makes the signed interpretation explicit.
     */
    assign dout = $signed(din);

endmodule