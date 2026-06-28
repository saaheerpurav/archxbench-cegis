`timescale 1ns/1ps

module conv1d_window5 #(
    parameter DATA_W = 8
) (
    input  [DATA_W-1:0] data_current,
    input  [DATA_W-1:0] delay1,
    input  [DATA_W-1:0] delay2,
    input  [DATA_W-1:0] delay3,
    input  [DATA_W-1:0] delay4,
    output [DATA_W-1:0] tap0,
    output [DATA_W-1:0] tap1,
    output [DATA_W-1:0] tap2,
    output [DATA_W-1:0] tap3,
    output [DATA_W-1:0] tap4
);

    assign tap0 = data_current;
    assign tap1 = delay1;
    assign tap2 = delay2;
    assign tap3 = delay3;
    assign tap4 = delay4;

endmodule