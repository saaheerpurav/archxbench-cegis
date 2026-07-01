`timescale 1ns/1ps

module fft16_address_gen (
    input  [1:0] stage,
    input  [2:0] butterfly_index,
    output reg [3:0] p_idx,
    output reg [3:0] q_idx,
    output reg [3:0] tw_idx
);
    always @* begin
        case (stage)
            2'd0: begin
                // span=2, half=1: (0,1), (2,3), ...
                p_idx  = {butterfly_index, 1'b0};
                q_idx  = {butterfly_index, 1'b0} + 4'd1;
                tw_idx = 4'd0;
            end

            2'd1: begin
                // span=4, half=2: twiddles 0,4 within each group
                p_idx  = {butterfly_index[2:1], 2'b00} + {3'b000, butterfly_index[0]};
                q_idx  = ({butterfly_index[2:1], 2'b00} + {3'b000, butterfly_index[0]}) + 4'd2;
                tw_idx = {butterfly_index[0], 2'b00};
            end

            2'd2: begin
                // span=8, half=4: twiddles 0,2,4,6 within each group
                p_idx  = {butterfly_index[2], 3'b000} + {2'b00, butterfly_index[1:0]};
                q_idx  = ({butterfly_index[2], 3'b000} + {2'b00, butterfly_index[1:0]}) + 4'd4;
                tw_idx = {butterfly_index[1:0], 1'b0};
            end

            default: begin
                // span=16, half=8: twiddles 0..7
                p_idx  = {1'b0, butterfly_index};
                q_idx  = {1'b0, butterfly_index} + 4'd8;
                tw_idx = {1'b0, butterfly_index};
            end
        endcase
    end
endmodule