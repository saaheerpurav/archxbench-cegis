`timescale 1ns/1ps

module conv3d #(
    parameter K1 = 3,
    parameter K2 = 3,
    parameter K3 = 3,
    parameter D = 8,
    parameter H = 64,
    parameter W = 64,
    parameter DATA_W = 8,
    parameter LOG_KW = 4
) (
    input clk,
    input rst,
    input [DATA_W-1:0] voxel_in,
    input valid_in,
    input [K1*K2*K3*DATA_W-1:0] kernel,
    input last_in,
    output reg [DATA_W+LOG_KW-1:0] voxel_out,
    output reg valid_out,
    output reg done
);

    localparam N = D * H * W;
    localparam KTOT = K1 * K2 * K3;
    localparam OUT_W = DATA_W + LOG_KW;
    localparam ACC_W = (2 * DATA_W) + LOG_KW + 8;

    reg [DATA_W-1:0] volume_mem [0:N-1];

    reg [31:0] x_pos;
    reg [31:0] y_pos;
    reg [31:0] z_pos;
    reg [31:0] wr_addr;

    reg [KTOT*DATA_W-1:0] window_reg;

    wire window_valid_c;
    wire done_c;
    wire [KTOT*DATA_W-1:0] window_ordered_c;
    wire [ACC_W-1:0] mac_sum_c;
    wire [OUT_W-1:0] formatted_c;

    integer i;
    integer kz;
    integer ky;
    integer kx;
    integer wi;
    integer mem_index;
    integer rz;
    integer ry;
    integer rx;

    conv3d_window_valid #(
        .K1(K1), .K2(K2), .K3(K3),
        .D(D), .H(H), .W(W)
    ) u_window_valid (
        .valid_in(valid_in),
        .x_pos(x_pos),
        .y_pos(y_pos),
        .z_pos(z_pos),
        .window_valid(window_valid_c)
    );

    conv3d_window_pack #(
        .K1(K1), .K2(K2), .K3(K3),
        .DATA_W(DATA_W)
    ) u_window_pack (
        .window_in(window_reg),
        .window_out(window_ordered_c)
    );

    conv3d_mac #(
        .K1(K1), .K2(K2), .K3(K3),
        .DATA_W(DATA_W),
        .ACC_W(ACC_W)
    ) u_mac (
        .window(window_ordered_c),
        .kernel(kernel),
        .sum(mac_sum_c)
    );

    conv3d_output_format #(
        .IN_W(ACC_W),
        .OUT_W(OUT_W)
    ) u_output_format (
        .sum_in(mac_sum_c),
        .voxel_out(formatted_c)
    );

    conv3d_done_ctrl u_done_ctrl (
        .valid_in(valid_in),
        .last_in(last_in),
        .done(done_c)
    );

    always @(posedge clk) begin
        if (rst) begin
            x_pos <= 0;
            y_pos <= 0;
            z_pos <= 0;
            wr_addr <= 0;
            voxel_out <= 0;
            valid_out <= 0;
            done <= 0;
            window_reg <= 0;
            for (i = 0; i < N; i = i + 1)
                volume_mem[i] <= 0;
        end else begin
            done <= done_c;
            valid_out <= window_valid_c;

            if (valid_in) begin
                volume_mem[wr_addr] <= voxel_in;

                for (kz = 0; kz < K1; kz = kz + 1) begin
                    for (ky = 0; ky < K2; ky = ky + 1) begin
                        for (kx = 0; kx < K3; kx = kx + 1) begin
                            wi = ((kz * K2 * K3) + (ky * K3) + kx);
                            rz = z_pos - (K1 - 1 - kz);
                            ry = y_pos - (K2 - 1 - ky);
                            rx = x_pos - (K3 - 1 - kx);
                            mem_index = ((rz * H * W) + (ry * W) + rx);

                            if (window_valid_c) begin
                                if (mem_index == wr_addr)
                                    window_reg[wi*DATA_W +: DATA_W] <= voxel_in;
                                else
                                    window_reg[wi*DATA_W +: DATA_W] <= volume_mem[mem_index];
                            end else begin
                                window_reg[wi*DATA_W +: DATA_W] <= 0;
                            end
                        end
                    end
                end

                if (window_valid_c)
                    voxel_out <= formatted_c;
                else
                    voxel_out <= 0;

                if (last_in) begin
                    x_pos <= 0;
                    y_pos <= 0;
                    z_pos <= 0;
                    wr_addr <= 0;
                end else begin
                    wr_addr <= wr_addr + 1;
                    if (x_pos == W - 1) begin
                        x_pos <= 0;
                        if (y_pos == H - 1) begin
                            y_pos <= 0;
                            if (z_pos == D - 1)
                                z_pos <= 0;
                            else
                                z_pos <= z_pos + 1;
                        end else begin
                            y_pos <= y_pos + 1;
                        end
                    end else begin
                        x_pos <= x_pos + 1;
                    end
                end
            end else begin
                voxel_out <= 0;
                valid_out <= 0;
            end
        end
    end

endmodule