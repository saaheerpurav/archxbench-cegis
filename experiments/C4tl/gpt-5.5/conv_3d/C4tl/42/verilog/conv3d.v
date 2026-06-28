`timescale 1ns/1ps

module conv3d #(
    parameter K1 = 3,  // Kernel depth
    parameter K2 = 3,  // Kernel height
    parameter K3 = 3,  // Kernel width
    parameter D = 8,   // Input volume depth
    parameter H = 64,  // Input height
    parameter W = 64,  // Input width
    parameter DATA_W = 8,
    parameter LOG_KW = 4
) (
    input clk,
    input rst,
    input [DATA_W-1:0] voxel_in,
    input valid_in,
    input [K1*K2*K3*DATA_W-1:0] kernel,
    input last_in,
    output [DATA_W+LOG_KW-1:0] voxel_out,
    output valid_out,
    output done
);

    localparam OUT_W = DATA_W + LOG_KW;
    localparam N     = D * H * W;

    reg [31:0] depth_idx;
    reg [31:0] row_idx;
    reg [31:0] col_idx;

    reg [DATA_W-1:0] volume_mem [0:N-1];

    wire [31:0] linear_addr;
    assign linear_addr = (depth_idx * H * W) + (row_idx * W) + col_idx;

    wire [31:0] next_depth_idx;
    wire [31:0] next_row_idx;
    wire [31:0] next_col_idx;
    wire        coord_volume_end;

    conv3d_coord_next #(
        .D(D),
        .H(H),
        .W(W)
    ) u_coord_next (
        .depth_idx(depth_idx),
        .row_idx(row_idx),
        .col_idx(col_idx),
        .advance(valid_in),
        .last_in(last_in),
        .next_depth_idx(next_depth_idx),
        .next_row_idx(next_row_idx),
        .next_col_idx(next_col_idx),
        .volume_end(coord_volume_end)
    );

    wire region_valid;

    conv3d_valid_region #(
        .K1(K1),
        .K2(K2),
        .K3(K3),
        .D(D),
        .H(H),
        .W(W)
    ) u_valid_region (
        .depth_idx(depth_idx),
        .row_idx(row_idx),
        .col_idx(col_idx),
        .valid_region(region_valid)
    );

    wire [K1*K2*K3*DATA_W-1:0] window_flat;

    genvar gd, gh, gw;
    generate
        for (gd = 0; gd < K1; gd = gd + 1) begin : GEN_DEPTH
            for (gh = 0; gh < K2; gh = gh + 1) begin : GEN_HEIGHT
                for (gw = 0; gw < K3; gw = gw + 1) begin : GEN_WIDTH
                    localparam integer TAP_INDEX = ((gd * K2 + gh) * K3 + gw);

                    wire        tap_in_range;
                    wire        tap_is_current;
                    wire [31:0] tap_addr;
                    wire [DATA_W-1:0] tap_voxel;

                    conv3d_tap_addr #(
                        .K1(K1),
                        .K2(K2),
                        .K3(K3),
                        .D(D),
                        .H(H),
                        .W(W),
                        .TD(gd),
                        .TH(gh),
                        .TW(gw)
                    ) u_tap_addr (
                        .depth_idx(depth_idx),
                        .row_idx(row_idx),
                        .col_idx(col_idx),
                        .in_range(tap_in_range),
                        .is_current(tap_is_current),
                        .addr(tap_addr)
                    );

                    assign tap_voxel =
                        tap_is_current ? voxel_in :
                        tap_in_range   ? volume_mem[tap_addr] :
                                         {DATA_W{1'b0}};

                    assign window_flat[TAP_INDEX*DATA_W +: DATA_W] = tap_voxel;
                end
            end
        end
    endgenerate

    wire [OUT_W-1:0] mac_out;

    conv3d_mac_tree #(
        .K1(K1),
        .K2(K2),
        .K3(K3),
        .DATA_W(DATA_W),
        .LOG_KW(LOG_KW)
    ) u_mac_tree (
        .window_flat(window_flat),
        .kernel(kernel),
        .sum_out(mac_out)
    );

    assign valid_out = valid_in & region_valid & ~rst;
    assign done      = valid_in & coord_volume_end & ~rst;

    assign voxel_out = (valid_in & region_valid & ~rst) ? mac_out : {OUT_W{1'b0}};

    always @(posedge clk) begin
        if (rst) begin
            depth_idx <= 32'd0;
            row_idx   <= 32'd0;
            col_idx   <= 32'd0;
        end else if (valid_in) begin
            volume_mem[linear_addr] <= voxel_in;

            depth_idx <= next_depth_idx;
            row_idx   <= next_row_idx;
            col_idx   <= next_col_idx;
        end
    end

endmodule