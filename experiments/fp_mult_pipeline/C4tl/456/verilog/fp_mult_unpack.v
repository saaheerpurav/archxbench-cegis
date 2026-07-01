`timescale 1ns/1ps

module fp_mult_unpack (
    input [31:0] a,
    input [31:0] b,
    output sign,
    output [7:0] exp_a,
    output [7:0] exp_b,
    output [22:0] frac_a,
    output [22:0] frac_b,
    output [23:0] sig_a,
    output [23:0] sig_b,
    output zero_a,
    output zero_b,
    output inf_a,
    output inf_b,
    output nan_a,
    output nan_b
);
    assign sign = a[31] ^ b[31];

    assign exp_a = a[30:23];
    assign exp_b = b[30:23];

    assign frac_a = a[22:0];
    assign frac_b = b[22:0];

    assign sig_a = (exp_a == 8'b0) ? {1'b0, frac_a} : {1'b1, frac_a};
    assign sig_b = (exp_b == 8'b0) ? {1'b0, frac_b} : {1'b1, frac_b};

    assign zero_a = (exp_a == 8'h00) && (frac_a == 23'b0);
    assign zero_b = (exp_b == 8'h00) && (frac_b == 23'b0);

    assign inf_a = (exp_a == 8'hFF) && (frac_a == 23'b0);
    assign inf_b = (exp_b == 8'hFF) && (frac_b == 23'b0);

    assign nan_a = (exp_a == 8'hFF) && (frac_a != 23'b0);
    assign nan_b = (exp_b == 8'hFF) && (frac_b != 23'b0);
endmodule