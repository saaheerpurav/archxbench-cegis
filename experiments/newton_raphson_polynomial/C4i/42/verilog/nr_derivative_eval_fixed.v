`timescale 1ns/1ps

module nr_derivative_eval_fixed #(
    parameter WIDTH = 16,
    parameter FRAC  = 8,
    parameter XW    = 64
)(
    input  signed [XW-1:0]    x,
    input  signed [WIDTH-1:0] coeff1,
    input  signed [WIDTH-1:0] coeff2,
    input  signed [WIDTH-1:0] coeff3,
    output signed [XW-1:0]    derivative
);

    wire signed [XW-1:0] c1_ext;
    wire signed [XW-1:0] c2_ext;
    wire signed [XW-1:0] c3_ext;

    wire signed [XW-1:0] two_c2;
    wire signed [XW-1:0] three_c3;

    wire signed [(2*XW)-1:0] mult0;
    wire signed [(2*XW)-1:0] mult1;

    wire signed [XW-1:0] stage0;
    wire signed [XW-1:0] stage1;

    assign c1_ext = {{(XW-WIDTH){coeff1[WIDTH-1]}}, coeff1};
    assign c2_ext = {{(XW-WIDTH){coeff2[WIDTH-1]}}, coeff2};
    assign c3_ext = {{(XW-WIDTH){coeff3[WIDTH-1]}}, coeff3};

    assign two_c2   = c2_ext << 1;
    assign three_c3 = (c3_ext << 1) + c3_ext;

    assign stage0 = three_c3;

    assign mult0  = stage0 * x;
    assign stage1 = (mult0 >>> FRAC) + two_c2;

    assign mult1      = stage1 * x;
    assign derivative = (mult1 >>> FRAC) + c1_ext;

endmodule