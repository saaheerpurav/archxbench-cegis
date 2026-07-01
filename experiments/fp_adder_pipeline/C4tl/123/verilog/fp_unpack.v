`timescale 1ns/1ps

module fp_unpack (
    input [31:0] operand,
    output sign,
    output [7:0] exponent,
    output [22:0] fraction,
    output is_zero,
    output is_inf,
    output is_nan
);

assign sign     = operand[31];
assign exponent = operand[30:23];
assign fraction = operand[22:0];

assign is_zero = (exponent == 8'h00) && (fraction == 23'h000000);
assign is_inf  = (exponent == 8'hFF) && (fraction == 23'h000000);
assign is_nan  = (exponent == 8'hFF) && (fraction != 23'h000000);

endmodule