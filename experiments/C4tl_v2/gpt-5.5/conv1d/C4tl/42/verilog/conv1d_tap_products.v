`timescale 1ns/1ps

module conv1d_tap_products #(
    parameter DATA_W      = 8,
    parameter KERNEL_SIZE = 5,
    parameter GAIN_W      = 4
) (
    input      [DATA_W-1:0]             x0,
    input      [DATA_W-1:0]             x1,
    input      [DATA_W-1:0]             x2,
    input      [DATA_W-1:0]             x3,
    input      [DATA_W-1:0]             x4,
    output     [DATA_W+GAIN_W+3-1:0]    prod0,
    output     [DATA_W+GAIN_W+3-1:0]    prod1,
    output     [DATA_W+GAIN_W+3-1:0]    prod2,
    output     [DATA_W+GAIN_W+3-1:0]    prod3,
    output     [DATA_W+GAIN_W+3-1:0]    prod4
);

    localparam PROD_W = DATA_W + GAIN_W + 3;

    wire [PROD_W-1:0] x0_ext;
    wire [PROD_W-1:0] x1_ext;
    wire [PROD_W-1:0] x2_ext;
    wire [PROD_W-1:0] x3_ext;
    wire [PROD_W-1:0] x4_ext;

    assign x0_ext = {{(PROD_W-DATA_W){1'b0}}, x0};
    assign x1_ext = {{(PROD_W-DATA_W){1'b0}}, x1};
    assign x2_ext = {{(PROD_W-DATA_W){1'b0}}, x2};
    assign x3_ext = {{(PROD_W-DATA_W){1'b0}}, x3};
    assign x4_ext = {{(PROD_W-DATA_W){1'b0}}, x4};

    assign prod0 = x0_ext << 1;                   // 2  * x[n]
    assign prod1 = x1_ext << 3;                   // 8  * x[n-1]
    assign prod2 = (x2_ext << 3) + (x2_ext << 2); // 12 * x[n-2]
    assign prod3 = x3_ext << 3;                   // 8  * x[n-3]
    assign prod4 = x4_ext << 1;                   // 2  * x[n-4]

endmodule