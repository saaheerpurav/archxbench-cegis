`timescale 1ns/1ps

module fp_mult_normalize (
    input [47:0] product,
    input signed [10:0] exp_in,
    output [23:0] mantissa,
    output guard_bit,
    output round_bit,
    output sticky_bit,
    output signed [10:0] exp_out
);

wire product_overflow;

assign product_overflow = product[47];

assign mantissa   = product_overflow ? product[47:24] : product[46:23];
assign guard_bit  = product_overflow ? product[23]    : product[22];
assign round_bit  = product_overflow ? product[22]    : product[21];
assign sticky_bit = product_overflow ? |product[21:0] : |product[20:0];
assign exp_out    = product_overflow ? (exp_in + 11'sd1) : exp_in;

endmodule