module ifft16_pair_index (
    input  [2:0] stage,
    input  [3:0] butterfly,
    output reg [3:0] p_addr,
    output reg [3:0] q_addr,
    output reg [3:0] tw_idx
);
    always @(*) begin
        p_addr = 4'd0;
        q_addr = 4'd0;
        tw_idx = 4'd0;

        case (stage)
            3'd0: begin
                p_addr = {butterfly[2:0], 1'b0};
                q_addr = {butterfly[2:0], 1'b1};
                tw_idx = 4'd0;
            end

            3'd1: begin
                p_addr = {butterfly[2:1], 2'b00} + {3'b000, butterfly[0]};
                q_addr = p_addr + 4'd2;
                tw_idx = {butterfly[0], 2'b00};
            end

            3'd2: begin
                p_addr = {butterfly[2], 3'b000} + {2'b00, butterfly[1:0]};
                q_addr = p_addr + 4'd4;
                tw_idx = {butterfly[1:0], 1'b0};
            end

            3'd3: begin
                p_addr = {1'b0, butterfly[2:0]};
                q_addr = p_addr + 4'd8;
                tw_idx = {1'b0, butterfly[2:0]};
            end

            default: begin
                p_addr = 4'd0;
                q_addr = 4'd0;
                tw_idx = 4'd0;
            end
        endcase
    end
endmodule