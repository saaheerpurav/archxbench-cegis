`timescale 1ns/1ps

module fp_adder_pipeline #(
    parameter LATENCY = 5
) (
    input clk,
    input rst,
    input [31:0] a,
    input [31:0] b,
    input add_sub,
    input valid_in,
    output [31:0] result,
    output valid_out
);

    /*
     * Fixed 5-stage IEEE-754 single-precision add/sub pipeline:
     *   Stage 1: unpack/classify/special-case detection
     *   Stage 2: exponent alignment with sticky generation
     *   Stage 3: add/subtract aligned significands
     *   Stage 4: normalize
     *   Stage 5: round-to-nearest-even and pack
     *
     * If LATENCY > 5, extra output delay stages are inserted.
     * If LATENCY <= 5, the implemented arithmetic pipeline remains 5 stages.
     */

    /* ---------------- Stage 1 combinational ---------------- */

    wire        c1_a_sign;
    wire        c1_b_sign;
    wire [8:0]  c1_a_exp;
    wire [8:0]  c1_b_exp;
    wire [23:0] c1_a_sig;
    wire [23:0] c1_b_sig;
    wire        c1_special;
    wire [31:0] c1_special_result;

    fp_add_unpack u_unpack (
        .a(a),
        .b(b),
        .add_sub(add_sub),
        .a_sign(c1_a_sign),
        .b_sign(c1_b_sign),
        .a_exp(c1_a_exp),
        .b_exp(c1_b_exp),
        .a_sig(c1_a_sig),
        .b_sig(c1_b_sig),
        .special(c1_special),
        .special_result(c1_special_result)
    );

    /* ---------------- Stage 1 registers ---------------- */

    reg        s1_a_sign;
    reg        s1_b_sign;
    reg [8:0]  s1_a_exp;
    reg [8:0]  s1_b_exp;
    reg [23:0] s1_a_sig;
    reg [23:0] s1_b_sig;
    reg        s1_special;
    reg [31:0] s1_special_result;
    reg        v1;

    /* ---------------- Stage 2 combinational ---------------- */

    wire        c2_a_sign;
    wire        c2_b_sign;
    wire [8:0]  c2_exp;
    wire [26:0] c2_a_aligned;
    wire [26:0] c2_b_aligned;
    wire        c2_special;
    wire [31:0] c2_special_result;

    fp_add_align u_align (
        .special_in(s1_special),
        .special_result_in(s1_special_result),
        .a_sign_in(s1_a_sign),
        .b_sign_in(s1_b_sign),
        .a_exp_in(s1_a_exp),
        .b_exp_in(s1_b_exp),
        .a_sig_in(s1_a_sig),
        .b_sig_in(s1_b_sig),
        .special_out(c2_special),
        .special_result_out(c2_special_result),
        .a_sign_out(c2_a_sign),
        .b_sign_out(c2_b_sign),
        .exp_out(c2_exp),
        .a_aligned(c2_a_aligned),
        .b_aligned(c2_b_aligned)
    );

    /* ---------------- Stage 2 registers ---------------- */

    reg        s2_a_sign;
    reg        s2_b_sign;
    reg [8:0]  s2_exp;
    reg [26:0] s2_a_aligned;
    reg [26:0] s2_b_aligned;
    reg        s2_special;
    reg [31:0] s2_special_result;
    reg        v2;

    /* ---------------- Stage 3 combinational ---------------- */

    wire        c3_special;
    wire [31:0] c3_special_result;
    wire        c3_sign;
    wire [8:0]  c3_exp;
    wire [27:0] c3_raw_sum;
    wire        c3_zero;

    fp_add_core u_core (
        .special_in(s2_special),
        .special_result_in(s2_special_result),
        .a_sign(s2_a_sign),
        .b_sign(s2_b_sign),
        .exp_in(s2_exp),
        .a_aligned(s2_a_aligned),
        .b_aligned(s2_b_aligned),
        .special_out(c3_special),
        .special_result_out(c3_special_result),
        .result_sign(c3_sign),
        .exp_out(c3_exp),
        .raw_sum(c3_raw_sum),
        .zero(c3_zero)
    );

    /* ---------------- Stage 3 registers ---------------- */

    reg        s3_special;
    reg [31:0] s3_special_result;
    reg        s3_sign;
    reg [8:0]  s3_exp;
    reg [27:0] s3_raw_sum;
    reg        s3_zero;
    reg        v3;

    /* ---------------- Stage 4 combinational ---------------- */

    wire        c4_special;
    wire [31:0] c4_special_result;
    wire        c4_sign;
    wire [8:0]  c4_exp;
    wire [26:0] c4_sig;
    wire        c4_zero;

    fp_add_normalize u_normalize (
        .special_in(s3_special),
        .special_result_in(s3_special_result),
        .sign_in(s3_sign),
        .exp_in(s3_exp),
        .raw_sum(s3_raw_sum),
        .zero_in(s3_zero),
        .special_out(c4_special),
        .special_result_out(c4_special_result),
        .sign_out(c4_sign),
        .exp_out(c4_exp),
        .sig_out(c4_sig),
        .zero_out(c4_zero)
    );

    /* ---------------- Stage 4 registers ---------------- */

    reg        s4_special;
    reg [31:0] s4_special_result;
    reg        s4_sign;
    reg [8:0]  s4_exp;
    reg [26:0] s4_sig;
    reg        s4_zero;
    reg        v4;

    /* ---------------- Stage 5 combinational ---------------- */

    wire [31:0] c5_result;

    fp_add_round_pack u_round_pack (
        .special_in(s4_special),
        .special_result_in(s4_special_result),
        .sign_in(s4_sign),
        .exp_in(s4_exp),
        .sig_in(s4_sig),
        .zero_in(s4_zero),
        .result(c5_result)
    );

    /* ---------------- Stage 5 register ---------------- */

    reg [31:0] result5_reg;
    reg        v5;

    always @(posedge clk) begin
        if (rst) begin
            s1_a_sign          <= 1'b0;
            s1_b_sign          <= 1'b0;
            s1_a_exp           <= 9'd0;
            s1_b_exp           <= 9'd0;
            s1_a_sig           <= 24'd0;
            s1_b_sig           <= 24'd0;
            s1_special         <= 1'b0;
            s1_special_result  <= 32'd0;
            v1                 <= 1'b0;

            s2_a_sign          <= 1'b0;
            s2_b_sign          <= 1'b0;
            s2_exp             <= 9'd0;
            s2_a_aligned       <= 27'd0;
            s2_b_aligned       <= 27'd0;
            s2_special         <= 1'b0;
            s2_special_result  <= 32'd0;
            v2                 <= 1'b0;

            s3_special         <= 1'b0;
            s3_special_result  <= 32'd0;
            s3_sign            <= 1'b0;
            s3_exp             <= 9'd0;
            s3_raw_sum         <= 28'd0;
            s3_zero            <= 1'b1;
            v3                 <= 1'b0;

            s4_special         <= 1'b0;
            s4_special_result  <= 32'd0;
            s4_sign            <= 1'b0;
            s4_exp             <= 9'd0;
            s4_sig             <= 27'd0;
            s4_zero            <= 1'b1;
            v4                 <= 1'b0;

            result5_reg        <= 32'd0;
            v5                 <= 1'b0;
        end else begin
            s1_a_sign          <= c1_a_sign;
            s1_b_sign          <= c1_b_sign;
            s1_a_exp           <= c1_a_exp;
            s1_b_exp           <= c1_b_exp;
            s1_a_sig           <= c1_a_sig;
            s1_b_sig           <= c1_b_sig;
            s1_special         <= c1_special;
            s1_special_result  <= c1_special_result;
            v1                 <= valid_in;

            s2_a_sign          <= c2_a_sign;
            s2_b_sign          <= c2_b_sign;
            s2_exp             <= c2_exp;
            s2_a_aligned       <= c2_a_aligned;
            s2_b_aligned       <= c2_b_aligned;
            s2_special         <= c2_special;
            s2_special_result  <= c2_special_result;
            v2                 <= v1;

            s3_special         <= c3_special;
            s3_special_result  <= c3_special_result;
            s3_sign            <= c3_sign;
            s3_exp             <= c3_exp;
            s3_raw_sum         <= c3_raw_sum;
            s3_zero            <= c3_zero;
            v3                 <= v2;

            s4_special         <= c4_special;
            s4_special_result  <= c4_special_result;
            s4_sign            <= c4_sign;
            s4_exp             <= c4_exp;
            s4_sig             <= c4_sig;
            s4_zero            <= c4_zero;
            v4                 <= v3;

            result5_reg        <= c5_result;
            v5                 <= v4;
        end
    end

    generate
        if (LATENCY > 5) begin : gen_extra_latency
            reg [31:0] extra_result [0:LATENCY-6];
            reg [LATENCY-6:0] extra_valid;
            integer i;

            always @(posedge clk) begin
                if (rst) begin
                    for (i = 0; i <= LATENCY-6; i = i + 1) begin
                        extra_result[i] <= 32'd0;
                        extra_valid[i]  <= 1'b0;
                    end
                end else begin
                    extra_result[0] <= result5_reg;
                    extra_valid[0]  <= v5;
                    for (i = 1; i <= LATENCY-6; i = i + 1) begin
                        extra_result[i] <= extra_result[i-1];
                        extra_valid[i]  <= extra_valid[i-1];
                    end
                end
            end

            assign result    = extra_result[LATENCY-6];
            assign valid_out = extra_valid[LATENCY-6];
        end else begin : gen_no_extra_latency
            assign result    = result5_reg;
            assign valid_out = v5;
        end
    endgenerate

endmodule