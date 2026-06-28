`timescale 1ns/1ps

module ifft16_stage_addr_gen #(
    parameter N = 16,
    parameter ADDR_W = 4
) (
    input  [ADDR_W-1:0] stage,
    input  [ADDR_W-1:0] block_idx,
    input  [ADDR_W-1:0] j_idx,

    output [ADDR_W-1:0] p_idx,
    output [ADDR_W-1:0] q_idx,
    output [ADDR_W-1:0] tw_idx,

    output [ADDR_W:0]   half_size,
    output [ADDR_W:0]   m_size,

    output              last_j,
    output              last_block,
    output              last_stage
);

    function integer clog2_int;
        input integer value;
        integer v;
        begin
            v = value - 1;
            for (clog2_int = 0; v > 0; clog2_int = clog2_int + 1) begin
                v = v >> 1;
            end
        end
    endfunction

    localparam integer LOGN = clog2_int(N);

    localparam [ADDR_W:0] N_EXT   = N;
    localparam [ADDR_W:0] ONE_EXT = {{ADDR_W{1'b0}}, 1'b1};

    wire [ADDR_W:0] stage_ext;
    wire [ADDR_W:0] block_ext;
    wire [ADDR_W:0] j_ext;
    wire [ADDR_W:0] stride_ext;

    wire [ADDR_W:0] p_ext;
    wire [ADDR_W:0] q_ext;

    wire [(2*(ADDR_W+1))-1:0] tw_product_ext;

    assign stage_ext = {1'b0, stage};
    assign block_ext = {1'b0, block_idx};
    assign j_ext     = {1'b0, j_idx};

    assign half_size = ONE_EXT << stage;
    assign m_size    = half_size << 1;

    assign stride_ext = N_EXT >> (stage_ext + ONE_EXT);

    assign p_ext = block_ext + j_ext;
    assign q_ext = p_ext + half_size;

    assign p_idx = p_ext[ADDR_W-1:0];
    assign q_idx = q_ext[ADDR_W-1:0];

    assign tw_product_ext = j_ext * stride_ext;
    assign tw_idx = tw_product_ext[ADDR_W-1:0];

    assign last_j     = (j_ext == (half_size - ONE_EXT));
    assign last_block = (block_ext >= (N_EXT - m_size));
    assign last_stage = (stage_ext == (LOGN - 1));

endmodule