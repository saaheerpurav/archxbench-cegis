`timescale 1ns/1ps

module conv1d #(
    parameter DATA_W      = 8,
    parameter KERNEL_SIZE = 5,
    parameter GAIN_W      = 4
) (
    input                          clk,
    input                          rst,
    input                          valid_in,
    input      [DATA_W-1:0]        data_in,
    output                         valid_out,
    output     [DATA_W+GAIN_W-1:0] data_out
);

    localparam MAC_W = DATA_W + GAIN_W + 3;  // ceil(log2(5)) = 3

    // Delay taps for prior valid samples:
    // x_d1 = x[n-1], x_d2 = x[n-2], ..., x_d4 = x[n-4]
    reg [DATA_W-1:0] x_d1;
    reg [DATA_W-1:0] x_d2;
    reg [DATA_W-1:0] x_d3;
    reg [DATA_W-1:0] x_d4;

    wire [MAC_W-1:0] prod0;
    wire [MAC_W-1:0] prod1;
    wire [MAC_W-1:0] prod2;
    wire [MAC_W-1:0] prod3;
    wire [MAC_W-1:0] prod4;
    wire [MAC_W-1:0] mac_sum;

    // Zero-latency valid: output is valid in the same cycle as input.
    assign valid_out = valid_in & ~rst;

    // Sequential state is kept only in the top module.
    // Shift the sample history only when a valid sample is accepted.
    always @(posedge clk) begin
        if (rst) begin
            x_d1 <= {DATA_W{1'b0}};
            x_d2 <= {DATA_W{1'b0}};
            x_d3 <= {DATA_W{1'b0}};
            x_d4 <= {DATA_W{1'b0}};
        end else if (valid_in) begin
            x_d4 <= x_d3;
            x_d3 <= x_d2;
            x_d2 <= x_d1;
            x_d1 <= data_in;
        end
    end

    conv1d_tap_products #(
        .DATA_W(DATA_W),
        .KERNEL_SIZE(KERNEL_SIZE),
        .GAIN_W(GAIN_W)
    ) u_tap_products (
        .x0(data_in),
        .x1(x_d1),
        .x2(x_d2),
        .x3(x_d3),
        .x4(x_d4),
        .prod0(prod0),
        .prod1(prod1),
        .prod2(prod2),
        .prod3(prod3),
        .prod4(prod4)
    );

    conv1d_mac5 #(
        .DATA_W(DATA_W),
        .KERNEL_SIZE(KERNEL_SIZE),
        .GAIN_W(GAIN_W)
    ) u_mac5 (
        .prod0(prod0),
        .prod1(prod1),
        .prod2(prod2),
        .prod3(prod3),
        .prod4(prod4),
        .mac_sum(mac_sum)
    );

    conv1d_normalize #(
        .DATA_W(DATA_W),
        .KERNEL_SIZE(KERNEL_SIZE),
        .GAIN_W(GAIN_W)
    ) u_normalize (
        .mac_sum(mac_sum),
        .data_out(data_out)
    );

endmodule