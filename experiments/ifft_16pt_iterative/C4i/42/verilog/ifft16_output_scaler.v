`timescale 1ns/1ps

module ifft16_output_scaler #(
    parameter DATA_W = 16,
    parameter SHIFT  = 4
) (
    input  signed [DATA_W-1:0] in_val,
    input                      scale_en,
    output signed [DATA_W-1:0] out_val
);

    assign out_val = scale_en ? (in_val >>> SHIFT) : in_val;

endmodule