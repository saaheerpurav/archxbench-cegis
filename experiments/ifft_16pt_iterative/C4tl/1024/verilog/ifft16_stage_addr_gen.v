`timescale 1ns/1ps

module ifft16_stage_addr_gen (
    input  [2:0] stage,
    input  [3:0] group_base,
    input  [3:0] j_idx,
    output [3:0] half_size,
    output [4:0] step_size,
    output [3:0] p_addr,
    output [3:0] q_addr,
    output [3:0] tw_idx
);
    assign half_size = 4'd1 << stage;
    assign step_size = 5'd2 << stage;

    assign p_addr = group_base + j_idx;
    assign q_addr = group_base + j_idx + half_size;

    assign tw_idx = j_idx << (3'd3 - stage);
endmodule