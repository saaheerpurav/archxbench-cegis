`timescale 1ns/1ps

module nr_poly_derivative_fixed #(
    parameter WIDTH = 16,
    parameter FRAC = 8,
    parameter EXT_WIDTH = 64
)(
    input  signed [WIDTH-1:0] x,
    input  signed [WIDTH-1:0] coeff1,
    input  signed [WIDTH-1:0] coeff2,
    input  signed [WIDTH-1:0] coeff3,
    output signed [EXT_WIDTH-1:0] derivative,
    output derivative_zero
);

    wire signed [EXT_WIDTH-1:0] x_ext;
    wire signed [EXT_WIDTH-1:0] c1_ext;
    wire signed [EXT_WIDTH-1:0] c2_ext;
    wire signed [EXT_WIDTH-1:0] c3_ext;

    wire signed [EXT_WIDTH-1:0] two_c2;
    wire signed [EXT_WIDTH-1:0] three_c3;

    wire signed [(2*EXT_WIDTH)-1:0] prod_c3_x;
    wire signed [(2*EXT_WIDTH)-1:0] prod_horner_x;

    wire signed [EXT_WIDTH-1:0] three_c3_x;
    wire signed [EXT_WIDTH-1:0] horner_mid;

    assign x_ext  = {{(EXT_WIDTH-WIDTH){x[WIDTH-1]}}, x};
    assign c1_ext = {{(EXT_WIDTH-WIDTH){coeff1[WIDTH-1]}}, coeff1};
    assign c2_ext = {{(EXT_WIDTH-WIDTH){coeff2[WIDTH-1]}}, coeff2};
    assign c3_ext = {{(EXT_WIDTH-WIDTH){coeff3[WIDTH-1]}}, coeff3};

    assign two_c2   = c2_ext << 1;
    assign three_c3 = (c3_ext << 1) + c3_ext;

    assign prod_c3_x = three_c3 * x_ext;
    assign three_c3_x = prod_c3_x >>> FRAC;

    assign horner_mid = three_c3_x + two_c2;

    assign prod_horner_x = horner_mid * x_ext;
    assign derivative = (prod_horner_x >>> FRAC) + c1_ext;

    assign derivative_zero = (derivative == {EXT_WIDTH{1'b0}});

endmodule