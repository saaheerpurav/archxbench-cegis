`timescale 1ns/1ps

module fp_special_cases (
    input sign_a,
    input sign_b,
    input a_zero,
    input b_zero,
    input a_inf,
    input b_inf,
    input a_nan,
    input b_nan,
    output special_valid,
    output [31:0] special_result
);

wire invalid_inf_cancel;
wire both_zero;

assign invalid_inf_cancel = a_inf && b_inf && (sign_a != sign_b);
assign both_zero = a_zero && b_zero;

assign special_valid =
    a_nan || b_nan ||
    a_inf || b_inf ||
    both_zero;

assign special_result =
    (a_nan || b_nan || invalid_inf_cancel) ? 32'h7FC00000 :
    (a_inf)                              ? {sign_a, 8'hFF, 23'b0} :
    (b_inf)                              ? {sign_b, 8'hFF, 23'b0} :
    (both_zero)                          ? {(sign_a & sign_b), 31'b0} :
                                           32'b0;

endmodule