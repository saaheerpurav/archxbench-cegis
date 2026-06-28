`timescale 1ns/1ps

module conv2d_window_pad #(
    parameter DATA_W      = 8,
    parameter KERNEL_SIZE = 3,
    parameter COORD_W     = 32
) (
    input  [COORD_W-1:0] row_cnt,
    input  [COORD_W-1:0] col_cnt,
    input  [KERNEL_SIZE*KERNEL_SIZE*DATA_W-1:0] raw_window,
    output [KERNEL_SIZE*KERNEL_SIZE*DATA_W-1:0] padded_window
);

    genvar r;
    genvar c;

    generate
        for (r = 0; r < KERNEL_SIZE; r = r + 1) begin : GEN_PAD_ROW
            for (c = 0; c < KERNEL_SIZE; c = c + 1) begin : GEN_PAD_COL
                assign padded_window[((r*KERNEL_SIZE + c)*DATA_W) +: DATA_W] =
                    ((row_cnt >= r) && (col_cnt >= c)) ?
                        raw_window[((r*KERNEL_SIZE + c)*DATA_W) +: DATA_W] :
                        {DATA_W{1'b0}};
            end
        end
    endgenerate

endmodule