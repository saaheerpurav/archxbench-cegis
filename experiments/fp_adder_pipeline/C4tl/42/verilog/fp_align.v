`timescale 1ns/1ps

module fp_align (
    input sign_a,
    input sign_b,
    input [7:0] exp_a,
    input [7:0] exp_b,
    input [26:0] sig_a,
    input [26:0] sig_b,
    output sign_large,
    output sign_small,
    output [7:0] exp_large,
    output [26:0] sig_large,
    output [26:0] sig_small
);

wire a_is_larger;
wire [7:0] exp_diff;
wire [26:0] selected_small_sig;

assign a_is_larger = (exp_a > exp_b) ||
                     ((exp_a == exp_b) && (sig_a >= sig_b));

assign sign_large = a_is_larger ? sign_a : sign_b;
assign sign_small = a_is_larger ? sign_b : sign_a;

assign exp_large = a_is_larger ? exp_a : exp_b;
assign sig_large = a_is_larger ? sig_a : sig_b;

assign exp_diff = a_is_larger ? (exp_a - exp_b) : (exp_b - exp_a);
assign selected_small_sig = a_is_larger ? sig_b : sig_a;

function [26:0] shift_right_sticky;
    input [26:0] value;
    input [7:0] shift;
    reg sticky;
    begin
        if (shift == 8'd0) begin
            shift_right_sticky = value;
        end else if (shift >= 8'd27) begin
            shift_right_sticky = {26'b0, |value};
        end else begin
            sticky = |(value & ((27'b1 << shift) - 27'b1));
            shift_right_sticky = (value >> shift);
            shift_right_sticky[0] = shift_right_sticky[0] | sticky;
        end
    end
endfunction

assign sig_small = shift_right_sticky(selected_small_sig, exp_diff);

endmodule