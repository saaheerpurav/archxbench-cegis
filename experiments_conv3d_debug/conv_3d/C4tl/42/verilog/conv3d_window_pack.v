`timescale 1ns/1ps

module conv3d_window_pack #(
    parameter K1 = 3,
    parameter K2 = 3,
    parameter K3 = 3,
    parameter DATA_W = 8
) (
    input  [K1*K2*K3*DATA_W-1:0] window_in,
    output [K1*K2*K3*DATA_W-1:0] window_out
);

    assign window_out = window_in;

endmodule