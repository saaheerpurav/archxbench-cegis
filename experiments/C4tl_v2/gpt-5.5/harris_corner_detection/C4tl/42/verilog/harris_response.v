`timescale 1ns/1ps

module harris_response #(
    parameter SMOOTH_W = 36,
    parameter RESP_W   = 32,
    parameter K_W      = 8
) (
    input  signed [SMOOTH_W-1:0] sxx,
    input  signed [SMOOTH_W-1:0] syy,
    input  signed [SMOOTH_W-1:0] sxy,
    input  [K_W-1:0]             k_param,
    output [RESP_W-1:0]          response
);

    localparam integer TRACE_W    = SMOOTH_W + 1;
    localparam integer MUL_W      = 2 * SMOOTH_W;
    localparam integer DET_W      = MUL_W + 1;
    localparam integer TRACE_SQ_W = 2 * TRACE_W;
    localparam integer K_EXT_W    = K_W + 1;
    localparam integer K_MUL_W    = K_EXT_W + TRACE_SQ_W;
    localparam integer R_BASE_W   = (DET_W > K_MUL_W) ? DET_W : K_MUL_W;
    localparam integer R_W        = R_BASE_W + 1;
    localparam integer SAT_W      = (R_W > (RESP_W + 1)) ? R_W : (RESP_W + 1);

    /*
     * trace = sxx + syy
     *
     * sxx and syy are sign-extended by one bit before addition so that the
     * sum cannot overflow the input width.
     */
    wire signed [TRACE_W-1:0] sxx_trace;
    wire signed [TRACE_W-1:0] syy_trace;
    wire signed [TRACE_W-1:0] trace;

    assign sxx_trace = {sxx[SMOOTH_W-1], sxx};
    assign syy_trace = {syy[SMOOTH_W-1], syy};
    assign trace     = sxx_trace + syy_trace;

    /*
     * det = sxx * syy - sxy * sxy
     *
     * Operands are explicitly widened to MUL_W before multiplication.  This
     * avoids Verilog expression-width truncation and gives enough room for the
     * full signed product of two SMOOTH_W-bit values.
     */
    wire signed [MUL_W-1:0] sxx_mul_op;
    wire signed [MUL_W-1:0] syy_mul_op;
    wire signed [MUL_W-1:0] sxy_mul_op;

    wire signed [MUL_W-1:0] det_a;
    wire signed [MUL_W-1:0] det_b;

    wire signed [DET_W-1:0] det_a_ext;
    wire signed [DET_W-1:0] det_b_ext;
    wire signed [DET_W-1:0] det;

    assign sxx_mul_op = {{(MUL_W-SMOOTH_W){sxx[SMOOTH_W-1]}}, sxx};
    assign syy_mul_op = {{(MUL_W-SMOOTH_W){syy[SMOOTH_W-1]}}, syy};
    assign sxy_mul_op = {{(MUL_W-SMOOTH_W){sxy[SMOOTH_W-1]}}, sxy};

    assign det_a = sxx_mul_op * syy_mul_op;
    assign det_b = sxy_mul_op * sxy_mul_op;

    assign det_a_ext = {{(DET_W-MUL_W){det_a[MUL_W-1]}}, det_a};
    assign det_b_ext = {{(DET_W-MUL_W){det_b[MUL_W-1]}}, det_b};
    assign det       = det_a_ext - det_b_ext;

    /*
     * trace_sq = trace * trace
     *
     * trace is TRACE_W bits, so its square requires 2*TRACE_W bits.
     */
    wire signed [TRACE_SQ_W-1:0] trace_mul_op;
    wire signed [TRACE_SQ_W-1:0] trace_sq;

    assign trace_mul_op = {{(TRACE_SQ_W-TRACE_W){trace[TRACE_W-1]}}, trace};
    assign trace_sq     = trace_mul_op * trace_mul_op;

    /*
     * k_param is unsigned Q0.K_W fixed point.
     *
     * k_term = floor((k_param * trace_sq) / 2^K_W)
     */
    wire signed [K_EXT_W-1:0] k_fixed;
    wire signed [K_MUL_W-1:0] k_mul_op;
    wire signed [K_MUL_W-1:0] trace_sq_k_op;
    wire signed [K_MUL_W-1:0] k_scaled;
    wire signed [K_MUL_W-1:0] k_term;

    assign k_fixed      = {1'b0, k_param};
    assign k_mul_op     = {{(K_MUL_W-K_EXT_W){1'b0}}, k_fixed};
    assign trace_sq_k_op = {{(K_MUL_W-TRACE_SQ_W){trace_sq[TRACE_SQ_W-1]}}, trace_sq};

    assign k_scaled = k_mul_op * trace_sq_k_op;
    assign k_term   = k_scaled >>> K_W;

    /*
     * R = det - k_term
     */
    wire signed [R_W-1:0] det_r_ext;
    wire signed [R_W-1:0] k_r_ext;
    wire signed [R_W-1:0] r_wide;

    assign det_r_ext = {{(R_W-DET_W){det[DET_W-1]}}, det};
    assign k_r_ext   = {{(R_W-K_MUL_W){k_term[K_MUL_W-1]}}, k_term};
    assign r_wide    = det_r_ext - k_r_ext;

    /*
     * Saturate signed R into unsigned RESP_W response.
     */
    wire signed [SAT_W-1:0] r_sat_ext;
    wire signed [SAT_W-1:0] max_resp_ext;
    wire signed [SAT_W-1:0] zero_ext;

    assign r_sat_ext   = {{(SAT_W-R_W){r_wide[R_W-1]}}, r_wide};
    assign max_resp_ext = {{(SAT_W-RESP_W){1'b0}}, {RESP_W{1'b1}}};
    assign zero_ext     = {SAT_W{1'b0}};

    assign response = (r_sat_ext <= zero_ext)     ? {RESP_W{1'b0}} :
                      (r_sat_ext > max_resp_ext)  ? {RESP_W{1'b1}} :
                                                     r_sat_ext[RESP_W-1:0];

endmodule