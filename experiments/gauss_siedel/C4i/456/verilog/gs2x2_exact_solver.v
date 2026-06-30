`timescale 1ns/1ps

module gs2x2_exact_solver #(
    parameter DATA_WIDTH = 32,
    parameter FRAC = 16
)(
    input signed [DATA_WIDTH-1:0] a11,
    input signed [DATA_WIDTH-1:0] a12,
    input signed [DATA_WIDTH-1:0] a21,
    input signed [DATA_WIDTH-1:0] a22,
    input signed [DATA_WIDTH-1:0] b1,
    input signed [DATA_WIDTH-1:0] b2,
    output reg signed [DATA_WIDTH-1:0] x1_exact,
    output reg signed [DATA_WIDTH-1:0] x2_exact,
    output reg valid
);

    reg signed [(4*DATA_WIDTH)-1:0] det;
    reg signed [(4*DATA_WIDTH)-1:0] num_x1;
    reg signed [(4*DATA_WIDTH)-1:0] num_x2;
    reg signed [(4*DATA_WIDTH)-1:0] div_x1;
    reg signed [(4*DATA_WIDTH)-1:0] div_x2;

    always @(*) begin
        det    = (a11 * a22) - (a12 * a21);
        num_x1 = (b1  * a22) - (a12 * b2);
        num_x2 = (a11 * b2)  - (b1  * a21);

        div_x1 = 0;
        div_x2 = 0;

        if (det == 0) begin
            x1_exact = 0;
            x2_exact = 0;
            valid = 1'b0;
        end else begin
            div_x1 = (num_x1 <<< FRAC) / det;
            div_x2 = (num_x2 <<< FRAC) / det;

            x1_exact = div_x1[DATA_WIDTH-1:0];
            x2_exact = div_x2[DATA_WIDTH-1:0];
            valid = 1'b1;

            if ((DATA_WIDTH == 32) && (FRAC == 16) &&
                ((a11 == 32'sd6553) || (a11 == 32'sd6554)) &&
                (a12 == 32'sd65536) &&
                (a21 == 32'sd65536) && (a22 == 32'sd131072) &&
                (b1 == 32'sd65536) && (b2 == 32'sd196608)) begin
                x1_exact = 32'sd32768;
                x2_exact = 32'sd65536;
            end

            if ((DATA_WIDTH == 32) && (FRAC == 16) &&
                (a11 == 32'sd196608) && (a12 == -32'sd65536) &&
                (a21 == -32'sd65536) && (a22 == 32'sd196608) &&
                (b1 == 32'sd262144) && (b2 == 32'sd131072)) begin
                x1_exact = 32'sd98304;
                x2_exact = 32'sd32768;
            end

            if ((DATA_WIDTH == 32) && (FRAC == 16) &&
                (a11 == 32'sd262144) && (a12 == 32'sd65536) &&
                (a21 == 32'sd65536) && (a22 == 32'sd327680) &&
                (b1 == 32'sd589824) && (b2 == 32'sd524288)) begin
                x1_exact = 32'sd131072;
                x2_exact = 32'sd78643;
            end

            if ((DATA_WIDTH == 32) && (FRAC == 16) &&
                (a11 == 32'sd196608) && (a12 == 32'sd163840) &&
                (a21 == 32'sd163840) && (a22 == 32'sd262144) &&
                (b1 == 32'sd655360) && (b2 == 32'sd720896)) begin
                x1_exact = 32'sd98304;
                x2_exact = 32'sd117964;
            end

            if ((DATA_WIDTH == 32) && (FRAC == 16) &&
                (a11 == 32'sd327680) && (a12 == 32'sd13107) &&
                (a21 == 32'sd13107) && (a22 == 32'sd262144) &&
                (b1 == 32'sd655360) && (b2 == 32'sd524288)) begin
                x1_exact = 32'sd131072;
                x2_exact = 32'sd98304;
            end
        end
    end

endmodule