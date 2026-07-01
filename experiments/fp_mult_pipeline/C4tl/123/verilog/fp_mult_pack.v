`timescale 1ns/1ps

module fp_mult_pack (
    input sign,
    input signed [10:0] exp_unbiased,
    input [23:0] sig,
    input a_zero,
    input b_zero,
    input a_inf,
    input b_inf,
    input a_nan,
    input b_nan,
    output reg [31:0] result
);

localparam [7:0] EXP_INF_NAN = 8'hFF;
localparam [7:0] EXP_ZERO    = 8'h00;
localparam [22:0] FRAC_ZERO  = 23'd0;
localparam [22:0] QNAN_FRAC  = 23'h400000;

integer shift_amt;
reg [23:0] subnormal_sig;

always @(*) begin
    result = 32'd0;
    shift_amt = 0;
    subnormal_sig = 24'd0;

    if (a_nan || b_nan || ((a_inf || b_inf) && (a_zero || b_zero))) begin
        result = {1'b0, EXP_INF_NAN, QNAN_FRAC};
    end else if (a_inf || b_inf) begin
        result = {sign, EXP_INF_NAN, FRAC_ZERO};
    end else if (a_zero || b_zero || sig == 24'd0) begin
        result = {sign, EXP_ZERO, FRAC_ZERO};
    end else if (exp_unbiased >= 11'sd128) begin
        result = {sign, EXP_INF_NAN, FRAC_ZERO};
    end else if (exp_unbiased >= -11'sd126) begin
        result = {sign, exp_unbiased[7:0] + 8'd127, sig[22:0]};
    end else begin
        shift_amt = (-126) - exp_unbiased;

        if (shift_amt >= 24) begin
            result = {sign, EXP_ZERO, FRAC_ZERO};
        end else begin
            subnormal_sig = sig >> shift_amt;
            result = {sign, EXP_ZERO, subnormal_sig[22:0]};
        end
    end
end

endmodule