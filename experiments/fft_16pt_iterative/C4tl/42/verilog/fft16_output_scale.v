`timescale 1ns/1ps

module fft16_output_scale #(
    parameter DATA_W = 12,
    parameter GAIN_W = 4
) (
    input signed [DATA_W+GAIN_W-1:0] in_real,
    input signed [DATA_W+GAIN_W-1:0] in_imag,
    input ifft_mode,
    output signed [DATA_W+GAIN_W-1:0] out_real,
    output signed [DATA_W+GAIN_W-1:0] out_imag
);
    localparam OUT_W = DATA_W + GAIN_W;

    assign out_real = ifft_mode ? (in_real >>> GAIN_W) : in_real;
    assign out_imag = ifft_mode ? (in_imag >>> GAIN_W) : in_imag;

endmodule