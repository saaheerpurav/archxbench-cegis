`timescale 1ns/1ps

module fp_adder_unpack (
    input [31:0] in,
    output sign,
    output [7:0] exp,
    output [22:0] frac,
    output [23:0] sig,
    output is_zero,
    output is_inf,
    output is_nan
);

assign sign = in[31];
assign exp  = in[30:23];
assign frac = in[22:0];

assign is_zero = (exp == 8'h00) && (frac == 23'h000000);
assign is_inf  = (exp == 8'hFF) && (frac == 23'h000000);
assign is_nan  = (exp == 8'hFF) && (frac != 23'h000000);

// IEEE-754 significand:
// - Normal numbers have an implicit leading 1.
// - Subnormal numbers and zero have an implicit leading 0.
// - INF/NaN payload bits are still exposed through frac; sig follows field form.
assign sig = (exp == 8'h00) ? {1'b0, frac} : {1'b1, frac};

endmodule