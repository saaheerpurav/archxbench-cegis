`timescale 1ns/1ps

module harris_response #(
    parameter IN_W = 36,
    parameter RESP_W = 32,
    parameter K_W = 8
) (
    input  signed [IN_W-1:0] ix2,
    input  signed [IN_W-1:0] iy2,
    input  signed [IN_W-1:0] ixy,
    input         [K_W-1:0]  k_param,
    output signed [RESP_W-1:0] response
);
    localparam MUL_W      = 2 * IN_W;
    localparam DET_W      = MUL_W + 1;
    localparam TRACE_W    = IN_W + 1;
    localparam TRACE_SQ_W = 2 * TRACE_W;
    localparam K_EXT_W    = K_W + 1;
    localparam K_TERM_W   = TRACE_SQ_W + K_EXT_W;
    localparam ACC_W      = K_TERM_W + 1;

    wire signed [MUL_W-1:0] det_a;
    wire signed [MUL_W-1:0] det_b;
    wire signed [DET_W-1:0] det;

    wire signed [TRACE_W-1:0] trace;
    wire signed [TRACE_SQ_W-1:0] trace_sq;

    wire signed [K_EXT_W-1:0] k_signed;
    wire signed [K_TERM_W-1:0] k_term_full;
    wire signed [ACC_W-1:0] det_ext;
    wire signed [ACC_W-1:0] k_term_ext;
    wire signed [ACC_W-1:0] k_term_scaled;
    wire signed [ACC_W-1:0] resp_full;

    assign det_a = ix2 * iy2;
    assign det_b = ixy * ixy;
    assign det   = {det_a[MUL_W-1], det_a} - {det_b[MUL_W-1], det_b};

    assign trace    = ix2 + iy2;
    assign trace_sq = trace * trace;

    assign k_signed    = {1'b0, k_param};
    assign k_term_full = k_signed * trace_sq;

    assign det_ext = {{(ACC_W-DET_W){det[DET_W-1]}}, det};
    assign k_term_ext = {{(ACC_W-K_TERM_W){k_term_full[K_TERM_W-1]}}, k_term_full};
    assign k_term_scaled = k_term_ext >>> K_W;

    assign resp_full = det_ext - k_term_scaled;

    assign response = resp_full[RESP_W-1:0];

endmodule