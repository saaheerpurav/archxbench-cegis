`timescale 1ns/1ps

module fft16_ifft_output_scale #(
    parameter DATA_W = 16,
    parameter SHIFT = 4
) (
    input  signed [DATA_W-1:0] in_real,
    input  signed [DATA_W-1:0] in_imag,
    output signed [DATA_W-1:0] out_real,
    output signed [DATA_W-1:0] out_imag
);
    assign out_real = in_real >>> SHIFT;
    assign out_imag = in_imag >>> SHIFT;
endmodule