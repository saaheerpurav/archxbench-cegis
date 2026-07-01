`timescale 1ns/1ps

module ifft16_bit_reverse_addr (
    input  [3:0] addr,
    output [3:0] rev_addr
);
    assign rev_addr = {addr[0], addr[1], addr[2], addr[3]};
endmodule