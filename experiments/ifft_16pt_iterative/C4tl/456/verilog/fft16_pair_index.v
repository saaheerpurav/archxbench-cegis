`timescale 1ns/1ps

module fft16_pair_index (
    input  [1:0] stage,
    input  [3:0] butterfly_idx,
    output [3:0] p_idx,
    output [3:0] q_idx,
    output [3:0] tw_idx
);
    wire [3:0] j;
    wire [3:0] group;
    wire [3:0] half_size;
    wire [3:0] block_size;

    assign half_size  = 4'd1 << stage;
    assign block_size = 4'd2 << stage;

    assign j = butterfly_idx & (half_size - 4'd1);

    assign group =
        (stage == 2'd0) ? butterfly_idx :
        (stage == 2'd1) ? {1'b0, butterfly_idx[3:1]} :
        (stage == 2'd2) ? {2'b00, butterfly_idx[3:2]} :
                           {3'b000, butterfly_idx[3]};

    assign p_idx =
        (stage == 2'd0) ? {butterfly_idx[2:0], 1'b0} :
        (stage == 2'd1) ? ({butterfly_idx[2:1], 2'b00} + {3'b000, butterfly_idx[0]}) :
        (stage == 2'd2) ? ({butterfly_idx[2], 3'b000} + {2'b00, butterfly_idx[1:0]}) :
                           butterfly_idx[2:0];

    assign q_idx = p_idx + half_size;

    assign tw_idx =
        (stage == 2'd0) ? 4'd0 :
        (stage == 2'd1) ? ({3'b000, butterfly_idx[0]} << 2) :
        (stage == 2'd2) ? ({2'b00, butterfly_idx[1:0]} << 1) :
                           {1'b0, butterfly_idx[2:0]};

endmodule