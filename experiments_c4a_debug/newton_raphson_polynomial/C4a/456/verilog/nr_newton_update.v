`timescale 1ns/1ps

module nr_newton_update #(
    parameter WIDTH = 16,
    parameter EXT_WIDTH = 64
)(
    input  signed [WIDTH-1:0]     x_current,
    input  signed [EXT_WIDTH-1:0] delta,
    input                         hold,
    output signed [WIDTH-1:0]     x_next
);

    wire signed [EXT_WIDTH-1:0] x_ext;
    wire signed [EXT_WIDTH-1:0] updated_ext;

    assign x_ext       = {{(EXT_WIDTH-WIDTH){x_current[WIDTH-1]}}, x_current};
    assign updated_ext = hold ? x_ext : (x_ext - delta);
    assign x_next      = updated_ext[WIDTH-1:0];

endmodule