`timescale 1ns/1ps

module sqrt_nr_divide #(
    parameter N = 16,
    parameter M = 8
)(
    input  [N-1:0] X,
    input  [N-1:0] y,
    output reg [N-1:0] quotient
);

    /*
        Fixed-point division:

            quotient_real = X_real / y_real

        Since X and y are stored with M fractional bits:

            X_real = X / 2^M
            y_real = y / 2^M

        The fixed-point quotient should be:

            quotient = quotient_real * 2^M
                     = ((X / 2^M) / (y / 2^M)) * 2^M
                     = (X * 2^M) / y
                     = (X << M) / y

        Use an extended dividend width to preserve the shifted value before
        division, then saturate the result back to N bits.
    */

    localparam W = N + M + 1;

    wire [W-1:0] dividend;
    wire [W-1:0] divisor;
    wire [W-1:0] max_n_extended;

    reg  [W-1:0] quotient_full;

    assign dividend       = ({{(W-N){1'b0}}, X} << M);
    assign divisor        = {{(W-N){1'b0}}, y};
    assign max_n_extended = {{(W-N){1'b0}}, {N{1'b1}}};

    always @* begin
        quotient_full = {W{1'b0}};
        quotient      = {N{1'b0}};

        if (y == {N{1'b0}}) begin
            /*
                For the square-root datapath, X=0 and y=0 should produce 0.
                For a nonzero numerator with zero denominator, saturate.
            */
            if (X == {N{1'b0}})
                quotient = {N{1'b0}};
            else
                quotient = {N{1'b1}};
        end else begin
            quotient_full = dividend / divisor;

            if (quotient_full > max_n_extended)
                quotient = {N{1'b1}};
            else
                quotient = quotient_full[N-1:0];
        end
    end

endmodule