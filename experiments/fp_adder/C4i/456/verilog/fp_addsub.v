`timescale 1ns/1ps

module fp_addsub #(
    parameter integer EXP_WIDTH  = 8,
    parameter integer MANT_WIDTH = 23
)(
    input  [EXP_WIDTH:0]     aligned_exp,
    input                    large_sign,
    input                    small_sign,
    input  [MANT_WIDTH+3:0]  large_sig,
    input  [MANT_WIDTH+3:0]  small_sig,
    output reg               raw_sign,
    output reg               raw_zero,
    output reg [EXP_WIDTH:0] raw_exp,
    output reg [MANT_WIDTH+4:0] raw_sig
);

    always @* begin
        raw_exp = aligned_exp;

        if (large_sign == small_sign) begin
            raw_sig = {1'b0, large_sig} + {1'b0, small_sig};
        end else begin
            raw_sig = {1'b0, large_sig} - {1'b0, small_sig};
        end

        raw_zero = (raw_sig == {MANT_WIDTH+5{1'b0}});
        raw_sign = raw_zero ? 1'b0 : large_sign;
    end

endmodule