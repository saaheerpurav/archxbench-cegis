`timescale 1ns/1ps

module fir_output_scale #(
    parameter IN_W  = 64,
    parameter OUT_W = 24,
    parameter SHIFT = 15
) (
    input  signed [IN_W-1:0]  acc_in,
    output signed [OUT_W-1:0] data_out
);

    wire signed [IN_W-1:0] shifted;

    assign shifted  = acc_in >>> SHIFT;
    assign data_out = shifted[OUT_W-1:0];

endmodule