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
    input mode, // 0 = DCT, 1 = IDCT
    input [2:0] index,
    output reg [OUT_W-1:0] coeff_out,
    output reg valid_out,
    output reg [2:0] index_out
);

    localparam PROD_W = DATA_W + COEFF_W;
    localparam ACC_W  = PROD_W + 3;
    localparam FRAC_W = 14;

    reg signed [DATA_W-1:0] cap0, cap1, cap2, cap3, cap4, cap5, cap6, cap7;
    reg signed [DATA_W-1:0] proc0, proc1, proc2, proc3, proc4, proc5, proc6, proc7;

    reg proc_mode;
    reg out_active;
    reg [2:0] out_idx;

    wire signed [DATA_W-1:0] sample_s;
    assign sample_s = sample_in;

    wire block_done;
    assign block_done = valid_in && (index == 3'd7);

    wire signed [DATA_W-1:0] next0;
    wire signed [DATA_W-1:0] next1;
    wire signed [DATA_W-1:0] next2;
    wire signed [DATA_W-1:0] next3;
    wire signed [DATA_W-1:0] next4;
    wire signed [DATA_W-1:0] next5;
    wire signed [DATA_W-1:0] next6;
    wire signed [DATA_W-1:0] next7;

    assign next0 = (valid_in && index == 3'd0) ? sample_s : cap0;
    assign next1 = (valid_in && index == 3'd1) ? sample_s : cap1;
    assign next2 = (valid_in && index == 3'd2) ? sample_s : cap2;
    assign next3 = (valid_in && index == 3'd3) ? sample_s : cap3;
    assign next4 = (valid_in && index == 3'd4) ? sample_s : cap4;
    assign next5 = (valid_in && index == 3'd5) ? sample_s : cap5;
    assign next6 = (valid_in && index == 3'd6) ? sample_s : cap6;
    assign next7 = (valid_in && index == 3'd7) ? sample_s : cap7;

    wire signed [COEFF_W-1:0] c0, c1, c2, c3, c4, c5, c6, c7;

    dct8_coeff_rom #(.COEFF_W(COEFF_W)) u_coeff0 (
        .mode(proc_mode),
        .row_index(out_idx),
        .col_index(3'd0),
        .coeff(c0)
    );

    dct8_coeff_rom #(.COEFF_W(COEFF_W)) u_coeff1 (
        .mode(proc_mode),
        .row_index(out_idx),
        .col_index(3'd1),
        .coeff(c1)
    );

    dct8_coeff_rom #(.COEFF_W(COEFF_W)) u_coeff2 (
        .mode(proc_mode),
        .row_index(out_idx),
        .col_index(3'd2),
        .coeff(c2)
    );

    dct8_coeff_rom #(.COEFF_W(COEFF_W)) u_coeff3 (
        .mode(proc_mode),
        .row_index(out_idx),
        .col_index(3'd3),
        .coeff(c3)
    );

    dct8_coeff_rom #(.COEFF_W(COEFF_W)) u_coeff4 (
        .mode(proc_mode),
        .row_index(out_idx),
        .col_index(3'd4),
        .coeff(c4)
    );

    dct8_coeff_rom #(.COEFF_W(COEFF_W)) u_coeff5 (
        .mode(proc_mode),
        .row_index(out_idx),
        .col_index(3'd5),
        .coeff(c5)
    );

    dct8_coeff_rom #(.COEFF_W(COEFF_W)) u_coeff6 (
        .mode(proc_mode),
        .row_index(out_idx),
        .col_index(3'd6),
        .coeff(c6)
    );

    dct8_coeff_rom #(.COEFF_W(COEFF_W)) u_coeff7 (
        .mode(proc_mode),
        .row_index(out_idx),
        .col_index(3'd7),
        .coeff(c7)
    );

    wire signed [PROD_W-1:0] p0, p1, p2, p3, p4, p5, p6, p7;

    dct8_product #(.DATA_W(DATA_W), .COEFF_W(COEFF_W), .PROD_W(PROD_W)) u_prod0 (
        .sample(proc0),
        .coeff(c0),
        .product(p0)
    );

    dct8_product #(.DATA_W(DATA_W), .COEFF_W(COEFF_W), .PROD_W(PROD_W)) u_prod1 (
        .sample(proc1),
        .coeff(c1),
        .product(p1)
    );

    dct8_product #(.DATA_W(DATA_W), .COEFF_W(COEFF_W), .PROD_W(PROD_W)) u_prod2 (
        .sample(proc2),
        .coeff(c2),
        .product(p2)
    );

    dct8_product #(.DATA_W(DATA_W), .COEFF_W(COEFF_W), .PROD_W(PROD_W)) u_prod3 (
        .sample(proc3),
        .coeff(c3),
        .product(p3)
    );

    dct8_product #(.DATA_W(DATA_W), .COEFF_W(COEFF_W), .PROD_W(PROD_W)) u_prod4 (
        .sample(proc4),
        .coeff(c4),
        .product(p4)
    );

    dct8_product #(.DATA_W(DATA_W), .COEFF_W(COEFF_W), .PROD_W(PROD_W)) u_prod5 (
        .sample(proc5),
        .coeff(c5),
        .product(p5)
    );

    dct8_product #(.DATA_W(DATA_W), .COEFF_W(COEFF_W), .PROD_W(PROD_W)) u_prod6 (
        .sample(proc6),
        .coeff(c6),
        .product(p6)
    );

    dct8_product #(.DATA_W(DATA_W), .COEFF_W(COEFF_W), .PROD_W(PROD_W)) u_prod7 (
        .sample(proc7),
        .coeff(c7),
        .product(p7)
    );

    wire signed [ACC_W-1:0] acc_sum;

    dct8_sum8 #(.IN_W(PROD_W), .SUM_W(ACC_W)) u_sum8 (
        .in0(p0),
        .in1(p1),
        .in2(p2),
        .in3(p3),
        .in4(p4),
        .in5(p5),
        .in6(p6),
        .in7(p7),
        .sum(acc_sum)
    );

    wire signed [OUT_W-1:0] scaled_sat;

    dct8_quantize_saturate #(
        .IN_W(ACC_W),
        .OUT_W(OUT_W),
        .FRAC_W(FRAC_W)
    ) u_quant (
        .value_in(acc_sum),
        .value_out(scaled_sat)
    );

    always @(negedge clk or posedge rst) begin
        if (rst) begin
            cap0 <= {DATA_W{1'b0}};
            cap1 <= {DATA_W{1'b0}};
            cap2 <= {DATA_W{1'b0}};
            cap3 <= {DATA_W{1'b0}};
            cap4 <= {DATA_W{1'b0}};
            cap5 <= {DATA_W{1'b0}};
            cap6 <= {DATA_W{1'b0}};
            cap7 <= {DATA_W{1'b0}};

            proc0 <= {DATA_W{1'b0}};
            proc1 <= {DATA_W{1'b0}};
            proc2 <= {DATA_W{1'b0}};
            proc3 <= {DATA_W{1'b0}};
            proc4 <= {DATA_W{1'b0}};
            proc5 <= {DATA_W{1'b0}};
            proc6 <= {DATA_W{1'b0}};
            proc7 <= {DATA_W{1'b0}};

            proc_mode  <= 1'b0;
            out_active <= 1'b0;
            out_idx    <= 3'd0;

            coeff_out <= {OUT_W{1'b0}};
            valid_out <= 1'b0;
            index_out <= 3'd0;
        end else begin
            if (out_active) begin
                coeff_out <= scaled_sat;
                valid_out <= 1'b1;
                index_out <= out_idx;
            end else begin
                coeff_out <= {OUT_W{1'b0}};
                valid_out <= 1'b0;
                index_out <= 3'd0;
            end

            if (valid_in) begin
                case (index)
                    3'd0: cap0 <= sample_s;
                    3'd1: cap1 <= sample_s;
                    3'd2: cap2 <= sample_s;
                    3'd3: cap3 <= sample_s;
                    3'd4: cap4 <= sample_s;
                    3'd5: cap5 <= sample_s;
                    3'd6: cap6 <= sample_s;
                    3'd7: cap7 <= sample_s;
                    default: begin
                        cap0 <= cap0;
                    end
                endcase
            end

            if (out_active) begin
                if (out_idx == 3'd7) begin
                    if (block_done) begin
                        proc0 <= next0;
                        proc1 <= next1;
                        proc2 <= next2;
                        proc3 <= next3;
                        proc4 <= next4;
                        proc5 <= next5;
                        proc6 <= next6;
                        proc7 <= next7;
                        proc_mode <= mode;
                        out_idx <= 3'd0;
                        out_active <= 1'b1;
                    end else begin
                        out_idx <= 3'd0;
                        out_active <= 1'b0;
                    end
                end else begin
                    out_idx <= out_idx + 3'd1;
                    out_active <= 1'b1;
                end
            end else begin
                if (block_done) begin
                    proc0 <= next0;
                    proc1 <= next1;
                    proc2 <= next2;
                    proc3 <= next3;
                    proc4 <= next4;
                    proc5 <= next5;
                    proc6 <= next6;
                    proc7 <= next7;
                    proc_mode <= mode;
                    out_idx <= 3'd0;
                    out_active <= 1'b1;
                end else begin
                    out_idx <= 3'd0;
                    out_active <= 1'b0;
                end
            end
        end
    end

endmodule