`timescale 1ns/1ps

module bandpass_fir_scaler #(
    parameter ACC_W = 64,
    parameter OUT_W = 24,
    parameter SHIFT = 15
) (
    input  signed [ACC_W-1:0] acc_sum,
    output signed [OUT_W-1:0] data_out
);

    assign data_out = acc_sum >>> SHIFT;

endmodule