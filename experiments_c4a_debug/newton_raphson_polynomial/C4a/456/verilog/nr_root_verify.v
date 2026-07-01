`timescale 1ns/1ps

module nr_root_verify #(
    parameter WIDTH = 16,
    parameter FRAC = 8,
    parameter EXT_WIDTH = 64,
    parameter signed [WIDTH-1:0] TOLERANCE = 8
)(
    input signed [EXT_WIDTH-1:0] poly,
    output valid
);
    wire signed [EXT_WIDTH-1:0] tol_ext;
    wire [EXT_WIDTH:0] abs_poly_mag;
    wire [EXT_WIDTH:0] tol_mag;

    assign tol_ext = {{(EXT_WIDTH-WIDTH){TOLERANCE[WIDTH-1]}}, TOLERANCE};

    assign abs_poly_mag = poly[EXT_WIDTH-1]
        ? ({1'b0, ~poly} + {{EXT_WIDTH{1'b0}}, 1'b1})
        : {1'b0, poly};

    assign tol_mag = tol_ext[EXT_WIDTH-1]
        ? {EXT_WIDTH+1{1'b0}}
        : {1'b0, tol_ext};

    assign valid = (abs_poly_mag <= tol_mag);

endmodule