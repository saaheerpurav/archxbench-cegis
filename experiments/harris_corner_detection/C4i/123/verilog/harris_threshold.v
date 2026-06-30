`timescale 1ns/1ps

module harris_threshold #(
    parameter RESP_W = 32
) (
    input  signed [RESP_W-1:0] response,
    input         [RESP_W-1:0] threshold,
    output                    is_corner
);

    wire signed [RESP_W:0] response_ext;
    wire signed [RESP_W:0] threshold_ext;

    assign response_ext  = {response[RESP_W-1], response};
    assign threshold_ext = {1'b0, threshold};

    assign is_corner = (response_ext > threshold_ext);

endmodule