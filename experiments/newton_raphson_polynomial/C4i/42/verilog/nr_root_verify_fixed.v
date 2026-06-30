`timescale 1ns/1ps

module nr_root_verify_fixed #(
    parameter WIDTH = 16,
    parameter FRAC = 8,
    parameter XW = 64
)(
    input signed [XW-1:0] poly_value,
    input signed [WIDTH-1:0] tolerance,
    output valid
);

    wire signed [XW-1:0] tolerance_ext;
    wire [XW:0] abs_poly;
    wire [XW:0] abs_tol;

    assign tolerance_ext = {{(XW-WIDTH){tolerance[WIDTH-1]}}, tolerance};

    assign abs_poly = poly_value[XW-1] ?
                      ({1'b0, ~poly_value} + {{XW{1'b0}}, 1'b1}) :
                      {1'b0, poly_value};

    assign abs_tol = tolerance_ext[XW-1] ?
                     ({1'b0, ~tolerance_ext} + {{XW{1'b0}}, 1'b1}) :
                     {1'b0, tolerance_ext};

    assign valid = (abs_poly <= abs_tol);

endmodule