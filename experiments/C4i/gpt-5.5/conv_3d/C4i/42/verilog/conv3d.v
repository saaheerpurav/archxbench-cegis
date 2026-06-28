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

    localparam NUM_TAPS = K1 * K2 * K3;
    localparam OUT_W    = DATA_W + LOG_KW;

    reg [31:0] x_pos;
    reg [31:0] y_pos;
    reg [31:0] z_pos;

    wire [31:0] next_x;
    wire [31:0] next_y;
    wire [31:0] next_z;
    wire        coord_done;

    wire        region_valid;
    wire        kernel_nonzero;
    wire [NUM_TAPS*DATA_W-1:0] window_flat;
    wire [OUT_W-1:0] mac_result;

    conv3d_coord_update_comb #(
        .D(D),
        .H(H),
        .W(W)
    ) u_coord_update (
        .x_cur(x_pos),
        .y_cur(y_pos),
        .z_cur(z_pos),
        .valid_in(valid_in),
        .last_in(last_in),
        .x_next(next_x),
        .y_next(next_y),
        .z_next(next_z),
        .end_of_volume(coord_done)
    );

    conv3d_valid_region_comb #(
        .K1(K1),
        .K2(K2),
        .K3(K3)
    ) u_valid_region (
        .x_cur(x_pos),
        .y_cur(y_pos),
        .z_cur(z_pos),
        .valid_in(valid_in),
        .window_valid(region_valid)
    );

    conv3d_kernel_activity_comb #(
        .KERNEL_W(K1*K2*K3*DATA_W)
    ) u_kernel_activity (
        .kernel(kernel),
        .kernel_nonzero(kernel_nonzero)
    );

    conv3d_window_formatter_comb #(
        .K1(K1),
        .K2(K2),
        .K3(K3),
        .DATA_W(DATA_W)
    ) u_window_formatter (
        .voxel_in(voxel_in),
        .window_flat(window_flat)
    );

    conv3d_mac_array_comb #(
        .NUM_TAPS(NUM_TAPS),
        .DATA_W(DATA_W),
        .OUT_W(OUT_W)
    ) u_mac_array (
        .window_flat(window_flat),
        .kernel_flat(kernel),
        .enable(region_valid),
        .result(mac_result)
    );

    always @(posedge clk) begin
        if (rst) begin
            x_pos <= 32'd0;
            y_pos <= 32'd0;
            z_pos <= 32'd0;
        end else if (valid_in) begin
            x_pos <= next_x;
            y_pos <= next_y;
            z_pos <= next_z;
        end
    end

    assign voxel_out = kernel_nonzero ? mac_result : {OUT_W{1'b0}};
    assign valid_out = region_valid;
    assign done = coord_done;

endmodule