`timescale 1ns/1ps

module conv1d_gain_shift #(
    parameter MAC_W  = 15,
    parameter GAIN_W = 4,
    parameter OUT_W  = 12
) (
    input  [MAC_W-1:0] mac_sum,
    output [OUT_W-1:0] data_out
);

    // Combinational normalization:
    // unsigned logical right shift by GAIN_W, equivalent to divide by 2^GAIN_W.
    assign data_out = mac_sum >> GAIN_W;

endmodule