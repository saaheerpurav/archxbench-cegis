`timescale 1ns/1ps

module fp_add_core (
    input         special_in,
    input  [31:0] special_result_in,

    input         a_sign,
    input         b_sign,
    input  [8:0]  exp_in,
    input  [26:0] a_aligned,
    input  [26:0] b_aligned,

    output reg        special_out,
    output reg [31:0] special_result_out,
    output reg        result_sign,
    output reg [8:0]  exp_out,
    output reg [27:0] raw_sum,
    output reg        zero
);

    always @* begin
        /*
         * Metadata pass-through.
         * Special results such as NaN/INF are handled by later stages using
         * special_out/special_result_out.  The arithmetic datapath is still
         * computed deterministically so that all outputs are well-defined.
         */
        special_out        = special_in;
        special_result_out = special_result_in;
        exp_out            = exp_in;

        result_sign = 1'b0;
        raw_sum     = 28'd0;
        zero        = 1'b0;

        /*
         * If effective signs match, perform magnitude addition.
         * Extend both 27-bit aligned significands to 28 bits to preserve
         * carry-out for the normalize stage.
         */
        if (a_sign == b_sign) begin
            raw_sum     = {1'b0, a_aligned} + {1'b0, b_aligned};
            result_sign = a_sign;
        end

        /*
         * If effective signs differ, perform magnitude subtraction.
         * Keep raw_sum non-negative by subtracting the smaller aligned
         * magnitude from the larger one.  The result sign follows the
         * operand with the larger magnitude.
         */
        else begin
            if (a_aligned > b_aligned) begin
                raw_sum     = {1'b0, a_aligned} - {1'b0, b_aligned};
                result_sign = a_sign;
            end
            else if (b_aligned > a_aligned) begin
                raw_sum     = {1'b0, b_aligned} - {1'b0, a_aligned};
                result_sign = b_sign;
            end
            else begin
                raw_sum     = 28'd0;
                result_sign = 1'b0;
            end
        end

        /*
         * Exact zero detection.
         * The required zero result is +0.0, so force sign low whenever the
         * raw arithmetic result is exactly zero.
         */
        if (raw_sum == 28'd0) begin
            zero        = 1'b1;
            result_sign = 1'b0;
        end
    end

endmodule