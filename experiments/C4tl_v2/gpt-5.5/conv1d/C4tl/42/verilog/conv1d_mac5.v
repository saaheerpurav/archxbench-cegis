`timescale 1ns/1ps

module conv1d_mac5 #(
    parameter DATA_W      = 8,
    parameter KERNEL_SIZE = 5,
    parameter GAIN_W      = 4
) (
    input      [DATA_W+GAIN_W+3-1:0] prod0,
    input      [DATA_W+GAIN_W+3-1:0] prod1,
    input      [DATA_W+GAIN_W+3-1:0] prod2,
    input      [DATA_W+GAIN_W+3-1:0] prod3,
    input      [DATA_W+GAIN_W+3-1:0] prod4,
    output     [DATA_W+GAIN_W+3-1:0] mac_sum
);

    localparam PROD_W = DATA_W + GAIN_W + 3;

    /*
     * Five unsigned product terms are accumulated combinationally.
     *
     * The extra three bits in sum_ext are enough to represent the sum of
     * five arbitrary PROD_W-bit unsigned values without intermediate
     * expression truncation. For the intended conv1d datapath, the legal
     * product values are much smaller than the full PROD_W range, so the
     * final MAC result fits in mac_sum's declared width.
     */
    wire [PROD_W+2:0] sum_ext;

    assign sum_ext =
          {3'b000, prod0}
        + {3'b000, prod1}
        + {3'b000, prod2}
        + {3'b000, prod3}
        + {3'b000, prod4};

    assign mac_sum = sum_ext[PROD_W-1:0];

endmodule