`timescale 1ns/1ps

module nr_fixed_div #(
    parameter WIDTH = 16,
    parameter FRAC  = 8
)(
    input  signed [WIDTH-1:0] numerator,
    input  signed [WIDTH-1:0] denominator,
    output signed [WIDTH-1:0] quotient
);

    localparam EXT = WIDTH * 4;

    wire signed [EXT-1:0] numerator_ext;
    wire signed [EXT-1:0] denominator_ext;
    wire signed [EXT-1:0] shifted_numerator;
    wire signed [EXT-1:0] quotient_ext;

    assign numerator_ext   = {{(EXT-WIDTH){numerator[WIDTH-1]}}, numerator};
    assign denominator_ext = {{(EXT-WIDTH){denominator[WIDTH-1]}}, denominator};

    assign shifted_numerator = numerator_ext << FRAC;

    assign quotient_ext = (denominator == {WIDTH{1'b0}})
                        ? {EXT{1'b0}}
                        : shifted_numerator / denominator_ext;

    assign quotient = quotient_ext[WIDTH-1:0];

endmodule