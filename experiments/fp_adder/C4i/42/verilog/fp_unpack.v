`timescale 1ns/1ps

module fp_unpack #(
    parameter integer WIDTH      = 32,
    parameter integer EXP_WIDTH  = 8,
    parameter integer MANT_WIDTH = 23
)(
    input  [WIDTH-1:0]       in,
    output                   sign,
    output [EXP_WIDTH-1:0]   exp,
    output [EXP_WIDTH-1:0]   exp_eff,
    output [MANT_WIDTH-1:0]  frac,
    output [MANT_WIDTH:0]    sig,
    output                   is_zero,
    output                   is_inf,
    output                   is_nan,
    output                   is_denorm
);

    wire exp_all_ones;
    wire exp_is_zero;
    wire frac_is_zero;

    assign sign = in[WIDTH-1];
    assign exp  = in[WIDTH-2:MANT_WIDTH];
    assign frac = in[MANT_WIDTH-1:0];

    assign exp_all_ones = (exp  == {EXP_WIDTH{1'b1}});
    assign exp_is_zero  = (exp  == {EXP_WIDTH{1'b0}});
    assign frac_is_zero = (frac == {MANT_WIDTH{1'b0}});

    assign is_zero   = exp_is_zero  &&  frac_is_zero;
    assign is_denorm = exp_is_zero  && !frac_is_zero;
    assign is_inf    = exp_all_ones &&  frac_is_zero;
    assign is_nan    = exp_all_ones && !frac_is_zero;

    assign exp_eff = exp_is_zero ? {{(EXP_WIDTH-1){1'b0}}, 1'b1} : exp;

    assign sig = exp_is_zero ? {1'b0, frac} : {1'b1, frac};

endmodule