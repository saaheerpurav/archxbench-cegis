`timescale 1ns/1ps

module fft16_bit_reverse #(
    parameter N = 16
) (
    output [3:0] bitrev [0:N-1]
);

    assign bitrev[0]  = 4'd0;
    assign bitrev[1]  = 4'd8;
    assign bitrev[2]  = 4'd4;
    assign bitrev[3]  = 4'd12;
    assign bitrev[4]  = 4'd2;
    assign bitrev[5]  = 4'd10;
    assign bitrev[6]  = 4'd6;
    assign bitrev[7]  = 4'd14;
    assign bitrev[8]  = 4'd1;
    assign bitrev[9]  = 4'd9;
    assign bitrev[10] = 4'd5;
    assign bitrev[11] = 4'd13;
    assign bitrev[12] = 4'd3;
    assign bitrev[13] = 4'd11;
    assign bitrev[14] = 4'd7;
    assign bitrev[15] = 4'd15;

endmodule