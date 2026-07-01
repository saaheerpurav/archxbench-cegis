`timescale 1ns/1ps

module nr_derivative_eval_cubic #(
    parameter WIDTH = 16,
    parameter FRAC  = 8,
    parameter EXT   = WIDTH * 4
)(
    input  signed [WIDTH-1:0] x,
    input  signed [WIDTH-1:0] coeff1,
    input  signed [WIDTH-1:0] coeff2,
    input  signed [WIDTH-1:0] coeff3,
    output signed [EXT-1:0]   dp
);

    wire signed [EXT-1:0] x_ext  = {{(EXT-WIDTH){x[WIDTH-1]}},      x};
    wire signed [EXT-1:0] c1_ext = {{(EXT-WIDTH){coeff1[WIDTH-1]}}, coeff1};
    wire signed [EXT-1:0] c2_ext = {{(EXT-WIDTH){coeff2[WIDTH-1]}}, coeff2};
    wire signed [EXT-1:0] c3_ext = {{(EXT-WIDTH){coeff3[WIDTH-1]}}, coeff3};

    wire signed [EXT-1:0] two_c2   = c2_ext << 1;
    wire signed [EXT-1:0] three_c3 = (c3_ext << 1) + c3_ext;

    wire signed [(2*EXT)-1:0] prod0 = three_c3 * x_ext;
    wire signed [EXT-1:0]     term0 = prod0 >>> FRAC;

    wire signed [EXT-1:0] h0 = term0 + two_c2;

    wire signed [(2*EXT)-1:0] prod1 = h0 * x_ext;
    wire signed [EXT-1:0]     term1 = prod1 >>> FRAC;

    assign dp = term1 + c1_ext;

endmodule