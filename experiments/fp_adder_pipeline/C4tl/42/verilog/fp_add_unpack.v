`timescale 1ns/1ps

module fp_add_unpack (
    input  [31:0] a,
    input  [31:0] b,
    input         add_sub,

    output reg        a_sign,
    output reg        b_sign,
    output reg [8:0]  a_exp,
    output reg [8:0]  b_exp,
    output reg [23:0] a_sig,
    output reg [23:0] b_sig,

    output reg        special,
    output reg [31:0] special_result
);

    wire        a_sign_raw = a[31];
    wire        b_sign_raw = b[31];
    wire        b_sign_eff = b_sign_raw ^ add_sub;

    wire [7:0]  a_exp_f = a[30:23];
    wire [7:0]  b_exp_f = b[30:23];

    wire [22:0] a_frac  = a[22:0];
    wire [22:0] b_frac  = b[22:0];

    wire        a_exp_zero = (a_exp_f == 8'h00);
    wire        b_exp_zero = (b_exp_f == 8'h00);

    wire        a_exp_all_ones = (a_exp_f == 8'hFF);
    wire        b_exp_all_ones = (b_exp_f == 8'hFF);

    wire        a_frac_zero = (a_frac == 23'd0);
    wire        b_frac_zero = (b_frac == 23'd0);

    wire        a_nan = a_exp_all_ones && !a_frac_zero;
    wire        b_nan = b_exp_all_ones && !b_frac_zero;

    wire        a_inf = a_exp_all_ones && a_frac_zero;
    wire        b_inf = b_exp_all_ones && b_frac_zero;

    always @* begin
        a_sign = a_sign_raw;
        b_sign = b_sign_eff;

        /*
         * IEEE-754 unpacking for addition alignment:
         *
         * Normal:
         *   exponent    = stored biased exponent
         *   significand = 1.fraction
         *
         * Subnormal/zero:
         *   exponent    = 1
         *   significand = 0.fraction
         *
         * Using effective exponent 1 for subnormals/zeros makes their scale
         * match the minimum normal exponent during later alignment.
         */
        a_exp = a_exp_zero ? 9'd1 : {1'b0, a_exp_f};
        b_exp = b_exp_zero ? 9'd1 : {1'b0, b_exp_f};

        a_sig = a_exp_zero ? {1'b0, a_frac} : {1'b1, a_frac};
        b_sig = b_exp_zero ? {1'b0, b_frac} : {1'b1, b_frac};

        special        = 1'b0;
        special_result = 32'd0;

        /*
         * Early special-case resolution.
         *
         * NaNs are canonicalized to a quiet NaN.
         * Opposite-signed infinities after applying add/sub are invalid.
         * Otherwise infinities propagate with their effective arithmetic sign.
         */
        if (a_nan || b_nan) begin
            special        = 1'b1;
            special_result = 32'h7FC00000;
        end else if (a_inf && b_inf && (a_sign_raw != b_sign_eff)) begin
            special        = 1'b1;
            special_result = 32'h7FC00000;
        end else if (a_inf) begin
            special        = 1'b1;
            special_result = {a_sign_raw, 8'hFF, 23'd0};
        end else if (b_inf) begin
            special        = 1'b1;
            special_result = {b_sign_eff, 8'hFF, 23'd0};
        end
    end

endmodule