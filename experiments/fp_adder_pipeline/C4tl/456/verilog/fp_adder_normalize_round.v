`timescale 1ns/1ps

module fp_adder_normalize_round (
    input sign_in,
    input [7:0] exp_in,
    input [27:0] sig_in,
    input exact_zero,
    output reg [31:0] result
);

function [27:0] shift_right_sticky;
    input [27:0] value;
    input [7:0] shift;
    reg sticky;
    begin
        if (shift == 0) begin
            shift_right_sticky = value;
        end else if (shift >= 28) begin
            shift_right_sticky = {27'b0, |value};
        end else begin
            sticky = |(value & ((28'b1 << shift) - 1'b1));
            shift_right_sticky = (value >> shift);
            shift_right_sticky[0] = shift_right_sticky[0] | sticky;
        end
    end
endfunction

reg [27:0] sig_norm;
reg [27:0] sig_rounded;
reg [8:0] exp_norm;
reg [8:0] exp_rounded;
reg guard_bit;
reg round_bit;
reg sticky_bit;
reg round_inc;
integer i;

always @* begin
    result = 32'b0;

    sig_norm = sig_in;
    sig_rounded = 28'b0;
    exp_norm = {1'b0, exp_in};
    exp_rounded = 9'b0;

    guard_bit = 1'b0;
    round_bit = 1'b0;
    sticky_bit = 1'b0;
    round_inc = 1'b0;

    if (exact_zero || (sig_in == 28'b0)) begin
        result = {sign_in, 31'b0};
    end else if (exp_in == 8'hff) begin
        if (|sig_in[25:3])
            result = {1'b0, 8'hff, 1'b1, sig_in[21:0]};
        else
            result = {sign_in, 8'hff, 23'b0};
    end else begin
        if (sig_norm[27]) begin
            sig_norm = {1'b0, sig_norm[27:1]};
            sig_norm[0] = sig_norm[0] | sig_in[0];
            exp_norm = exp_norm + 9'd1;
        end else begin
            for (i = 0; i < 27; i = i + 1) begin
                if (!sig_norm[26] && (exp_norm > 0)) begin
                    sig_norm = sig_norm << 1;
                    exp_norm = exp_norm - 9'd1;
                end
            end
        end

        if (!sig_norm[26]) begin
            sig_norm = shift_right_sticky(sig_norm, 8'd1);
            exp_norm = 9'd0;
        end

        if (exp_norm == 0 && sig_norm[26]) begin
            sig_norm = shift_right_sticky(sig_norm, 8'd1);
        end

        guard_bit = sig_norm[2];
        round_bit = sig_norm[1];
        sticky_bit = sig_norm[0];

        round_inc = guard_bit && (round_bit || sticky_bit || sig_norm[3]);

        sig_rounded = sig_norm;
        if (round_inc)
            sig_rounded = sig_norm + 28'd8;

        exp_rounded = exp_norm;

        if (sig_rounded[27]) begin
            sig_rounded = {1'b0, sig_rounded[27:1]};
            exp_rounded = exp_norm + 9'd1;
        end

        if (exp_rounded >= 9'd255) begin
            result = {sign_in, 8'hff, 23'b0};
        end else if (exp_rounded == 0) begin
            result = {sign_in, 8'b0, sig_rounded[25:3]};
        end else begin
            result = {sign_in, exp_rounded[7:0], sig_rounded[25:3]};
        end
    end
end

endmodule