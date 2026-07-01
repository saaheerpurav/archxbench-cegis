`timescale 1ns/1ps

module fp_mult_unpack (
    input [31:0] a,
    input [31:0] b,
    output sign,
    output [7:0] exp_a,
    output [7:0] exp_b,
    output [23:0] sig_a,
    output [23:0] sig_b,
    output zero_a,
    output zero_b,
    output inf_a,
    output inf_b,
    output nan_a,
    output nan_b,
    output sub_a,
    output sub_b
);

wire sign_a;
wire sign_b;
wire [22:0] frac_a;
wire [22:0] frac_b;

assign sign_a = a[31];
assign sign_b = b[31];

assign exp_a = a[30:23];
assign exp_b = b[30:23];

assign frac_a = a[22:0];
assign frac_b = b[22:0];

assign sign = sign_a ^ sign_b;

assign zero_a = (exp_a == 8'h00) && (frac_a == 23'b0);
assign zero_b = (exp_b == 8'h00) && (frac_b == 23'b0);

assign inf_a = (exp_a == 8'hff) && (frac_a == 23'b0);
assign inf_b = (exp_b == 8'hff) && (frac_b == 23'b0);

assign nan_a = (exp_a == 8'hff) && (frac_a != 23'b0);
assign nan_b = (exp_b == 8'hff) && (frac_b != 23'b0);

assign sub_a = (exp_a == 8'h00) && (frac_a != 23'b0);
assign sub_b = (exp_b == 8'h00) && (frac_b != 23'b0);

assign sig_a = (exp_a == 8'h00) ? {1'b0, frac_a} : {1'b1, frac_a};
assign sig_b = (exp_b == 8'h00) ? {1'b0, frac_b} : {1'b1, frac_b};

endmodule