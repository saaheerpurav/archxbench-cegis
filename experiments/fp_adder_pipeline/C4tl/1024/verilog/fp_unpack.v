`timescale 1ns/1ps

module fp_unpack (
    input  [31:0] operand,
    output        sign,
    output [7:0]  exp,
    output [22:0] frac,
    output [23:0] sig,
    output        is_zero,
    output        is_inf,
    output        is_nan,
    output        is_denorm
);

wire exp_all_zero;
wire exp_all_ones;
wire frac_zero;

assign sign = operand[31];
assign exp  = operand[30:23];
assign frac = operand[22:0];

assign exp_all_zero = (exp == 8'h00);
assign exp_all_ones = (exp == 8'hFF);
assign frac_zero    = (frac == 23'b0);

assign is_zero   = exp_all_zero && frac_zero;
assign is_denorm = exp_all_zero && !frac_zero;
assign is_inf    = exp_all_ones && frac_zero;
assign is_nan    = exp_all_ones && !frac_zero;

assign sig = exp_all_zero ? {1'b0, frac} : {1'b1, frac};

endmodule