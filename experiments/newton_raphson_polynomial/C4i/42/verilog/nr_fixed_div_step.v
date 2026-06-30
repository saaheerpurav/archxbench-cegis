`timescale 1ns/1ps

module nr_fixed_div_step #(
    parameter FRAC = 8,
    parameter XW = 64
)(
    input  signed [XW-1:0] numerator,
    input  signed [XW-1:0] denominator,
    output signed [XW-1:0] quotient
);

    wire signed [(2*XW)-1:0] scaled_numerator;
    wire signed [(2*XW)-1:0] denominator_ext;
    wire signed [(2*XW)-1:0] quotient_ext;

    assign scaled_numerator = {{XW{numerator[XW-1]}}, numerator} << FRAC;
    assign denominator_ext   = {{XW{denominator[XW-1]}}, denominator};

    assign quotient_ext = (denominator == {XW{1'b0}})
                        ? {(2*XW){1'b0}}
                        : (scaled_numerator / denominator_ext);

    assign quotient = quotient_ext[XW-1:0];

endmodule