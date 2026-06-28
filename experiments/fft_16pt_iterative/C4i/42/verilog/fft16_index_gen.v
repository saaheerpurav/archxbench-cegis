`timescale 1ns/1ps

module fft16_index_gen #(
    parameter N = 16
) (
    input  [$clog2(N)-1:0] stage,
    input  [$clog2(N)-1:0] butterfly_count,
    output reg [$clog2(N)-1:0] idx_p,
    output reg [$clog2(N)-1:0] idx_q,
    output reg [$clog2(N)-1:0] twiddle_idx
);

    localparam ADDR_W = $clog2(N);

    reg [31:0] half_size;
    reg [31:0] span;
    reg [31:0] local_j;
    reg [31:0] group;
    reg [31:0] p_calc;
    reg [31:0] q_calc;
    reg [31:0] tw_calc;

    always @(*) begin
        half_size = (32'd1 << stage);
        span      = (half_size << 1);

        local_j = butterfly_count & (half_size - 32'd1);
        group   = butterfly_count >> stage;

        p_calc = group * span + local_j;
        q_calc = p_calc + half_size;

        if (span <= N)
            tw_calc = local_j * (N / span);
        else
            tw_calc = 32'd0;

        idx_p       = p_calc[ADDR_W-1:0];
        idx_q       = q_calc[ADDR_W-1:0];
        twiddle_idx = tw_calc[ADDR_W-1:0];
    end

endmodule