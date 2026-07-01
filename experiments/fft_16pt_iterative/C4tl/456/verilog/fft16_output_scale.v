`timescale 1ns/1ps

module fft16_output_scale #(
    parameter IN_W = 16,
    parameter GAIN_W = 4
) (
    input signed [IN_W-1:0] din,
    input mode,
    output signed [IN_W-1:0] dout
);
    assign dout = mode ? (din >>> GAIN_W) : din;
endmodule