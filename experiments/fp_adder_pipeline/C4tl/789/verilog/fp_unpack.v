`timescale 1ns/1ps

module fp_unpack (
    input [31:0] in,
    output sign,
    output [7:0] exp,
    output [23:0] mant,
    output is_zero,
    output is_inf,
    output is_nan
);

wire [7:0]  exp_raw;
wire [22:0] frac;
wire        exp_all_zero;
wire        exp_all_one;
wire        frac_zero;

assign sign = in[31];
assign exp_raw = in[30:23];
assign frac = in[22:0];

assign exp_all_zero = (exp_raw == 8'h00);
assign exp_all_one  = (exp_raw == 8'hFF);
assign frac_zero    = (frac == 23'd0);

assign exp = exp_raw;

assign is_zero = exp_all_zero && frac_zero;
assign is_inf  = exp_all_one && frac_zero;
assign is_nan  = exp_all_one && !frac_zero;

assign mant = exp_all_zero ? {1'b0, frac} : {1'b1, frac};

endmodule