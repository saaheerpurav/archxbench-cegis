`timescale 1ns/1ps

module fp_add_align (
    input         special_in,
    input  [31:0] special_result_in,

    input         a_sign_in,
    input         b_sign_in,

    input  [8:0]  a_exp_in,
    input  [8:0]  b_exp_in,

    input  [23:0] a_sig_in,
    input  [23:0] b_sig_in,

    output reg        special_out,
    output reg [31:0] special_result_out,

    output reg        a_sign_out,
    output reg        b_sign_out,

    output reg [8:0]  exp_out,

    output reg [26:0] a_aligned,
    output reg [26:0] b_aligned
);

    /*
     * Right shift with jammed sticky bit.
     *
     * value[26:3] : significand bits
     * value[2]    : guard bit
     * value[1]    : round bit
     * value[0]    : sticky bit
     *
     * Any nonzero bit shifted out of the LSB is ORed into bit 0.
     */
    function [26:0] rshift_jam27;
        input [26:0] value;
        input [8:0]  shamt;

        reg [26:0] shifted;
        reg [26:0] lost_mask;
        reg        sticky;

        begin
            if (shamt == 9'd0) begin
                rshift_jam27 = value;
            end else if (shamt >= 9'd27) begin
                /*
                 * Entire operand is shifted below the representable
                 * aligned significand field. Preserve only whether it
                 * was nonzero.
                 */
                if (value != 27'd0)
                    rshift_jam27 = 27'd1;
                else
                    rshift_jam27 = 27'd0;
            end else begin
                shifted   = value >> shamt;
                lost_mask = (27'd1 << shamt) - 27'd1;
                sticky    = |(value & lost_mask);

                shifted[0] = shifted[0] | sticky;
                rshift_jam27 = shifted;
            end
        end
    endfunction

    reg [26:0] a_ext;
    reg [26:0] b_ext;
    reg [8:0]  exp_diff;

    always @* begin
        /*
         * Pass-through control and special-case data.
         */
        special_out        = special_in;
        special_result_out = special_result_in;

        a_sign_out = a_sign_in;
        b_sign_out = b_sign_in;

        /*
         * Append guard, round, and sticky positions.
         * Initially they are exact zero before alignment shifting.
         */
        a_ext = {a_sig_in, 3'b000};
        b_ext = {b_sig_in, 3'b000};

        if (a_exp_in >= b_exp_in) begin
            exp_out  = a_exp_in;
            exp_diff = a_exp_in - b_exp_in;

            a_aligned = a_ext;
            b_aligned = rshift_jam27(b_ext, exp_diff);
        end else begin
            exp_out  = b_exp_in;
            exp_diff = b_exp_in - a_exp_in;

            a_aligned = rshift_jam27(a_ext, exp_diff);
            b_aligned = b_ext;
        end
    end

endmodule