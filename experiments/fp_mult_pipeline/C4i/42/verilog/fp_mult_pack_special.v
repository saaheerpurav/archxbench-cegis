`timescale 1ns/1ps

module fp_mult_pack_special (
    input        sign,
    input        a_zero,
    input        b_zero,
    input        a_inf,
    input        b_inf,
    input        a_nan,
    input        b_nan,
    input signed [10:0] exp_in,
    input  [22:0] frac_in,
    output reg [31:0] result
);

    localparam [7:0]  EXP_INF_NAN   = 8'hFF;
    localparam [31:0] CANONICAL_NAN = 32'h7FC00000;

    wire invalid_zero_inf;
    wire nan_case;
    wire inf_case;
    wire zero_case;

    assign invalid_zero_inf = (a_zero && b_inf) || (a_inf && b_zero);

    assign nan_case  = a_nan || b_nan || invalid_zero_inf;
    assign inf_case  = a_inf || b_inf;
    assign zero_case = a_zero || b_zero;

    always @* begin
        /*
         * IEEE-754 priority:
         *   NaN / invalid operation
         *   Infinity
         *   Zero
         *   Overflow
         *   Normal finite
         *   Underflow flushed to zero
         */
        if (nan_case) begin
            result = CANONICAL_NAN;
        end else if (inf_case) begin
            result = {sign, EXP_INF_NAN, 23'd0};
        end else if (zero_case) begin
            result = {sign, 31'd0};
        end else if (exp_in >= 11'sd255) begin
            result = {sign, EXP_INF_NAN, 23'd0};
        end else if (exp_in >= 11'sd1) begin
            result = {sign, exp_in[7:0], frac_in};
        end else begin
            result = {sign, 31'd0};
        end
    end

endmodule