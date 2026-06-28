`timescale 1ns/1ps

module ifft16_bit_reverse #(
    parameter WIDTH = 4
) (
    input  [WIDTH-1:0] idx,
    output [WIDTH-1:0] rev
);

    genvar i;

    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : GEN_REV
            assign rev[i] = idx[WIDTH-1-i];
        end
    endgenerate

endmodule