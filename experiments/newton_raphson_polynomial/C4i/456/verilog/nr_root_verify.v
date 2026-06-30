`timescale 1ns/1ps

module nr_root_verify #(
    parameter WIDTH = 16,
    parameter FRAC = 8,
    parameter signed [WIDTH-1:0] TOLERANCE = 8
)(
    input  signed [WIDTH-1:0] x,
    input  signed [WIDTH-1:0] coeff0,
    input  signed [WIDTH-1:0] coeff1,
    input  signed [WIDTH-1:0] coeff2,
    input  signed [WIDTH-1:0] coeff3,
    output valid
);

    localparam EXT_WIDTH = WIDTH * 4;

    wire signed [EXT_WIDTH-1:0] x_ext;
    wire signed [EXT_WIDTH-1:0] c0_ext;
    wire signed [EXT_WIDTH-1:0] c1_ext;
    wire signed [EXT_WIDTH-1:0] c2_ext;
    wire signed [EXT_WIDTH-1:0] c3_ext;
    wire signed [EXT_WIDTH-1:0] tol_ext;

    wire signed [EXT_WIDTH-1:0] h2;
    wire signed [EXT_WIDTH-1:0] h1;
    wire signed [EXT_WIDTH-1:0] poly_value;

    assign x_ext   = {{(EXT_WIDTH-WIDTH){x[WIDTH-1]}}, x};
    assign c0_ext  = {{(EXT_WIDTH-WIDTH){coeff0[WIDTH-1]}}, coeff0};
    assign c1_ext  = {{(EXT_WIDTH-WIDTH){coeff1[WIDTH-1]}}, coeff1};
    assign c2_ext  = {{(EXT_WIDTH-WIDTH){coeff2[WIDTH-1]}}, coeff2};
    assign c3_ext  = {{(EXT_WIDTH-WIDTH){coeff3[WIDTH-1]}}, coeff3};
    assign tol_ext = {{(EXT_WIDTH-WIDTH){TOLERANCE[WIDTH-1]}}, TOLERANCE};

    function signed [EXT_WIDTH-1:0] fixed_mul;
        input signed [EXT_WIDTH-1:0] a;
        input signed [EXT_WIDTH-1:0] b;
        reg signed [(2*EXT_WIDTH)-1:0] product;
        begin
            product = a * b;
            fixed_mul = product >>> FRAC;
        end
    endfunction

    function signed [EXT_WIDTH-1:0] abs_ext;
        input signed [EXT_WIDTH-1:0] value;
        begin
            if (value == {1'b1, {(EXT_WIDTH-1){1'b0}}})
                abs_ext = {1'b0, {(EXT_WIDTH-1){1'b1}}};
            else if (value < 0)
                abs_ext = -value;
            else
                abs_ext = value;
        end
    endfunction

    assign h2 = fixed_mul(c3_ext, x_ext) + c2_ext;
    assign h1 = fixed_mul(h2, x_ext) + c1_ext;
    assign poly_value = fixed_mul(h1, x_ext) + c0_ext;

    assign valid = (abs_ext(poly_value) <= abs_ext(tol_ext));

endmodule