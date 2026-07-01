`timescale 1ns/1ps

module nr_root_verify #(
    parameter WIDTH = 16,
    parameter EXT_WIDTH = (WIDTH * 4) + 8
)(
    input signed [EXT_WIDTH-1:0] p,
    input signed [WIDTH-1:0] tolerance,
    output valid
);

    wire signed [EXT_WIDTH-1:0] tol_ext;
    wire [EXT_WIDTH:0] p_mag;
    wire [EXT_WIDTH:0] tol_mag;

    assign tol_ext = {{(EXT_WIDTH-WIDTH){tolerance[WIDTH-1]}}, tolerance};

    assign p_mag   = p[EXT_WIDTH-1]       ? ({1'b0, ~p} + {{EXT_WIDTH{1'b0}}, 1'b1})
                                          : {1'b0, p};

    assign tol_mag = tol_ext[EXT_WIDTH-1] ? ({1'b0, ~tol_ext} + {{EXT_WIDTH{1'b0}}, 1'b1})
                                          : {1'b0, tol_ext};

    assign valid = (p_mag <= tol_mag);

endmodule