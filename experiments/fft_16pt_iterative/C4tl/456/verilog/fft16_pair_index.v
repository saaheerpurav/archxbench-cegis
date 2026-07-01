`timescale 1ns/1ps

module fft16_pair_index (
    input  [1:0] stage,
    input  [3:0] butterfly,
    output reg [3:0] p_idx,
    output reg [3:0] q_idx,
    output reg [3:0] tw_idx
);
    always @* begin
        case (stage)
            2'd0: begin
                // m=2, half=1
                p_idx  = {butterfly[2:0], 1'b0};
                q_idx  = {butterfly[2:0], 1'b1};
                tw_idx = 4'd0;
            end

            2'd1: begin
                // m=4, half=2
                p_idx  = {butterfly[2:1], 2'b00} + {3'b000, butterfly[0]};
                q_idx  = p_idx + 4'd2;
                tw_idx = {butterfly[0], 2'b00};
            end

            2'd2: begin
                // m=8, half=4
                p_idx  = {butterfly[2], 3'b000} + {2'b00, butterfly[1:0]};
                q_idx  = p_idx + 4'd4;
                tw_idx = {butterfly[1:0], 1'b0};
            end

            default: begin
                // m=16, half=8
                p_idx  = {1'b0, butterfly[2:0]};
                q_idx  = {1'b1, butterfly[2:0]};
                tw_idx = {1'b0, butterfly[2:0]};
            end
        endcase
    end
endmodule