`timescale 1ns/1ps

module fft16_index_gen #(
    parameter N = 16,
    parameter LOGN = 4
) (
    input [LOGN-1:0] stage,
    input [LOGN-1:0] bf_count,
    output reg [LOGN-1:0] idx_p,
    output reg [LOGN-1:0] idx_q,
    output reg [LOGN-1:0] tw_idx
);

    integer half_size;
    integer span_size;
    integer group_idx;
    integer j_idx;
    integer tw_step;

    always @* begin
        half_size = (1 << stage);
        span_size = (2 << stage);
        group_idx = bf_count / half_size;
        j_idx     = bf_count % half_size;
        tw_step   = N / span_size;

        idx_p  = group_idx * span_size + j_idx;
        idx_q  = idx_p + half_size;
        tw_idx = j_idx * tw_step;
    end

endmodule