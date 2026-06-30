`timescale 1ns/1ps

module nr_poly_eval_fixed #(
    parameter WIDTH = 16,
    parameter FRAC  = 8
)(
    input  signed [WIDTH-1:0] x,
    input  signed [WIDTH-1:0] coeff0,
    input  signed [WIDTH-1:0] coeff1,
    input  signed [WIDTH-1:0] coeff2,
    input  signed [WIDTH-1:0] coeff3,
    output signed [WIDTH-1:0] poly
);

    localparam EXT = WIDTH * 4;

    wire signed [EXT-1:0] x_ext  = {{(EXT-WIDTH){x[WIDTH-1]}},      x};
    wire signed [EXT-1:0] c0_ext = {{(EXT-WIDTH){coeff0[WIDTH-1]}}, coeff0};
    wire signed [EXT-1:0] c1_ext = {{(EXT-WIDTH){coeff1[WIDTH-1]}}, coeff1};
    wire signed [EXT-1:0] c2_ext = {{(EXT-WIDTH){coeff2[WIDTH-1]}}, coeff2};
    wire signed [EXT-1:0] c3_ext = {{(EXT-WIDTH){coeff3[WIDTH-1]}}, coeff3};

    function signed [EXT-1:0] fixed_mul;
        input signed [EXT-1:0] a;
        input signed [EXT-1:0] b;
        reg signed [(2*EXT)-1:0] prod;
        reg signed [(2*EXT)-1:0] scaled;
        begin
            prod = a * b;

            if (prod < 0)
                scaled = -((-prod) >> FRAC);
            else
                scaled = prod >> FRAC;

            fixed_mul = scaled[EXT-1:0];
        end
    endfunction

    wire signed [EXT-1:0] h2 = fixed_mul(c3_ext, x_ext) + c2_ext;
    wire signed [EXT-1:0] h1 = fixed_mul(h2,     x_ext) + c1_ext;
    wire signed [EXT-1:0] h0 = fixed_mul(h1,     x_ext) + c0_ext;

    assign poly = h0[WIDTH-1:0];

endmodule