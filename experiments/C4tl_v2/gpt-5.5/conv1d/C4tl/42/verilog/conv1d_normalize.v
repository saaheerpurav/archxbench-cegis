`timescale 1ns/1ps

module conv1d_normalize #(
    parameter DATA_W      = 8,
    parameter KERNEL_SIZE = 5,
    parameter GAIN_W      = 4
) (
    input      [DATA_W+GAIN_W+3-1:0] mac_sum,
    output     [DATA_W+GAIN_W-1:0]   data_out
);

    // Purely combinational normalization.
    // The MAC sum is unsigned, so this is a logical right shift.
    // Assignment to data_out truncates to DATA_W+GAIN_W bits.
    assign data_out = mac_sum >> GAIN_W;

endmodule