`timescale 1ns/1ps

module fft16_bit_reverse (
    input [3:0] index_in,
    output [3:0] index_out
);

    assign index_out = {index_in[0], index_in[1], index_in[2], index_in[3]};

endmodule