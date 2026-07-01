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
wire [7:0] raw_exp_a;
wire [7:0] raw_exp_b;
wire [22:0] frac_a;
wire [22:0] frac_b;

assign sign_a = a[31];
assign sign_b = b[31];

assign raw_exp_a = a[30:23];
assign raw_exp_b = b[30:23];

assign frac_a = a[22:0];
assign frac_b = b[22:0];

assign sign = sign_a ^ sign_b;

assign exp_a = raw_exp_a;
assign exp_b = raw_exp_b;

assign zero_a = (raw_exp_a == 8'h00) && (frac_a == 23'b0);
assign zero_b = (raw_exp_b == 8'h00) && (frac_b == 23'b0);

assign sub_a = (raw_exp_a == 8'h00) && (frac_a != 23'b0);
assign sub_b = (raw_exp_b == 8'h00) && (frac_b != 23'b0);

assign inf_a = (raw_exp_a == 8'hff) && (frac_a == 23'b0);
assign inf_b = (raw_exp_b == 8'hff) && (frac_b == 23'b0);

assign nan_a = (raw_exp_a == 8'hff) && (frac_a != 23'b0);
assign nan_b = (raw_exp_b == 8'hff) && (frac_b != 23'b0);

assign sig_a = (raw_exp_a == 8'h00) ? {1'b0, frac_a} : {1'b1, frac_a};
assign sig_b = (raw_exp_b == 8'h00) ? {1'b0, frac_b} : {1'b1, frac_b};

endmodule