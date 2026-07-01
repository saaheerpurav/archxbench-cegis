`timescale 1ns/1ps

module fp_add_core (
    input sign_a,
    input sign_b,
    input [7:0] exp_a,
    input [7:0] exp_b,
    input [22:0] frac_a,
    input [22:0] frac_b,
    input is_zero_a,
    input is_zero_b,
    output reg [31:0] result
);

reg [7:0]  eff_exp_a, eff_exp_b;
reg [23:0] sig_a, sig_b;
reg [26:0] ext_a, ext_b;
reg [26:0] aligned_a, aligned_b;
reg [7:0]  exp_large;
reg [7:0]  exp_diff;

reg [27:0] add_sum;
reg [26:0] mag_large, mag_small;
reg [26:0] mag_diff;
reg        sign_large;
reg        result_sign;

reg [26:0] norm_sig;
reg [7:0]  norm_exp;
reg [24:0] rounded_sig;
reg [23:0] round_base;
reg        guard_bit, round_bit, sticky_bit;
reg        round_inc;
reg [7:0]  out_exp;
reg [22:0] out_frac;
integer i;

function [26:0] shift_right_sticky;
    input [26:0] value;
    input [7:0]  shift;
    reg sticky;
    begin
        if (shift == 0) begin
            shift_right_sticky = value;
        end else if (shift >= 27) begin
            shift_right_sticky = {26'b0, |value};
        end else begin
            sticky = |(value & ((27'b1 << shift) - 27'b1));
            shift_right_sticky = (value >> shift);
            shift_right_sticky[0] = shift_right_sticky[0] | sticky;
        end
    end
endfunction

always @* begin
    result = 32'h00000000;

    eff_exp_a = (exp_a == 8'd0) ? 8'd1 : exp_a;
    eff_exp_b = (exp_b == 8'd0) ? 8'd1 : exp_b;

    sig_a = (exp_a == 8'd0) ? {1'b0, frac_a} : {1'b1, frac_a};
    sig_b = (exp_b == 8'd0) ? {1'b0, frac_b} : {1'b1, frac_b};

    ext_a = {sig_a, 3'b000};
    ext_b = {sig_b, 3'b000};

    if (is_zero_a && is_zero_b) begin
        result = 32'h00000000;
    end else if (is_zero_a) begin
        result = {sign_b, exp_b, frac_b};
    end else if (is_zero_b) begin
        result = {sign_a, exp_a, frac_a};
    end else begin
        if (eff_exp_a >= eff_exp_b) begin
            exp_large = eff_exp_a;
            exp_diff = eff_exp_a - eff_exp_b;
            aligned_a = ext_a;
            aligned_b = shift_right_sticky(ext_b, exp_diff);
        end else begin
            exp_large = eff_exp_b;
            exp_diff = eff_exp_b - eff_exp_a;
            aligned_a = shift_right_sticky(ext_a, exp_diff);
            aligned_b = ext_b;
        end

        if (sign_a == sign_b) begin
            result_sign = sign_a;
            add_sum = {1'b0, aligned_a} + {1'b0, aligned_b};
            norm_exp = exp_large;

            if (add_sum[27]) begin
                norm_sig = add_sum[27:1];
                norm_sig[0] = norm_sig[0] | add_sum[0];
                norm_exp = norm_exp + 8'd1;
            end else begin
                norm_sig = add_sum[26:0];
            end
        end else begin
            if (aligned_a > aligned_b) begin
                mag_large = aligned_a;
                mag_small = aligned_b;
                sign_large = sign_a;
            end else begin
                mag_large = aligned_b;
                mag_small = aligned_a;
                sign_large = sign_b;
            end

            mag_diff = mag_large - mag_small;
            result_sign = sign_large;
            norm_exp = exp_large;
            norm_sig = mag_diff;

            if (mag_diff == 27'd0) begin
                result_sign = 1'b0;
                norm_exp = 8'd0;
                norm_sig = 27'd0;
            end else begin
                for (i = 0; i < 26; i = i + 1) begin
                    if (!norm_sig[26] && norm_exp > 8'd1) begin
                        norm_sig = norm_sig << 1;
                        norm_exp = norm_exp - 8'd1;
                    end
                end
            end
        end

        if (norm_sig == 27'd0) begin
            result = 32'h00000000;
        end else if (norm_exp >= 8'd255) begin
            result = {result_sign, 8'hff, 23'd0};
        end else begin
            guard_bit = norm_sig[2];
            round_bit = norm_sig[1];
            sticky_bit = norm_sig[0];
            round_base = norm_sig[26:3];
            round_inc = guard_bit & (round_bit | sticky_bit | round_base[0]);

            rounded_sig = {1'b0, round_base} + round_inc;

            if (rounded_sig[24]) begin
                rounded_sig = rounded_sig >> 1;
                norm_exp = norm_exp + 8'd1;
            end

            if (norm_exp >= 8'd255) begin
                result = {result_sign, 8'hff, 23'd0};
            end else begin
                if (norm_exp == 8'd1 && rounded_sig[23] == 1'b0) begin
                    out_exp = 8'd0;
                    out_frac = rounded_sig[22:0];
                end else begin
                    out_exp = norm_exp;
                    out_frac = rounded_sig[22:0];
                end

                result = {result_sign, out_exp, out_frac};
            end
        end
    end
end

endmodule