`timescale 1ns/1ps

module harris_threshold #(
    parameter RESP_W = 32
) (
    input  signed [RESP_W-1:0] response,
    input         [RESP_W-1:0] threshold,
    output                    is_corner
);

    assign is_corner = (response > 0) && ($unsigned(response) > threshold);

endmodule