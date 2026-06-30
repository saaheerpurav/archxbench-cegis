`timescale 1ns/1ps

module nr_poly_eval_fixed #(
    parameter WIDTH = 16,
    parameter FRAC  = 8,
    parameter XW    = 64
)(
    input  signed [XW-1:0]    x,
    input  signed [WIDTH-1:0] coeff0,
    input  signed [WIDTH-1:0] coeff1,
    input  signed [WIDTH-1:0] coeff2,
    input  signed [WIDTH-1:0] coeff3,
    output signed [XW-1:0]    poly
);

    localparam IW = 4 * XW;

    wire signed [IW-1:0] x_ext;
    wire signed [IW-1:0] c0_ext;
    wire signed [IW-1:0] c1_ext;
    wire signed [IW-1:0] c2_ext;
    wire signed [IW-1:0] c3_ext;

    wire signed [(2*IW)-1:0] prod0;
    wire signed [(2*IW)-1:0] prod1;
    wire signed [(2*IW)-1:0] prod2;

    wire signed [IW-1:0] stage1;
    wire signed [IW-1:0] stage2;
    wire signed [IW-1:0] poly_wide;

    assign x_ext  = {{(IW-XW){x[XW-1]}}, x};

    assign c0_ext = {{(IW-WIDTH){coeff0[WIDTH-1]}}, coeff0};
    assign c1_ext = {{(IW-WIDTH){coeff1[WIDTH-1]}}, coeff1};
    assign c2_ext = {{(IW-WIDTH){coeff2[WIDTH-1]}}, coeff2};
    assign c3_ext = {{(IW-WIDTH){coeff3[WIDTH-1]}}, coeff3};

    assign prod0     = c3_ext * x_ext;
    assign stage1    = (prod0 >>> FRAC) + c2_ext;

    assign prod1     = stage1 * x_ext;
    assign stage2    = (prod1 >>> FRAC) + c1_ext;

    assign prod2     = stage2 * x_ext;
    assign poly_wide = (prod2 >>> FRAC) + c0_ext;

    assign poly = poly_wide[XW-1:0];

endmodule