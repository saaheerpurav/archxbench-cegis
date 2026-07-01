`timescale 1ns/1ps

module fp_mult_normalize (
    input signed [10:0] exp_sum_unbiased,
    input [47:0] product,
    output signed [10:0] norm_exp_unbiased,
    output [23:0] norm_sig,
    output guard_bit,
    output round_bit,
    output sticky_bit
);

wire product_overflow = product[47];

assign norm_exp_unbiased = product_overflow
                         ? exp_sum_unbiased + 11'sd1
                         : exp_sum_unbiased;

assign norm_sig = product_overflow
                ? product[47:24]
                : product[46:23];

assign guard_bit = product_overflow
                 ? product[23]
                 : product[22];

assign round_bit = product_overflow
                 ? product[22]
                 : product[21];

assign sticky_bit = product_overflow
                  ? |product[21:0]
                  : |product[20:0];

endmodule