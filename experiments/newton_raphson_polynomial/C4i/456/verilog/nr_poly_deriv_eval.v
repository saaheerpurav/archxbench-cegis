`timescale 1ns/1ps

module nr_poly_deriv_eval #(
    parameter WIDTH = 16,
    parameter FRAC  = 8
)(
    input  signed [WIDTH-1:0] x,
    input  signed [WIDTH-1:0] coeff0,
    input  signed [WIDTH-1:0] coeff1,
    input  signed [WIDTH-1:0] coeff2,
    input  signed [WIDTH-1:0] coeff3,
    output signed [WIDTH-1:0] poly,
    output signed [WIDTH-1:0] deriv
);

    function signed [WIDTH-1:0] sat_signed;
        input signed [127:0] value;
        reg signed [127:0] max_val;
        reg signed [127:0] min_val;
        begin
            max_val = (128'sd1 << (WIDTH - 1)) - 128'sd1;
            min_val = -(128'sd1 << (WIDTH - 1));

            if (value > max_val)
                sat_signed = {1'b0, {(WIDTH-1){1'b1}}};
            else if (value < min_val)
                sat_signed = {1'b1, {(WIDTH-1){1'b0}}};
            else
                sat_signed = value[WIDTH-1:0];
        end
    endfunction

    function signed [127:0] round_shift;
        input signed [127:0] value;
        input integer shift_amt;
        reg signed [127:0] half;
        begin
            if (shift_amt == 0) begin
                round_shift = value;
            end else begin
                half = 128'sd1 << (shift_amt - 1);
                round_shift = (value + half) >>> shift_amt;
            end
        end
    endfunction

    wire signed [127:0] sx  = {{(128-WIDTH){x[WIDTH-1]}}, x};
    wire signed [127:0] sc0 = {{(128-WIDTH){coeff0[WIDTH-1]}}, coeff0};
    wire signed [127:0] sc1 = {{(128-WIDTH){coeff1[WIDTH-1]}}, coeff1};
    wire signed [127:0] sc2 = {{(128-WIDTH){coeff2[WIDTH-1]}}, coeff2};
    wire signed [127:0] sc3 = {{(128-WIDTH){coeff3[WIDTH-1]}}, coeff3};

    wire signed [127:0] x2 = sx * sx;
    wire signed [127:0] x3 = x2 * sx;

    wire signed [127:0] poly_val =
        sc0 +
        round_shift(sc1 * sx, FRAC) +
        round_shift(sc2 * x2, 2 * FRAC) +
        round_shift(sc3 * x3, 3 * FRAC);

    wire signed [127:0] deriv_val =
        sc1 +
        round_shift((sc2 * 128'sd2) * sx, FRAC) +
        round_shift((sc3 * 128'sd3) * x2, 2 * FRAC);

    assign poly  = sat_signed(poly_val);
    assign deriv = sat_signed(deriv_val);

endmodule