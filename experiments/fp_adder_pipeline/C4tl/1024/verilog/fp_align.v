`timescale 1ns/1ps

module fp_align (
    input        a_sign,
    input [7:0]  a_exp,
    input [23:0] a_sig,
    input        b_sign,
    input [7:0]  b_exp,
    input [23:0] b_sig,
    output        sign_large,
    output        sign_small,
    output [7:0]  exp_large,
    output [26:0] sig_large,
    output [26:0] sig_small
);

wire a_is_larger;
wire [7:0] exp_diff;
wire [23:0] large_sig_raw;
wire [23:0] small_sig_raw;

assign a_is_larger = (a_exp > b_exp) ||
                     ((a_exp == b_exp) && (a_sig >= b_sig));

assign sign_large    = a_is_larger ? a_sign : b_sign;
assign sign_small    = a_is_larger ? b_sign : a_sign;
assign exp_large     = a_is_larger ? a_exp  : b_exp;
assign exp_diff      = a_is_larger ? (a_exp - b_exp) : (b_exp - a_exp);
assign large_sig_raw = a_is_larger ? a_sig : b_sig;
assign small_sig_raw = a_is_larger ? b_sig : a_sig;

assign sig_large = {large_sig_raw, 3'b000};

function [26:0] shift_right_sticky;
    input [23:0] sig;
    input [7:0]  shamt;

    reg [26:0] ext_sig;
    reg [26:0] shifted;
    reg        sticky;
begin
    ext_sig = {sig, 3'b000};

    if (shamt == 8'd0) begin
        shift_right_sticky = ext_sig;
    end else if (shamt >= 8'd27) begin
        shift_right_sticky = {26'b0, |ext_sig};
    end else begin
        shifted = ext_sig >> shamt;
        sticky  = |(ext_sig & ((27'b1 << shamt) - 27'b1));
        shift_right_sticky = {shifted[26:1], shifted[0] | sticky};
    end
end
endfunction

assign sig_small = shift_right_sticky(small_sig_raw, exp_diff);

endmodule