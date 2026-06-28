`timescale 1ns/1ps

module conv2d_valid_gen #(
    parameter KERNEL_SIZE = 3,
    parameter COORD_W = 32
) (
    input                   valid_in,
    input  [COORD_W-1:0]    row_cnt,
    input  [COORD_W-1:0]    col_cnt,
    output                  valid_out
);

    localparam RADIUS = (KERNEL_SIZE - 1) / 2;

    assign valid_out = valid_in &&
                       (row_cnt >= RADIUS[COORD_W-1:0]) &&
                       (col_cnt >= RADIUS[COORD_W-1:0]);

endmodule