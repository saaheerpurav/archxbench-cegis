`timescale 1ns/1ps

module fp_mult_pack (
    input sign,
    input [23:0] mantissa,
    input signed [10:0] exp_unbiased,
    input zero_a,
    input zero_b,
    input inf_a,
    input inf_b,
    input nan_a,
    input nan_b,
    output [31:0] result
);

wire invalid_inf_zero;
wire any_nan;
wire any_inf;
wire any_zero;
wire overflow;
wire underflow;
wire [7:0] exp_biased;

assign invalid_inf_zero = (inf_a && zero_b) || (inf_b && zero_a);
assign any_nan          = nan_a || nan_b || invalid_inf_zero;
assign any_inf          = inf_a || inf_b;
assign any_zero         = zero_a || zero_b;

assign overflow  = (exp_unbiased > 11'sd127);
assign underflow = (exp_unbiased < -11'sd126);

assign exp_biased = exp_unbiased[7:0] + 8'd127;

assign result =
    any_nan    ? 32'h7FC00000 :
    any_inf    ? {sign, 8'hFF, 23'b0} :
    any_zero   ? {sign, 31'b0} :
    overflow   ? {sign, 8'hFF, 23'b0} :
    underflow  ? {sign, 31'b0} :
                 {sign, exp_biased, mantissa[22:0]};

endmodule