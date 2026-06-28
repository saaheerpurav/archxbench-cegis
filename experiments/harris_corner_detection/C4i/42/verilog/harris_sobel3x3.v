`timescale 1ns/1ps

module harris_sobel3x3 #(
    parameter PIXEL_W = 8,
    parameter GRAD_W  = 16
) (
    input  [PIXEL_W-1:0] p00,
    input  [PIXEL_W-1:0] p01,
    input  [PIXEL_W-1:0] p02,
    input  [PIXEL_W-1:0] p10,
    input  [PIXEL_W-1:0] p11,
    input  [PIXEL_W-1:0] p12,
    input  [PIXEL_W-1:0] p20,
    input  [PIXEL_W-1:0] p21,
    input  [PIXEL_W-1:0] p22,
    output signed [GRAD_W-1:0] gx,
    output signed [GRAD_W-1:0] gy
);

    /*
     * Maximum Sobel magnitude is:
     *
     *   4 * (2^PIXEL_W - 1)
     *
     * This requires PIXEL_W+3 signed bits, including sign.
     * Use at least GRAD_W internally so the normal configured output width
     * is not truncated before the final assignment.
     */
    localparam ACC_W = (GRAD_W > (PIXEL_W + 3)) ? GRAD_W : (PIXEL_W + 3);

    /*
     * Convert an unsigned pixel to a signed accumulator value.
     *
     * For real hardware inputs are 0/1.  During simulation, however, stencil
     * warmup or border windows may contain X/Z if upstream storage was not
     * fully initialized.  Treat any bit that is not a known 1 as 0 so that
     * those simulation-only unknowns do not propagate into gx/gy and then into
     * the JSON output as invalid 'x' values.
     */
    function signed [ACC_W-1:0] pix_s;
        input [PIXEL_W-1:0] v;
        integer i;
        begin
            pix_s = {ACC_W{1'b0}};
            for (i = 0; i < PIXEL_W; i = i + 1) begin
                pix_s[i] = (v[i] === 1'b1) ? 1'b1 : 1'b0;
            end
        end
    endfunction

    wire signed [ACC_W-1:0] gx_pos;
    wire signed [ACC_W-1:0] gx_neg;
    wire signed [ACC_W-1:0] gy_pos;
    wire signed [ACC_W-1:0] gy_neg;

    wire signed [ACC_W-1:0] gx_acc;
    wire signed [ACC_W-1:0] gy_acc;

    /*
     * Gx kernel:
     *
     *   -1  0 +1
     *   -2  0 +2
     *   -1  0 +1
     */
    assign gx_pos = pix_s(p02) + (pix_s(p12) <<< 1) + pix_s(p22);
    assign gx_neg = pix_s(p00) + (pix_s(p10) <<< 1) + pix_s(p20);
    assign gx_acc = gx_pos - gx_neg;

    /*
     * Gy kernel:
     *
     *   -1 -2 -1
     *    0  0  0
     *   +1 +2 +1
     */
    assign gy_pos = pix_s(p20) + (pix_s(p21) <<< 1) + pix_s(p22);
    assign gy_neg = pix_s(p00) + (pix_s(p01) <<< 1) + pix_s(p02);
    assign gy_acc = gy_pos - gy_neg;

    /*
     * p11 is intentionally unused by the Sobel kernels.
     * The final assignment keeps the low GRAD_W two's-complement bits.
     */
    assign gx = gx_acc[GRAD_W-1:0];
    assign gy = gy_acc[GRAD_W-1:0];

endmodule