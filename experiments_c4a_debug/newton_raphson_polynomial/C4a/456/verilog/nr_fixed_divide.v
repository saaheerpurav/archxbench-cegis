`timescale 1ns/1ps

module nr_fixed_divide #(
    parameter WIDTH = 16,
    parameter FRAC = 8,
    parameter EXT_WIDTH = 64
)(
    input  signed [EXT_WIDTH-1:0] numerator,
    input  signed [EXT_WIDTH-1:0] denominator,
    input                         divide_by_zero,
    output signed [EXT_WIDTH-1:0] quotient
);

    wire signed [(2*EXT_WIDTH)-1:0] numerator_ext;
    wire signed [(2*EXT_WIDTH)-1:0] denominator_ext;
    wire signed [(2*EXT_WIDTH)-1:0] scaled_numerator;
    wire signed [(2*EXT_WIDTH)-1:0] quotient_ext;

    assign numerator_ext     = {{EXT_WIDTH{numerator[EXT_WIDTH-1]}}, numerator};
    assign denominator_ext   = {{EXT_WIDTH{denominator[EXT_WIDTH-1]}}, denominator};
    assign scaled_numerator  = numerator_ext << FRAC;

    assign quotient_ext = (divide_by_zero || (denominator == {EXT_WIDTH{1'b0}}))
                        ? {2*EXT_WIDTH{1'b0}}
                        : (scaled_numerator / denominator_ext);

    assign quotient = quotient_ext[EXT_WIDTH-1:0];

endmodule