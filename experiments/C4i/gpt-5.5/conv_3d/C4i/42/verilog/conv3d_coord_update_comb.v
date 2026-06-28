`timescale 1ns/1ps

module conv3d_coord_update_comb #(
    parameter D = 8,
    parameter H = 64,
    parameter W = 64
) (
    input  [31:0] x_cur,
    input  [31:0] y_cur,
    input  [31:0] z_cur,
    input         valid_in,
    input         last_in,
    output reg [31:0] x_next,
    output reg [31:0] y_next,
    output reg [31:0] z_next,
    output        end_of_volume
);

    localparam [31:0] X_LAST = (W > 0) ? (W - 1) : 32'd0;
    localparam [31:0] Y_LAST = (H > 0) ? (H - 1) : 32'd0;
    localparam [31:0] Z_LAST = (D > 0) ? (D - 1) : 32'd0;

    wire at_last_x;
    wire at_last_y;
    wire at_last_z;
    wire at_last_voxel;
    wire eov;

    assign at_last_x     = (x_cur == X_LAST);
    assign at_last_y     = (y_cur == Y_LAST);
    assign at_last_z     = (z_cur == Z_LAST);
    assign at_last_voxel = at_last_x && at_last_y && at_last_z;

    assign eov = valid_in && (last_in || at_last_voxel);

    assign end_of_volume = eov;

    always @* begin
        x_next = x_cur;
        y_next = y_cur;
        z_next = z_cur;

        if (valid_in) begin
            if (eov) begin
                x_next = 32'd0;
                y_next = 32'd0;
                z_next = 32'd0;
            end else if (at_last_x) begin
                x_next = 32'd0;

                if (at_last_y) begin
                    y_next = 32'd0;
                    z_next = z_cur + 32'd1;
                end else begin
                    y_next = y_cur + 32'd1;
                end
            end else begin
                x_next = x_cur + 32'd1;
            end
        end
    end

endmodule