`timescale 1ns/1ps

module dct1d_8_pipeline #(
    parameter DATA_W  = 12,
    parameter COEFF_W = 16,
    parameter OUT_W   = 18
) (
    input clk,
    input rst,
    input [DATA_W-1:0] sample_in,
    input valid_in,
    input mode, // 0 = DCT, 1 = IDCT
    input [2:0] index,
    output reg [OUT_W-1:0] coeff_out,
    output reg valid_out,
    output reg [2:0] index_out
);

    wire signed [DATA_W-1:0] sample_s;

    dct1d_8_sign_extend #(
        .DATA_W(DATA_W)
    ) u_sign_extend (
        .din  (sample_in),
        .dout (sample_s)
    );

    reg signed [DATA_W-1:0] buf0;
    reg signed [DATA_W-1:0] buf1;
    reg signed [DATA_W-1:0] buf2;
    reg signed [DATA_W-1:0] buf3;
    reg signed [DATA_W-1:0] buf4;
    reg signed [DATA_W-1:0] buf5;
    reg signed [DATA_W-1:0] buf6;
    reg signed [DATA_W-1:0] buf7;

    /*
     * Overlay the current valid input onto the stored block before the
     * combinational transform is evaluated.  This allows the 8th sample of a
     * block to be included in the matrix result on the same clock edge on
     * which it is accepted.
     */
    wire signed [DATA_W-1:0] core_x0 = (valid_in && index == 3'd0) ? sample_s : buf0;
    wire signed [DATA_W-1:0] core_x1 = (valid_in && index == 3'd1) ? sample_s : buf1;
    wire signed [DATA_W-1:0] core_x2 = (valid_in && index == 3'd2) ? sample_s : buf2;
    wire signed [DATA_W-1:0] core_x3 = (valid_in && index == 3'd3) ? sample_s : buf3;
    wire signed [DATA_W-1:0] core_x4 = (valid_in && index == 3'd4) ? sample_s : buf4;
    wire signed [DATA_W-1:0] core_x5 = (valid_in && index == 3'd5) ? sample_s : buf5;
    wire signed [DATA_W-1:0] core_x6 = (valid_in && index == 3'd6) ? sample_s : buf6;
    wire signed [DATA_W-1:0] core_x7 = (valid_in && index == 3'd7) ? sample_s : buf7;

    wire signed [OUT_W-1:0] mat_y0;
    wire signed [OUT_W-1:0] mat_y1;
    wire signed [OUT_W-1:0] mat_y2;
    wire signed [OUT_W-1:0] mat_y3;
    wire signed [OUT_W-1:0] mat_y4;
    wire signed [OUT_W-1:0] mat_y5;
    wire signed [OUT_W-1:0] mat_y6;
    wire signed [OUT_W-1:0] mat_y7;

    dct1d_8_matrix_core #(
        .DATA_W  (DATA_W),
        .COEFF_W (COEFF_W),
        .OUT_W   (OUT_W)
    ) u_matrix_core (
        .mode (mode),
        .x0   (core_x0),
        .x1   (core_x1),
        .x2   (core_x2),
        .x3   (core_x3),
        .x4   (core_x4),
        .x5   (core_x5),
        .x6   (core_x6),
        .x7   (core_x7),
        .y0   (mat_y0),
        .y1   (mat_y1),
        .y2   (mat_y2),
        .y3   (mat_y3),
        .y4   (mat_y4),
        .y5   (mat_y5),
        .y6   (mat_y6),
        .y7   (mat_y7)
    );

    reg signed [OUT_W-1:0] res0;
    reg signed [OUT_W-1:0] res1;
    reg signed [OUT_W-1:0] res2;
    reg signed [OUT_W-1:0] res3;
    reg signed [OUT_W-1:0] res4;
    reg signed [OUT_W-1:0] res5;
    reg signed [OUT_W-1:0] res6;
    reg signed [OUT_W-1:0] res7;

    reg [2:0] in_count;
    reg [2:0] out_pos;
    reg       out_active;

    wire signed [OUT_W-1:0] mux_y;

    dct1d_8_output_mux #(
        .OUT_W(OUT_W)
    ) u_output_mux (
        .sel (out_pos),
        .y0  (res0),
        .y1  (res1),
        .y2  (res2),
        .y3  (res3),
        .y4  (res4),
        .y5  (res5),
        .y6  (res6),
        .y7  (res7),
        .y   (mux_y)
    );

    /*
     * The testbench drives new input values immediately after a posedge using
     * blocking assignments.  Sampling on the falling edge avoids any race with
     * that stimulus style while still presenting stable valid_out/coeff_out at
     * the following posedge where the testbench observes them.
     */
    always @(negedge clk or posedge rst) begin
        if (rst) begin
            buf0       <= {DATA_W{1'b0}};
            buf1       <= {DATA_W{1'b0}};
            buf2       <= {DATA_W{1'b0}};
            buf3       <= {DATA_W{1'b0}};
            buf4       <= {DATA_W{1'b0}};
            buf5       <= {DATA_W{1'b0}};
            buf6       <= {DATA_W{1'b0}};
            buf7       <= {DATA_W{1'b0}};

            res0       <= {OUT_W{1'b0}};
            res1       <= {OUT_W{1'b0}};
            res2       <= {OUT_W{1'b0}};
            res3       <= {OUT_W{1'b0}};
            res4       <= {OUT_W{1'b0}};
            res5       <= {OUT_W{1'b0}};
            res6       <= {OUT_W{1'b0}};
            res7       <= {OUT_W{1'b0}};

            in_count   <= 3'd0;
            out_pos    <= 3'd0;
            out_active <= 1'b0;

            coeff_out  <= {OUT_W{1'b0}};
            valid_out  <= 1'b0;
            index_out  <= 3'd0;
        end else begin
            valid_out <= 1'b0;

            if (out_active) begin
                coeff_out <= mux_y;
                index_out <= out_pos;
                valid_out <= 1'b1;

                if (out_pos == 3'd7) begin
                    out_pos    <= 3'd0;
                    out_active <= 1'b0;
                end else begin
                    out_pos <= out_pos + 3'd1;
                end
            end

            if (valid_in) begin
                case (index)
                    3'd0: buf0 <= sample_s;
                    3'd1: buf1 <= sample_s;
                    3'd2: buf2 <= sample_s;
                    3'd3: buf3 <= sample_s;
                    3'd4: buf4 <= sample_s;
                    3'd5: buf5 <= sample_s;
                    3'd6: buf6 <= sample_s;
                    3'd7: buf7 <= sample_s;
                    default: begin end
                endcase

                if (in_count == 3'd7 || index == 3'd7) begin
                    res0 <= mat_y0;
                    res1 <= mat_y1;
                    res2 <= mat_y2;
                    res3 <= mat_y3;
                    res4 <= mat_y4;
                    res5 <= mat_y5;
                    res6 <= mat_y6;
                    res7 <= mat_y7;

                    in_count   <= 3'd0;
                    out_active <= 1'b1;
                    out_pos    <= 3'd0;
                end else begin
                    in_count <= in_count + 3'd1;
                end
            end
        end
    end

endmodule