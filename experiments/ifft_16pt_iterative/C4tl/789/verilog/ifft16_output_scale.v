module ifft16_output_scale #(
    parameter IN_W = 16,
    parameter SHIFT = 4
) (
    input  signed [IN_W-1:0] din,
    output signed [IN_W-1:0] dout
);
    assign dout = din >>> SHIFT;
endmodule