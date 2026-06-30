`timescale 1ns/1ps

module nr_deriv_eval_fixed #(
    parameter WIDTH = 16,
    parameter FRAC  = 8
)(
    input  signed [WIDTH-1:0] x,
    input  signed [WIDTH-1:0] coeff1,
    input  signed [WIDTH-1:0] coeff2,
    input  signed [WIDTH-1:0] coeff3,
    output signed [WIDTH-1:0] deriv
);

    localparam EXT = WIDTH * 4;
    localparam MUL = EXT * 2;

    wire signed [EXT-1:0] x_ext  = {{(EXT-WIDTH){x[WIDTH-1]}}, x};
    wire signed [EXT-1:0] c1_ext = {{(EXT-WIDTH){coeff1[WIDTH-1]}}, coeff1};
    wire signed [EXT-1:0] c2_ext = {{(EXT-WIDTH){coeff2[WIDTH-1]}}, coeff2};
    wire signed [EXT-1:0] c3_ext = {{(EXT-WIDTH){coeff3[WIDTH-1]}}, coeff3};

    function signed [EXT-1:0] fixed_mul;
        input signed [EXT-1:0] a;
        input signed [EXT-1:0] b;
        reg signed [MUL-1:0] a_wide;
        reg signed [MUL-1:0] b_wide;
        reg signed [(2*MUL)-1:0] product;
        begin
            a_wide  = {{EXT{a[EXT-1]}}, a};
            b_wide  = {{EXT{b[EXT-1]}}, b};
            product = a_wide * b_wide;
            fixed_mul = product >>> FRAC;
        end
    endfunction

    wire signed [EXT-1:0] c3_x = fixed_mul(c3_ext, x_ext);
    wire signed [EXT-1:0] inner = (c3_x << 1) + c3_x + (c2_ext << 1);
    wire signed [EXT-1:0] deriv_ext = fixed_mul(inner, x_ext) + c1_ext;

    assign deriv = deriv_ext[WIDTH-1:0];

endmodule