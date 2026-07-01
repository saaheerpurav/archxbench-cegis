`timescale 1ns/1ps

module fp_adder_align (
    input sign_a,
    input sign_b,
    input [7:0] exp_a,
    input [7:0] exp_b,
    input [23:0] sig_a,
    input [23:0] sig_b,
    output op_sub,
    output res_sign,
    output [7:0] exp_common,
    output [27:0] sig_large,
    output [27:0] sig_small
);

wire [7:0] eff_exp_a;
wire [7:0] eff_exp_b;
wire a_ge_b;
wire [7:0] exp_diff;

wire [27:0] ext_a;
wire [27:0] ext_b;
wire [27:0] large_pre;
wire [27:0] small_pre;
wire sign_large;

assign eff_exp_a = (exp_a == 8'h00) ? 8'h01 : exp_a;
assign eff_exp_b = (exp_b == 8'h00) ? 8'h01 : exp_b;

assign ext_a = {1'b0, sig_a, 3'b000};
assign ext_b = {1'b0, sig_b, 3'b000};

assign a_ge_b = (eff_exp_a > eff_exp_b) ||
                ((eff_exp_a == eff_exp_b) && (sig_a >= sig_b));

assign exp_common = a_ge_b ? eff_exp_a : eff_exp_b;
assign exp_diff   = a_ge_b ? (eff_exp_a - eff_exp_b) : (eff_exp_b - eff_exp_a);

assign large_pre  = a_ge_b ? ext_a : ext_b;
assign small_pre  = a_ge_b ? ext_b : ext_a;
assign sign_large = a_ge_b ? sign_a : sign_b;

assign sig_large = large_pre;
assign sig_small = shift_right_sticky(small_pre, exp_diff);

assign op_sub = sign_a ^ sign_b;
assign res_sign = sign_large;

function [27:0] shift_right_sticky;
    input [27:0] value;
    input [7:0] shift;
    reg sticky;
    begin
        if (shift == 8'd0) begin
            shift_right_sticky = value;
        end else if (shift >= 8'd28) begin
            shift_right_sticky = (value != 28'd0) ? 28'd1 : 28'd0;
        end else begin
            sticky = |(value & ((28'd1 << shift) - 28'd1));
            shift_right_sticky = (value >> shift) | sticky;
        end
    end
endfunction

endmodule