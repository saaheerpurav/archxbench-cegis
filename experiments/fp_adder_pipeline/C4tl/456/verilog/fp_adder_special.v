`timescale 1ns/1ps

module fp_adder_special (
    input [31:0] a,
    input [31:0] b,
    input add_sub,
    input sign_a,
    input sign_b_raw,
    input zero_a,
    input zero_b,
    input inf_a,
    input inf_b,
    input nan_a,
    input nan_b,
    output sign_b_eff,
    output special_valid,
    output [31:0] special_result
);

wire [22:0] quiet_frac_a;
wire [22:0] quiet_frac_b;
wire [31:0] quiet_nan_a;
wire [31:0] quiet_nan_b;
wire [31:0] canonical_nan;

assign sign_b_eff = sign_b_raw ^ add_sub;

assign quiet_frac_a = a[22:0] | 23'h400000;
assign quiet_frac_b = b[22:0] | 23'h400000;

assign quiet_nan_a = {a[31], 8'hff, quiet_frac_a};
assign quiet_nan_b = {b[31], 8'hff, quiet_frac_b};
assign canonical_nan = 32'h7fc00000;

assign special_valid =
       nan_a | nan_b |
       inf_a | inf_b |
       zero_a | zero_b;

assign special_result =
       nan_a ? quiet_nan_a :
       nan_b ? quiet_nan_b :

       // Opposite-signed infinities after applying add/sub are invalid.
       (inf_a && inf_b && (sign_a != sign_b_eff)) ? canonical_nan :

       // Same-signed infinities preserve that infinite sign.
       (inf_a && inf_b) ? {sign_a, 8'hff, 23'b0} :

       inf_a ? {sign_a, 8'hff, 23'b0} :
       inf_b ? {sign_b_eff, 8'hff, 23'b0} :

       // Both operands are zero. Equal effective signs preserve the sign;
       // opposite effective signs produce +0 for round-to-nearest behavior.
       (zero_a && zero_b && (sign_a == sign_b_eff)) ? {sign_a, 31'b0} :
       (zero_a && zero_b) ? 32'b0 :

       // One zero operand: return the nonzero operand with its effective sign.
       zero_a ? {sign_b_eff, b[30:0]} :
       zero_b ? {sign_a, a[30:0]} :

       32'b0;

endmodule