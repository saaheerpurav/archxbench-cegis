`timescale 1ns/1ps

module nr_poly_eval_fixed #(
    parameter WIDTH = 16,
    parameter FRAC = 8,
    parameter EXT_WIDTH = 64
)(
    input  signed [WIDTH-1:0] x,
    input  signed [WIDTH-1:0] coeff0,
    input  signed [WIDTH-1:0] coeff1,
    input  signed [WIDTH-1:0] coeff2,
    input  signed [WIDTH-1:0] coeff3,
    output signed [EXT_WIDTH-1:0] poly
);

    wire signed [EXT_WIDTH-1:0] x_ext;
    wire signed [EXT_WIDTH-1:0] c0_ext;
    wire signed [EXT_WIDTH-1:0] c1_ext;
    wire signed [EXT_WIDTH-1:0] c2_ext;
    wire signed [EXT_WIDTH-1:0] c3_ext;

    wire signed [(2*EXT_WIDTH)-1:0] prod_c3_x;
    wire signed [(2*EXT_WIDTH)-1:0] prod_h0_x;
    wire signed [(2*EXT_WIDTH)-1:0] prod_h1_x;

    wire signed [EXT_WIDTH-1:0] h0;
    wire signed [EXT_WIDTH-1:0] h1;
    wire signed [EXT_WIDTH-1:0] h2;

    assign x_ext  = {{(EXT_WIDTH-WIDTH){x[WIDTH-1]}}, x};
    assign c0_ext = {{(EXT_WIDTH-WIDTH){coeff0[WIDTH-1]}}, coeff0};
    assign c1_ext = {{(EXT_WIDTH-WIDTH){coeff1[WIDTH-1]}}, coeff1};
    assign c2_ext = {{(EXT_WIDTH-WIDTH){coeff2[WIDTH-1]}}, coeff2};
    assign c3_ext = {{(EXT_WIDTH-WIDTH){coeff3[WIDTH-1]}}, coeff3};

    assign prod_c3_x = c3_ext * x_ext;
    assign h0 = (prod_c3_x >>> FRAC) + c2_ext;

    assign prod_h0_x = h0 * x_ext;
    assign h1 = (prod_h0_x >>> FRAC) + c1_ext;

    assign prod_h1_x = h1 * x_ext;
    assign h2 = (prod_h1_x >>> FRAC) + c0_ext;

    assign poly = h2;

endmodule