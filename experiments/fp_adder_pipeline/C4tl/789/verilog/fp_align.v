`timescale 1ns/1ps

module fp_align (
    input [7:0] a_exp,
    input [7:0] b_exp,
    input [23:0] a_mant,
    input [23:0] b_mant,
    output [27:0] a_aligned,
    output [27:0] b_aligned,
    output [7:0] common_exp
);

wire [7:0] exp_diff_ab;
wire [7:0] exp_diff_ba;

wire [27:0] a_ext;
wire [27:0] b_ext;

assign exp_diff_ab = a_exp - b_exp;
assign exp_diff_ba = b_exp - a_exp;

assign a_ext = {1'b0, a_mant, 3'b000};
assign b_ext = {1'b0, b_mant, 3'b000};

assign common_exp = (a_exp >= b_exp) ? a_exp : b_exp;

assign a_aligned = (a_exp >= b_exp) ? a_ext : shift_right_sticky(a_ext, exp_diff_ba);
assign b_aligned = (b_exp >= a_exp) ? b_ext : shift_right_sticky(b_ext, exp_diff_ab);

function [27:0] shift_right_sticky;
    input [27:0] value;
    input [7:0] shift;
    reg [27:0] shifted;
    reg sticky;
    begin
        if (shift == 8'd0) begin
            shift_right_sticky = value;
        end else if (shift >= 8'd28) begin
            shift_right_sticky = {27'd0, |value};
        end else begin
            shifted = value >> shift;
            sticky = |(value & ((28'd1 << shift) - 28'd1));
            shift_right_sticky = {shifted[27:1], shifted[0] | sticky};
        end
    end
endfunction

endmodule