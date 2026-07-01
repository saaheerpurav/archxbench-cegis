`timescale 1ns/1ps

module dct1d_8_pipeline #(
    parameter DATA_W = 12,
    parameter COEFF_W = 16,
    parameter OUT_W = 18
) (
    input clk,
    input rst,
    input [DATA_W-1:0] sample_in,
    input valid_in,
    input mode,
    input [2:0] index,
    output [OUT_W-1:0] coeff_out,
    output valid_out,
    output [2:0] index_out
);

    reg signed [DATA_W-1:0] sample_buf [0:7];
    reg                     mode_buf;
    reg                     emitting;
    reg [2:0]               emit_index;

    wire                    block_last;
    wire [2:0]              next_emit_index;
    wire                    emit_done;

    wire signed [OUT_W-1:0] transformed;
    wire signed [OUT_W-1:0] rounded_scaled;
    wire signed [OUT_W-1:0] saturated_out;

    reg signed [OUT_W-1:0]  coeff_out_r;
    reg                     valid_out_r;
    reg [2:0]               index_out_r;

    assign coeff_out = coeff_out_r;
    assign valid_out = valid_out_r;
    assign index_out = index_out_r;

    dct1d_8_block_control u_block_control (
        .valid_in(valid_in),
        .index(index),
        .emitting(emitting),
        .emit_index(emit_index),
        .block_last(block_last),
        .next_emit_index(next_emit_index),
        .emit_done(emit_done)
    );

    dct1d_8_matrix_mac #(
        .DATA_W(DATA_W),
        .COEFF_W(COEFF_W),
        .OUT_W(OUT_W)
    ) u_matrix_mac (
        .mode(mode_buf),
        .out_index(emit_index),
        .x0(sample_buf[0]),
        .x1(sample_buf[1]),
        .x2(sample_buf[2]),
        .x3(sample_buf[3]),
        .x4(sample_buf[4]),
        .x5(sample_buf[5]),
        .x6(sample_buf[6]),
        .x7(sample_buf[7]),
        .y(transformed)
    );

    dct1d_8_round_scale #(
        .IN_W(OUT_W),
        .OUT_W(OUT_W)
    ) u_round_scale (
        .din(transformed),
        .dout(rounded_scaled)
    );

    dct1d_8_saturate #(
        .IN_W(OUT_W),
        .OUT_W(OUT_W)
    ) u_saturate (
        .din(rounded_scaled),
        .dout(saturated_out)
    );

    always @(posedge clk) begin
        if (rst) begin
            sample_buf[0] <= {DATA_W{1'b0}};
            sample_buf[1] <= {DATA_W{1'b0}};
            sample_buf[2] <= {DATA_W{1'b0}};
            sample_buf[3] <= {DATA_W{1'b0}};
            sample_buf[4] <= {DATA_W{1'b0}};
            sample_buf[5] <= {DATA_W{1'b0}};
            sample_buf[6] <= {DATA_W{1'b0}};
            sample_buf[7] <= {DATA_W{1'b0}};
            mode_buf      <= 1'b0;
            emitting      <= 1'b0;
            emit_index    <= 3'd0;
            coeff_out_r   <= {OUT_W{1'b0}};
            valid_out_r   <= 1'b0;
            index_out_r   <= 3'd0;
        end else begin
            valid_out_r <= emitting;

            if (emitting) begin
                coeff_out_r <= saturated_out;
                index_out_r <= emit_index;
            end else begin
                coeff_out_r <= {OUT_W{1'b0}};
                index_out_r <= 3'd0;
            end

            if (valid_in) begin
                mode_buf <= mode;
                case (index)
                    3'd0: sample_buf[0] <= sample_in;
                    3'd1: sample_buf[1] <= sample_in;
                    3'd2: sample_buf[2] <= sample_in;
                    3'd3: sample_buf[3] <= sample_in;
                    3'd4: sample_buf[4] <= sample_in;
                    3'd5: sample_buf[5] <= sample_in;
                    3'd6: sample_buf[6] <= sample_in;
                    3'd7: sample_buf[7] <= sample_in;
                    default: sample_buf[0] <= sample_buf[0];
                endcase
            end

            if (block_last) begin
                emitting   <= 1'b1;
                emit_index <= 3'd0;
            end else if (emitting) begin
                emit_index <= next_emit_index;
                if (emit_done) begin
                    emitting <= 1'b0;
                end
            end
        end
    end

endmodule