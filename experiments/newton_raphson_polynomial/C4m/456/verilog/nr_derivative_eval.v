`timescale 1ns/1ps

module nr_derivative_eval #(
    parameter WIDTH = 16,
    parameter FRAC = 8,
    parameter EXT_WIDTH = (WIDTH * 4) + 8
)(
    input  signed [WIDTH-1:0] x,
    input  signed [WIDTH-1:0] coeff1,
    input  signed [WIDTH-1:0] coeff2,
    input  signed [WIDTH-1:0] coeff3,
    output signed [EXT_WIDTH-1:0] p_prime
);

    function signed [EXT_WIDTH-1:0] sext;
        input signed [WIDTH-1:0] v;
        begin
            sext = {{(EXT_WIDTH-WIDTH){v[WIDTH-1]}}, v};
        end
    endfunction

    function signed [EXT_WIDTH-1:0] fixed_mul;
        input signed [EXT_WIDTH-1:0] a;
        input signed [EXT_WIDTH-1:0] b;
        reg signed [(2*EXT_WIDTH)-1:0] product;
        begin
            product = a * b;
            fixed_mul = product >>> FRAC;
        end
    endfunction

    wire signed [EXT_WIDTH-1:0] x_ext  = sext(x);
    wire signed [EXT_WIDTH-1:0] c1_ext = sext(coeff1);
    wire signed [EXT_WIDTH-1:0] c2_ext = sext(coeff2);
    wire signed [EXT_WIDTH-1:0] c3_ext = sext(coeff3);

    wire signed [EXT_WIDTH-1:0] two_c2   = c2_ext << 1;
    wire signed [EXT_WIDTH-1:0] three_c3 = (c3_ext << 1) + c3_ext;

    wire signed [EXT_WIDTH-1:0] h1 = fixed_mul(three_c3, x_ext) + two_c2;

    assign p_prime = fixed_mul(h1, x_ext) + c1_ext;

endmodule