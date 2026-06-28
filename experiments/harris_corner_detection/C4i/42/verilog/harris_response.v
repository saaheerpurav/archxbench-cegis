`timescale 1ns/1ps

module harris_response #(
    parameter IN_W   = 36,
    parameter RESP_W = 32,
    parameter K_W    = 8
) (
    input  signed [IN_W-1:0] ix2_s,
    input  signed [IN_W-1:0] iy2_s,
    input  signed [IN_W-1:0] ixy_s,
    input  [K_W-1:0]         k_param,
    output reg [RESP_W-1:0]  response
);

    /*
     * Harris response:
     *
     *   det   = ix2 * iy2 - ixy * ixy
     *   trace = ix2 + iy2
     *   R     = det - k * trace^2
     *
     * k_param is unsigned Q0.K_W fixed point.
     * Example for K_W=8: k_param=5 means k = 5 / 256.
     *
     * The output is an unsigned saturated response:
     *   R <= 0        -> 0
     *   R > RESP_MAX  -> RESP_MAX
     *   otherwise     -> R[RESP_W-1:0]
     */

    localparam PROD_W      = 2 * IN_W;
    localparam DET_W       = PROD_W + 1;

    localparam TRACE_W     = IN_W + 1;
    localparam TRACE_SQ_W  = 2 * TRACE_W;

    localparam K_EXT_W     = K_W + 1;
    localparam KPROD_W     = TRACE_SQ_W + K_EXT_W;

    localparam BIG_W       = (DET_W > KPROD_W) ? (DET_W + 1) : (KPROD_W + 1);
    localparam CMP_W       = (BIG_W > (RESP_W + 1)) ? (BIG_W + 1) : (RESP_W + 2);

    /*
     * Extend operands before multiplication.
     * This avoids simulator/synthesis differences or truncation caused by
     * self-determined multiply expression widths.
     */
    wire signed [PROD_W-1:0] ix2_prod_ext;
    wire signed [PROD_W-1:0] iy2_prod_ext;
    wire signed [PROD_W-1:0] ixy_prod_ext;

    assign ix2_prod_ext = {{(PROD_W-IN_W){ix2_s[IN_W-1]}}, ix2_s};
    assign iy2_prod_ext = {{(PROD_W-IN_W){iy2_s[IN_W-1]}}, iy2_s};
    assign ixy_prod_ext = {{(PROD_W-IN_W){ixy_s[IN_W-1]}}, ixy_s};

    wire signed [PROD_W-1:0] ix2_iy2_prod;
    wire signed [PROD_W-1:0] ixy_ixy_prod;

    assign ix2_iy2_prod = ix2_prod_ext * iy2_prod_ext;
    assign ixy_ixy_prod = ixy_prod_ext * ixy_prod_ext;

    wire signed [DET_W-1:0] det_w;

    assign det_w =
        {{(DET_W-PROD_W){ix2_iy2_prod[PROD_W-1]}}, ix2_iy2_prod} -
        {{(DET_W-PROD_W){ixy_ixy_prod[PROD_W-1]}}, ixy_ixy_prod};

    /*
     * trace = ix2 + iy2
     */
    wire signed [TRACE_W-1:0] ix2_trace_ext;
    wire signed [TRACE_W-1:0] iy2_trace_ext;
    wire signed [TRACE_W-1:0] trace_w;

    assign ix2_trace_ext = {{(TRACE_W-IN_W){ix2_s[IN_W-1]}}, ix2_s};
    assign iy2_trace_ext = {{(TRACE_W-IN_W){iy2_s[IN_W-1]}}, iy2_s};

    assign trace_w = ix2_trace_ext + iy2_trace_ext;

    /*
     * trace_sq = trace * trace
     */
    wire signed [TRACE_SQ_W-1:0] trace_sq_op;
    wire signed [TRACE_SQ_W-1:0] trace_sq_w;

    assign trace_sq_op = {{(TRACE_SQ_W-TRACE_W){trace_w[TRACE_W-1]}}, trace_w};
    assign trace_sq_w  = trace_sq_op * trace_sq_op;

    /*
     * k_scaled = k_param * trace_sq / 2^K_W
     */
    wire signed [KPROD_W-1:0] trace_sq_k_ext;
    wire signed [KPROD_W-1:0] k_param_ext;
    wire signed [KPROD_W-1:0] k_prod_w;
    wire signed [KPROD_W-1:0] k_scaled_w;

    assign trace_sq_k_ext = {{(KPROD_W-TRACE_SQ_W){trace_sq_w[TRACE_SQ_W-1]}}, trace_sq_w};
    assign k_param_ext    = {{(KPROD_W-K_W){1'b0}}, k_param};

    assign k_prod_w   = trace_sq_k_ext * k_param_ext;
    assign k_scaled_w = k_prod_w >>> K_W;

    /*
     * R = det - k_scaled
     */
    wire signed [BIG_W-1:0] det_big_w;
    wire signed [BIG_W-1:0] k_scaled_big_w;
    wire signed [BIG_W-1:0] r_big_w;

    assign det_big_w =
        {{(BIG_W-DET_W){det_w[DET_W-1]}}, det_w};

    assign k_scaled_big_w =
        {{(BIG_W-KPROD_W){k_scaled_w[KPROD_W-1]}}, k_scaled_w};

    assign r_big_w = det_big_w - k_scaled_big_w;

    /*
     * Saturate signed R into unsigned RESP_W-bit response.
     */
    wire signed [CMP_W-1:0] r_cmp_w;
    wire signed [CMP_W-1:0] resp_max_cmp_w;

    assign r_cmp_w =
        {{(CMP_W-BIG_W){r_big_w[BIG_W-1]}}, r_big_w};

    assign resp_max_cmp_w =
        {{(CMP_W-(RESP_W+1)){1'b0}}, 1'b0, {RESP_W{1'b1}}};

    localparam [RESP_W-1:0] RESP_ZERO = {RESP_W{1'b0}};
    localparam [RESP_W-1:0] RESP_MAX  = {RESP_W{1'b1}};

    always @* begin
        if (r_cmp_w <= {CMP_W{1'b0}}) begin
            response = RESP_ZERO;
        end else if (r_cmp_w > resp_max_cmp_w) begin
            response = RESP_MAX;
        end else begin
            response = r_cmp_w[RESP_W-1:0];
        end
    end

endmodule