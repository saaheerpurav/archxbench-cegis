`timescale 1ns/1ps

module harris_gaussian3x3 #(
    parameter IN_W  = 32,
    parameter OUT_W = 36
) (
    input  signed [IN_W-1:0]  p00,
    input  signed [IN_W-1:0]  p01,
    input  signed [IN_W-1:0]  p02,
    input  signed [IN_W-1:0]  p10,
    input  signed [IN_W-1:0]  p11,
    input  signed [IN_W-1:0]  p12,
    input  signed [IN_W-1:0]  p20,
    input  signed [IN_W-1:0]  p21,
    input  signed [IN_W-1:0]  p22,
    output signed [OUT_W-1:0] out
);

    /*
     * Gaussian kernel:
     *
     *     1 2 1
     *     2 4 2   / 16
     *     1 2 1
     *
     * The weighted sum can grow by up to a factor of 16, so the accumulator
     * must be wider than IN_W.  Use a width also larger than OUT_W so that
     * assignment to the output is well-defined for both truncation and normal
     * sign-preserving cases.
     */
    localparam integer SUM_W = ((IN_W > OUT_W) ? IN_W : OUT_W) + 5;

    function signed [SUM_W-1:0] sext;
        input signed [IN_W-1:0] v;
        begin
            sext = {{(SUM_W-IN_W){v[IN_W-1]}}, v};
        end
    endfunction

    wire signed [SUM_W-1:0] row0;
    wire signed [SUM_W-1:0] row1;
    wire signed [SUM_W-1:0] row2;
    wire signed [SUM_W-1:0] sum_w;
    wire signed [SUM_W-1:0] div_w;

    assign row0 =  sext(p00) + (sext(p01) <<< 1) +  sext(p02);
    assign row1 = (sext(p10) <<< 1) + (sext(p11) <<< 2) + (sext(p12) <<< 1);
    assign row2 =  sext(p20) + (sext(p21) <<< 1) +  sext(p22);

    assign sum_w = row0 + row1 + row2;

    /*
     * Arithmetic shift preserves the sign for Ix*Iy smoothing.
     * This is the hardware fixed-point divide-by-16 operation.
     */
    assign div_w = sum_w >>> 4;

    assign out = div_w;

endmodule