`timescale 1ns/1ps

module fp_special_cases (
    input sign_a,
    input sign_b,
    input is_zero_a,
    input is_zero_b,
    input is_inf_a,
    input is_inf_b,
    input is_nan_a,
    input is_nan_b,
    output special_valid,
    output [31:0] special_result
);

reg special_valid_r;
reg [31:0] special_result_r;

assign special_valid = special_valid_r;
assign special_result = special_result_r;

always @(*) begin
    special_valid_r = 1'b0;
    special_result_r = 32'h00000000;

    if (is_nan_a || is_nan_b) begin
        special_valid_r = 1'b1;
        special_result_r = 32'h7FC00000;
    end else if (is_inf_a && is_inf_b) begin
        special_valid_r = 1'b1;

        if (sign_a != sign_b)
            special_result_r = 32'h7FC00000;
        else
            special_result_r = {sign_a, 8'hFF, 23'h000000};
    end else if (is_inf_a) begin
        special_valid_r = 1'b1;
        special_result_r = {sign_a, 8'hFF, 23'h000000};
    end else if (is_inf_b) begin
        special_valid_r = 1'b1;
        special_result_r = {sign_b, 8'hFF, 23'h000000};
    end else if (is_zero_a && is_zero_b) begin
        special_valid_r = 1'b1;

        if (sign_a == sign_b)
            special_result_r = {sign_a, 31'h00000000};
        else
            special_result_r = 32'h00000000;
    end
end

endmodule