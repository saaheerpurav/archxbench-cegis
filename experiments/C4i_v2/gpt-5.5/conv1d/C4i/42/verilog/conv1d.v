`timescale 1ns/1ps

module conv1d #(
    parameter DATA_W      = 8,
    parameter KERNEL_SIZE = 5,
    parameter GAIN_W      = 4
) (
    input                           clk,
    input                           rst,
    input                           valid_in,
    input      [DATA_W-1:0]         data_in,
    output                          valid_out,
    output     [DATA_W+GAIN_W-1:0]  data_out
);

    // KERNEL_SIZE is fixed at 5 by specification.
    // ceil(log2(5)) = 3.
    localparam MAC_W = DATA_W + GAIN_W + 3;

    reg [DATA_W-1:0] delay1;
    reg [DATA_W-1:0] delay2;
    reg [DATA_W-1:0] delay3;
    reg [DATA_W-1:0] delay4;

    wire [DATA_W-1:0] tap0;
    wire [DATA_W-1:0] tap1;
    wire [DATA_W-1:0] tap2;
    wire [DATA_W-1:0] tap3;
    wire [DATA_W-1:0] tap4;

    wire [MAC_W-1:0] prod0;
    wire [MAC_W-1:0] prod1;
    wire [MAC_W-1:0] prod2;
    wire [MAC_W-1:0] prod3;
    wire [MAC_W-1:0] prod4;

    wire [MAC_W-1:0] mac_sum;

    assign valid_out = valid_in & ~rst;

    always @(posedge clk) begin
        if (rst) begin
            delay1 <= {DATA_W{1'b0}};
            delay2 <= {DATA_W{1'b0}};
            delay3 <= {DATA_W{1'b0}};
            delay4 <= {DATA_W{1'b0}};
        end else if (valid_in) begin
            delay4 <= delay3;
            delay3 <= delay2;
            delay2 <= delay1;
            delay1 <= data_in;
        end
    end

    conv1d_window5 #(
        .DATA_W(DATA_W)
    ) u_window5 (
        .data_current(data_in),
        .delay1(delay1),
        .delay2(delay2),
        .delay3(delay3),
        .delay4(delay4),
        .tap0(tap0),
        .tap1(tap1),
        .tap2(tap2),
        .tap3(tap3),
        .tap4(tap4)
    );

    conv1d_mult5_fixed #(
        .DATA_W(DATA_W),
        .MAC_W(MAC_W)
    ) u_mult5_fixed (
        .tap0(tap0),
        .tap1(tap1),
        .tap2(tap2),
        .tap3(tap3),
        .tap4(tap4),
        .prod0(prod0),
        .prod1(prod1),
        .prod2(prod2),
        .prod3(prod3),
        .prod4(prod4)
    );

    conv1d_mac5 #(
        .MAC_W(MAC_W)
    ) u_mac5 (
        .prod0(prod0),
        .prod1(prod1),
        .prod2(prod2),
        .prod3(prod3),
        .prod4(prod4),
        .mac_sum(mac_sum)
    );

    conv1d_gain_shift #(
        .MAC_W(MAC_W),
        .GAIN_W(GAIN_W),
        .OUT_W(DATA_W+GAIN_W)
    ) u_gain_shift (
        .mac_sum(mac_sum),
        .data_out(data_out)
    );

endmodule