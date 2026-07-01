`timescale 1ns/1ps

module ifft16_addr_gen (
    input  [1:0] stage,
    input  [3:0] butterfly_idx,
    output [3:0] addr_p,
    output [3:0] addr_q,
    output [3:0] twiddle_idx
);
    reg [3:0] addr_p_r;
    reg [3:0] addr_q_r;
    reg [3:0] twiddle_idx_r;

    assign addr_p = addr_p_r;
    assign addr_q = addr_q_r;
    assign twiddle_idx = twiddle_idx_r;

    always @* begin
        case (stage)
            2'd0: begin
                // m=2, half=1: pairs (0,1), (2,3), ...
                addr_p_r      = {butterfly_idx[2:0], 1'b0};
                addr_q_r      = {butterfly_idx[2:0], 1'b0} + 4'd1;
                twiddle_idx_r = 4'd0;
            end

            2'd1: begin
                // m=4, half=2: twiddle step = 4
                addr_p_r      = {butterfly_idx[2:1], 2'b00} + {3'b000, butterfly_idx[0]};
                addr_q_r      = ({butterfly_idx[2:1], 2'b00} + {3'b000, butterfly_idx[0]}) + 4'd2;
                twiddle_idx_r = {1'b0, butterfly_idx[0], 2'b00};
            end

            2'd2: begin
                // m=8, half=4: twiddle step = 2
                addr_p_r      = {butterfly_idx[2], 1'b0, butterfly_idx[1:0]};
                addr_q_r      = {butterfly_idx[2], 1'b0, butterfly_idx[1:0]} + 4'd4;
                twiddle_idx_r = {1'b0, butterfly_idx[1:0], 1'b0};
            end

            default: begin
                // m=16, half=8: twiddle step = 1
                addr_p_r      = {1'b0, butterfly_idx[2:0]};
                addr_q_r      = {1'b0, butterfly_idx[2:0]} + 4'd8;
                twiddle_idx_r = {1'b0, butterfly_idx[2:0]};
            end
        endcase
    end
endmodule