`timescale 1ns/1ps

module fp_addsub (
    input a_sign,
    input b_sign,
    input [27:0] a_mant,
    input [27:0] b_mant,
    output result_sign,
    output [27:0] result_mant,
    output is_zero
);

wire same_sign;
wire a_ge_b;
wire [27:0] add_mant;
wire [27:0] sub_mant;
wire sub_sign;

assign same_sign = (a_sign == b_sign);
assign a_ge_b = (a_mant >= b_mant);

assign add_mant = a_mant + b_mant;
assign sub_mant = a_ge_b ? (a_mant - b_mant) : (b_mant - a_mant);
assign sub_sign = a_ge_b ? a_sign : b_sign;

assign result_mant = same_sign ? add_mant : sub_mant;
assign is_zero = (result_mant == 28'd0);

assign result_sign = is_zero ? 1'b0 :
                     same_sign ? a_sign :
                     sub_sign;

endmodule