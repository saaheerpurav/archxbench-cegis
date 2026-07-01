`timescale 1ns/1ps

module fft16_addr_gen #(
    parameter N = 16
) (
    input  [3:0] stage,
    input  [3:0] bf_idx,
    output reg [3:0] addr_p,
    output reg [3:0] addr_q,
    output reg [3:0] tw_idx
);

    reg [3:0] half_size;
    reg [4:0] span_size;
    reg [3:0] group_idx;
    reg [3:0] pair_idx;

    always @* begin
        addr_p = 4'd0;
        addr_q = 4'd0;
        tw_idx = 4'd0;

        case (stage)
            4'd0: begin
                half_size = 4'd1;
                span_size = 5'd2;
                group_idx = bf_idx;
                pair_idx  = 4'd0;

                addr_p = {bf_idx[2:0], 1'b0};
                addr_q = addr_p + half_size;
                tw_idx = 4'd0;
            end

            4'd1: begin
                half_size = 4'd2;
                span_size = 5'd4;
                group_idx = bf_idx >> 1;
                pair_idx  = bf_idx & 4'd1;

                addr_p = (group_idx << 2) + pair_idx;
                addr_q = addr_p + half_size;
                tw_idx = pair_idx << 2;
            end

            4'd2: begin
                half_size = 4'd4;
                span_size = 5'd8;
                group_idx = bf_idx >> 2;
                pair_idx  = bf_idx & 4'd3;

                addr_p = (group_idx << 3) + pair_idx;
                addr_q = addr_p + half_size;
                tw_idx = pair_idx << 1;
            end

            4'd3: begin
                half_size = 4'd8;
                span_size = 5'd16;
                group_idx = 4'd0;
                pair_idx  = bf_idx & 4'd7;

                addr_p = pair_idx;
                addr_q = addr_p + half_size;
                tw_idx = pair_idx;
            end

            default: begin
                half_size = 4'd0;
                span_size = 5'd0;
                group_idx = 4'd0;
                pair_idx  = 4'd0;

                addr_p = 4'd0;
                addr_q = 4'd0;
                tw_idx = 4'd0;
            end
        endcase
    end

endmodule