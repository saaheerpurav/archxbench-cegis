`timescale 1ns/1ps

module harris_threshold #(
    parameter RESP_W = 32
) (
    input  signed [RESP_W-1:0] response,
    input  signed [RESP_W-1:0] threshold,
    output                    is_corner
);

    assign is_corner = ($signed(response) > $signed(threshold)) ? 1'b1 : 1'b0;

endmodule