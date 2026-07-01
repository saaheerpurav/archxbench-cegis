`timescale 1ns/1ps

module fft16_addr_gen #(
    parameter N = 16
) (
    input [1:0] stage,
    input [3:0] butterfly,
    output reg [3:0] p_addr,
    output reg [3:0] q_addr,
    output reg [3:0] tw_addr
);
    always @(*) begin
        case (stage)
            2'd0: begin
                p_addr  = {butterfly[2:0], 1'b0};
                q_addr  = {butterfly[2:0], 1'b1};
                tw_addr = 4'd0;
            end

            2'd1: begin
                p_addr  = {butterfly[2:1], 2'b00} + {3'b000, butterfly[0]};
                q_addr  = p_addr + 4'd2;
                tw_addr = {butterfly[0], 2'b00};
            end

            2'd2: begin
                p_addr  = {butterfly[2], 3'b000} + {2'b00, butterfly[1:0]};
                q_addr  = p_addr + 4'd4;
                tw_addr = {butterfly[1:0], 1'b0};
            end

            default: begin
                p_addr  = {1'b0, butterfly[2:0]};
                q_addr  = p_addr + 4'd8;
                tw_addr = butterfly;
            end
        endcase
    end
endmodule