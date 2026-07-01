`timescale 1ns/1ps

module fp_special_cases (
    input a_sign,
    input b_sign,
    input [7:0] a_exp,
    input [7:0] b_exp,
    input [22:0] a_frac,
    input [22:0] b_frac,
    input a_zero,
    input b_zero,
    input a_inf,
    input b_inf,
    input a_nan,
    input b_nan,
    output special_valid,
    output [31:0] special_result
);

reg        special_valid_r;
reg [31:0] special_result_r;

wire [31:0] a_packed;
wire [31:0] b_packed;
wire [31:0] a_quiet_nan;
wire [31:0] b_quiet_nan;

assign a_packed = {a_sign, a_exp, a_frac};
assign b_packed = {b_sign, b_exp, b_frac};

assign a_quiet_nan = {1'b0, 8'hff, 1'b1, a_frac[21:0]};
assign b_quiet_nan = {1'b0, 8'hff, 1'b1, b_frac[21:0]};

assign special_valid  = special_valid_r;
assign special_result = special_result_r;

always @(*) begin
    special_valid_r  = 1'b0;
    special_result_r = 32'd0;

    if (a_nan) begin
        special_valid_r  = 1'b1;
        special_result_r = a_quiet_nan;
    end else if (b_nan) begin
        special_valid_r  = 1'b1;
        special_result_r = b_quiet_nan;
    end else if (a_inf && b_inf) begin
        special_valid_r = 1'b1;

        if (a_sign != b_sign) begin
            special_result_r = 32'h7fc00000;
        end else begin
            special_result_r = {a_sign, 8'hff, 23'd0};
        end
    end else if (a_inf) begin
        special_valid_r  = 1'b1;
        special_result_r = {a_sign, 8'hff, 23'd0};
    end else if (b_inf) begin
        special_valid_r  = 1'b1;
        special_result_r = {b_sign, 8'hff, 23'd0};
    end else if (a_zero && b_zero) begin
        special_valid_r = 1'b1;

        if (a_sign == b_sign) begin
            special_result_r = {a_sign, 31'd0};
        end else begin
            special_result_r = 32'd0;
        end
    end else if (a_zero) begin
        special_valid_r  = 1'b1;
        special_result_r = b_packed;
    end else if (b_zero) begin
        special_valid_r  = 1'b1;
        special_result_r = a_packed;
    end
end

endmodule