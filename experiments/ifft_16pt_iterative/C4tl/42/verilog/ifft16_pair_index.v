`timescale 1ns/1ps

module ifft16_pair_index #(
    parameter N       = 16,
    parameter IDX_W   = 4,
    parameter STAGE_W = 2
) (
    input  [STAGE_W-1:0] stage,
    input  [IDX_W-1:0]   j,
    input  [IDX_W-1:0]   group,
    output reg [IDX_W-1:0] p_idx,
    output reg [IDX_W-1:0] q_idx,
    output reg [IDX_W-1:0] tw_idx,
    output reg             last_group,
    output reg             last_stage,
    output reg             last_all
);

    localparam STAGES = $clog2(N);

    integer m_int;
    integer half_int;
    integer groups_int;
    integer p_int;
    integer q_int;
    integer tw_int;

    always @* begin
        /*
         * Radix-2 DIT stage geometry:
         *
         * stage s:
         *   m      = 2^(s+1)
         *   half   = 2^s
         *   groups = N / m
         *
         * butterfly operands:
         *   p = group*m + j
         *   q = p + half
         *
         * twiddle exponent:
         *   tw = j * N/m
         */
        m_int      = (1 << (stage + 1));
        half_int   = (1 << stage);
        groups_int = N / m_int;

        p_int  = group * m_int + j;
        q_int  = p_int + half_int;
        tw_int = j * (N / m_int);

        p_idx  = p_int[IDX_W-1:0];
        q_idx  = q_int[IDX_W-1:0];
        tw_idx = tw_int[IDX_W-1:0];

        last_group = (group == (groups_int - 1));
        last_stage = (j == (half_int - 1)) && last_group;
        last_all   = (stage == (STAGES - 1)) && last_stage;
    end

endmodule