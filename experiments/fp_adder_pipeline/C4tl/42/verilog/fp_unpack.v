`timescale 1ns/1ps

module fp_unpack (
    input [31:0] a,
    input [31:0] b,
    input add_sub,
    output sign_a,
    output sign_b,
    output [7:0] exp_a,
    output [7:0] exp_b,
    output [26:0] sig_a,
    output [26:0] sig_b,
    output a_zero,
    output b_zero,
    output a_inf,
    output b_inf,
    output a_nan,
    output b_nan
);

wire [22:0] frac_a;
wire [22:0] frac_b;

assign sign_a = a[31];
assign sign_b = b[31] ^ add_sub;

assign exp_a = a[30:23];
assign exp_b = b[30:23];

assign frac_a = a[22:0];
assign frac_b = b[22:0];

assign a_zero = (exp_a == 8'h00) && (frac_a == 23'b0);
assign b_zero = (exp_b == 8'h00) && (frac_b == 23'b0);

assign a_inf = (exp_a == 8'hff) && (frac_a == 23'b0);
assign b_inf = (exp_b == 8'hff) && (frac_b == 23'b0);

assign a_nan = (exp_a == 8'hff) && (frac_a != 23'b0);
assign b_nan = (exp_b == 8'hff) && (frac_b != 23'b0);

assign sig_a = (exp_a == 8'h00) ? {1'b0, frac_a, 3'b000} :
                                  {1'b1, frac_a, 3'b000};

assign sig_b = (exp_b == 8'h00) ? {1'b0, frac_b, 3'b000} :
                                  {1'b1, frac_b, 3'b000};

endmodule