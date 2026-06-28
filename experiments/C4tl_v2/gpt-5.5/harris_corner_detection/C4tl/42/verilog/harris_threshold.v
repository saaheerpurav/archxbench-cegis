`timescale 1ns/1ps

module harris_threshold #(
    parameter RESP_W = 32
) (
    input  [RESP_W-1:0] response,
    input  [RESP_W-1:0] threshold,
    output              is_corner
);

    /*
     * Harris response R = det(M) - k * trace(M)^2 can be negative.
     *
     * The response is carried as a RESP_W-bit two's-complement value.
     * A direct unsigned comparison would incorrectly classify negative
     * responses as very large positive numbers.
     *
     * A corner is reported only when:
     *   1. response is non-negative
     *   2. response is strictly greater than threshold
     */
    assign is_corner = (~response[RESP_W-1]) && (response > threshold);

endmodule