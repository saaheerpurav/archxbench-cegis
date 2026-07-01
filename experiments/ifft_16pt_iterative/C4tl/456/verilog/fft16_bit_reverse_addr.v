`timescale 1ns/1ps

module fft16_bit_reverse_addr (
    input  [3:0] addr_in,
    output [3:0] addr_out
);
    assign addr_out = {addr_in[0], addr_in[1], addr_in[2], addr_in[3]};
endmodule