`timescale 1ns/1ps

module nr_root_verify #(
    parameter WIDTH = 16,
    parameter FRAC = 8,
    parameter EXT = WIDTH * 4
)(
    input  signed [EXT-1:0]   p,
    input  signed [WIDTH-1:0] tolerance,
    output                    valid
);

    wire signed [EXT-1:0] tol_ext;
    wire [EXT-1:0] abs_p;
    wire [EXT-1:0] abs_tol;

    assign tol_ext = {{(EXT-WIDTH){tolerance[WIDTH-1]}}, tolerance};

    assign abs_p   = p[EXT-1]       ? $unsigned(-p)       : $unsigned(p);
    assign abs_tol = tol_ext[EXT-1] ? $unsigned(-tol_ext) : $unsigned(tol_ext);

    assign valid = (abs_p <= abs_tol);

endmodule