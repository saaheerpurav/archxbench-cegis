`timescale 1ns/1ps

module harris_response_calc #(
    parameter SMOOTH_W = 36,
    parameter RESP_W   = 32,
    parameter K_W      = 8
) (
    input  signed [SMOOTH_W-1:0] ix2_s,
    input  signed [SMOOTH_W-1:0] iy2_s,
    input  signed [SMOOTH_W-1:0] ixy_s,
    input         [K_W-1:0]      k_param,
    output signed [RESP_W-1:0]   response
);

    localparam INT_W = 96;

    wire signed [INT_W-1:0] ix2_ext = {{(INT_W-SMOOTH_W){ix2_s[SMOOTH_W-1]}}, ix2_s};
    wire signed [INT_W-1:0] iy2_ext = {{(INT_W-SMOOTH_W){iy2_s[SMOOTH_W-1]}}, iy2_s};
    wire signed [INT_W-1:0] ixy_ext = {{(INT_W-SMOOTH_W){ixy_s[SMOOTH_W-1]}}, ixy_s};
    wire signed [INT_W-1:0] k_ext   = {{(INT_W-K_W){1'b0}}, k_param};

    wire signed [INT_W-1:0] trace      = ix2_ext + iy2_ext;
    wire signed [INT_W-1:0] det_term   = (ix2_ext * iy2_ext) - (ixy_ext * ixy_ext);
    wire signed [INT_W-1:0] trace_term = trace * trace;

    wire signed [INT_W-1:0] k_term   = (k_ext * trace_term) >>> 7;
    wire signed [INT_W-1:0] r_full   = det_term - k_term;
    wire signed [INT_W-1:0] r_scaled = r_full >>> 12;

    wire signed [RESP_W-1:0] resp_max_narrow = {1'b0, {(RESP_W-1){1'b1}}};
    wire signed [RESP_W-1:0] resp_min_narrow = {1'b1, {(RESP_W-1){1'b0}}};

    wire signed [INT_W-1:0] resp_max =
        {{(INT_W-RESP_W){resp_max_narrow[RESP_W-1]}}, resp_max_narrow};
    wire signed [INT_W-1:0] resp_min =
        {{(INT_W-RESP_W){resp_min_narrow[RESP_W-1]}}, resp_min_narrow};

    assign response = (r_scaled > resp_max) ? resp_max_narrow :
                      (r_scaled < resp_min) ? resp_min_narrow :
                      r_scaled[RESP_W-1:0];

endmodule