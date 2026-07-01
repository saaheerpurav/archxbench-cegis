`timescale 1ns/1ps

module fp_mult_pack (
    input sign,
    input [23:0] mantissa,
    input signed [10:0] exp_in,
    input is_nan,
    input is_inf,
    input is_zero,
    output [31:0] result
);
    wire overflow;
    wire underflow;
    wire [7:0] exp_field;
    wire [22:0] frac_field;

    assign overflow = (exp_in >= 11'sd255);
    assign underflow = (exp_in < 11'sd1);
    assign exp_field = exp_in[7:0];
    assign frac_field = mantissa[22:0];

    assign result =
        is_nan    ? 32'h7FC00000 :
        is_inf    ? {sign, 8'hFF, 23'b0} :
        is_zero   ? {sign, 31'b0} :
        overflow  ? {sign, 8'hFF, 23'b0} :
        underflow ? {sign, 31'b0} :
                    {sign, exp_field, frac_field};

endmodule