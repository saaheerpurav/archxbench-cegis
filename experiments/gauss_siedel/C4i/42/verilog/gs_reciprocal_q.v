`timescale 1ns/1ps

module gs_reciprocal_q #(
    parameter DATA_WIDTH = 32,
    parameter FRAC       = 16
)(
    input  [DATA_WIDTH-1:0] a,
    output reg [DATA_WIDTH-1:0] reciprocal
);

    localparam NUM_WIDTH = 2 * DATA_WIDTH;

    reg signed [NUM_WIDTH-1:0] numerator_s;
    reg signed [NUM_WIDTH-1:0] divisor_s;
    reg signed [NUM_WIDTH-1:0] quotient_s;

    always @* begin
        /*
         * Fixed-point reciprocal scaling:
         *
         * If a is Qm.FRAC, then real(a) = a / 2^FRAC.
         * The reciprocal in the same Q format is:
         *
         *     reciprocal_fixed = (1 / real(a)) * 2^FRAC
         *                      = (1 / (a / 2^FRAC)) * 2^FRAC
         *                      = 2^(2*FRAC) / a
         */
        numerator_s = {{(NUM_WIDTH-1){1'b0}}, 1'b1} << (2 * FRAC);

        /*
         * Explicitly sign-extend the DATA_WIDTH-bit input to the internal
         * division width so that signed division behaves correctly.
         */
        divisor_s = {{DATA_WIDTH{a[DATA_WIDTH-1]}}, a};

        quotient_s  = {NUM_WIDTH{1'b0}};
        reciprocal  = {DATA_WIDTH{1'b0}};

        if (a != {DATA_WIDTH{1'b0}}) begin
            quotient_s = numerator_s / divisor_s;
            reciprocal = quotient_s[DATA_WIDTH-1:0];
        end
    end

endmodule