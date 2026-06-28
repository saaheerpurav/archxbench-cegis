`timescale 1ns/1ps

module fft16_addr_gen #(
    parameter N       = 16,
    parameter ADDR_W  = 4,
    parameter STAGE_W = 2
) (
    input  [STAGE_W-1:0] stage,
    input  [ADDR_W-1:0]  butterfly,
    output reg [ADDR_W-1:0] addr_p,
    output reg [ADDR_W-1:0] addr_q,
    output reg [ADDR_W-1:0] tw_index
);

    integer half_size;
    integer group_size;
    integer j;
    integer group;
    integer p_int;
    integer tw_stride;

    always @* begin
        /*
         * Radix-2 DIT addressing:
         *
         *   half_size  = 2^stage
         *   group_size = 2 * half_size
         *
         * The butterfly counter is split into:
         *   j     = position inside the current butterfly group
         *   group = which butterfly group is being processed
         *
         * Then:
         *   p = group * group_size + j
         *   q = p + half_size
         *
         * Twiddle exponent:
         *   tw_index = j * (N / group_size)
         */
        half_size  = 1 << stage;
        group_size = half_size << 1;

        j          = butterfly & (half_size - 1);
        group      = butterfly >> stage;

        p_int      = group * group_size + j;
        tw_stride  = N / group_size;

        addr_p     = p_int[ADDR_W-1:0];
        addr_q     = (p_int + half_size);
        tw_index   = j * tw_stride;
    end

endmodule