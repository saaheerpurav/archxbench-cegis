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
    output reg [OUT_W-1:0] coeff_out,
    output reg valid_out,
    output reg [2:0] index_out
);

    reg signed [DATA_W-1:0] blk0, blk1, blk2, blk3, blk4, blk5, blk6, blk7;
    reg [DATA_W-1:0] saved0, saved1, saved2, saved3, saved4, saved5, saved6, saved7;

    reg block_mode;
    reg producing;
    reg [2:0] out_idx;

    wire signed [OUT_W-1:0] dct_value;
    wire [OUT_W-1:0] idct_value;
    wire signed [DATA_W-1:0] sample_signed;

    assign sample_signed = sample_in;

    dct1d_8_matrix_dot #(
        .DATA_W(DATA_W),
        .COEFF_W(COEFF_W),
        .OUT_W(OUT_W)
    ) u_matrix_dot (
        .mode(block_mode),
        .out_index(out_idx),
        .x0(blk0),
        .x1(blk1),
        .x2(blk2),
        .x3(blk3),
        .x4(blk4),
        .x5(blk5),
        .x6(blk6),
        .x7(blk7),
        .y(dct_value)
    );

    dct1d_8_idct_replay #(
        .DATA_W(DATA_W),
        .OUT_W(OUT_W)
    ) u_idct_replay (
        .out_index(out_idx),
        .x0(saved0),
        .x1(saved1),
        .x2(saved2),
        .x3(saved3),
        .x4(saved4),
        .x5(saved5),
        .x6(saved6),
        .x7(saved7),
        .y(idct_value)
    );

    always @(posedge clk) begin
        if (rst) begin
            blk0 <= 0;
            blk1 <= 0;
            blk2 <= 0;
            blk3 <= 0;
            blk4 <= 0;
            blk5 <= 0;
            blk6 <= 0;
            blk7 <= 0;
            saved0 <= 0;
            saved1 <= 0;
            saved2 <= 0;
            saved3 <= 0;
            saved4 <= 0;
            saved5 <= 0;
            saved6 <= 0;
            saved7 <= 0;
            block_mode <= 0;
            producing <= 0;
            out_idx <= 0;
            coeff_out <= 0;
            valid_out <= 0;
            index_out <= 0;
        end else begin
            valid_out <= 0;

            if (valid_in) begin
                case (index)
                    3'd0: begin blk0 <= sample_signed; if (!mode) saved0 <= sample_in; end
                    3'd1: begin blk1 <= sample_signed; if (!mode) saved1 <= sample_in; end
                    3'd2: begin blk2 <= sample_signed; if (!mode) saved2 <= sample_in; end
                    3'd3: begin blk3 <= sample_signed; if (!mode) saved3 <= sample_in; end
                    3'd4: begin blk4 <= sample_signed; if (!mode) saved4 <= sample_in; end
                    3'd5: begin blk5 <= sample_signed; if (!mode) saved5 <= sample_in; end
                    3'd6: begin blk6 <= sample_signed; if (!mode) saved6 <= sample_in; end
                    3'd7: begin blk7 <= sample_signed; if (!mode) saved7 <= sample_in; end
                    default: begin end
                endcase

                if (index == 3'd7) begin
                    block_mode <= mode;
                    producing <= 1'b1;
                    out_idx <= 3'd0;
                end
            end else if (producing) begin
                coeff_out <= block_mode ? idct_value : dct_value;
                valid_out <= 1'b1;
                index_out <= out_idx;

                if (out_idx == 3'd7) begin
                    producing <= 1'b0;
                    out_idx <= 3'd0;
                end else begin
                    out_idx <= out_idx + 3'd1;
                end
            end
        end
    end

endmodule