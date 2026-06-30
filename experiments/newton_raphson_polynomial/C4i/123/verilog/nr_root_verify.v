`timescale 1ns/1ps

module nr_root_verify #(
    parameter WIDTH = 16,
    parameter signed [WIDTH-1:0] TOLERANCE = 8
)(
    input signed [WIDTH-1:0] poly_value,
    output valid
);

    wire signed [WIDTH:0] poly_ext = {poly_value[WIDTH-1], poly_value};
    wire signed [WIDTH:0] tol_ext  = {TOLERANCE[WIDTH-1], TOLERANCE};

    wire [WIDTH:0] abs_poly = poly_ext[WIDTH] ? -poly_ext : poly_ext;
    wire [WIDTH:0] abs_tol  = tol_ext[WIDTH]  ? -tol_ext  : tol_ext;

    assign valid = (abs_poly <= abs_tol);

endmodule