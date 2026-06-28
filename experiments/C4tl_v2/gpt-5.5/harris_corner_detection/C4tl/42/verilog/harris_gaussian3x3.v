```verilog
`timescale 1ns/1ps

module harris_gaussian3x3 #(
    parameter IN_W  = 32,
    parameter OUT_W = 36
) (
    input  signed [IN_W-1:0] d00,
    input  signed [IN_W-1:0] d01,
    input  signed [IN_W-1:0] d02,
    input  signed [IN_W-1:0] d10,
    input  signed [IN_W-1:0] d11,
    input  signed [IN_W-1:0] d12,
    input  signed [IN_W-1:0] d20,
    input  signed [IN_W-1:0] d21,
    input  signed [IN_W-1:0] d22,
    output signed [OUT_W-1:0] dout
);

    /*
     * 3x3 Gaussian kernel:
     *
     *     1 2 1
     *     2 4 2   / 16
     *     1 2 1
     *
     * The unnormalized weighted sum can be up to 16 times the input
     * magnitude, so use at least IN_W + 4 signed bits internally.
     */
    localparam integer SUM_W = (OUT_W > (IN_W + 4)) ? OUT_W : (IN_W + 4);
    localparam integer EXT_W = SUM_W - IN_W;

    wire signed [SUM_W-1:0] s00 = {{EXT_W{d00[IN_W-1]}}, d00};
    wire signed [SUM_W-1:0] s01 = {{EXT_W{d01[IN_W-1]}}, d01};
    wire signed [SUM_W-1:0] s02 = {{EXT_W{d02[IN_W-1]}}, d02};

    wire signed [SUM_W-1:0] s10 = {{EXT_W{d10[IN_W-1]}}, d10};
    wire signed [SUM_W-1:0] s11 = {{EXT_W{d11[IN_W-1]}}, d11};
    wire signed [SUM_W-1:0] s12 = {{EXT_W{d12[IN_W-1]}}, d12};

    wire signed [SUM_W-1:0] s20 = {{EXT_W{d20[IN_W-1]}}, d20};
    wire signed [SUM_W-1:0] s21 = {{EXT_W{d21[IN_W-1]}}, d21};
    wire signed [SUM_W-1:0] s22 = {{EXT_W{d22[IN_W-1]}}, d22};

    wire signed [SUM_W-1:0] weighted_sum;

    assign weighted_sum =
          s00 + (s01 <<< 1) + s02
        + (s10 <<< 1) + (s11 <<< 2) + (s12 <<< 1)
        + s20 + (s21 <<< 1) + s22;

    assign dout = weighted_sum >>> 4;

endmodule
```