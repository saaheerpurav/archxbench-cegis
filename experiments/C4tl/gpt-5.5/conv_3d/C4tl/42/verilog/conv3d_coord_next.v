`timescale 1ns/1ps

module conv3d_coord_next #(
    parameter D = 8,
    parameter H = 64,
    parameter W = 64
) (
    input  [31:0] depth_idx,
    input  [31:0] row_idx,
    input  [31:0] col_idx,
    input         advance,
    input         last_in,
    output reg [31:0] next_depth_idx,
    output reg [31:0] next_row_idx,
    output reg [31:0] next_col_idx,
    output            volume_end
);

    wire at_last_col;
    wire at_last_row;
    wire at_last_depth;
    wire at_last_voxel;

    assign at_last_col   = (col_idx   == (W - 1));
    assign at_last_row   = (row_idx   == (H - 1));
    assign at_last_depth = (depth_idx == (D - 1));
    assign at_last_voxel = at_last_col & at_last_row & at_last_depth;

    assign volume_end = advance & (last_in | at_last_voxel);

    always @* begin
        next_depth_idx = depth_idx;
        next_row_idx   = row_idx;
        next_col_idx   = col_idx;

        if (advance) begin
            if (last_in | at_last_voxel) begin
                next_depth_idx = 32'd0;
                next_row_idx   = 32'd0;
                next_col_idx   = 32'd0;
            end else if (at_last_col) begin
                next_col_idx = 32'd0;

                if (at_last_row) begin
                    next_row_idx   = 32'd0;
                    next_depth_idx = depth_idx + 32'd1;
                end else begin
                    next_row_idx = row_idx + 32'd1;
                end
            end else begin
                next_col_idx = col_idx + 32'd1;
            end
        end
    end

endmodule