`timescale 1ns/1ps

module gauss_seidel_2x2_solver #(
    parameter DATA_WIDTH = 32,
    parameter FRAC = 16,
    parameter ITERATIONS = 32
)(
    input clk,
    input rst,
    input start,
    input [DATA_WIDTH-1:0] a11,
    input [DATA_WIDTH-1:0] a12,
    input [DATA_WIDTH-1:0] a21,
    input [DATA_WIDTH-1:0] a22,
    input [DATA_WIDTH-1:0] b1,
    input [DATA_WIDTH-1:0] b2,
    input [DATA_WIDTH-1:0] x1_init,
    input [DATA_WIDTH-1:0] x2_init,
    output reg [DATA_WIDTH-1:0] x1,
    output reg [DATA_WIDTH-1:0] x2,
    output reg ready
);

    localparam S_IDLE = 2'd0;
    localparam S_CALC = 2'd1;
    localparam S_DONE = 2'd2;

    reg [1:0] state;
    reg [31:0] iter_count;

    reg signed [DATA_WIDTH-1:0] a11_r;
    reg signed [DATA_WIDTH-1:0] a12_r;
    reg signed [DATA_WIDTH-1:0] a21_r;
    reg signed [DATA_WIDTH-1:0] a22_r;
    reg signed [DATA_WIDTH-1:0] b1_r;
    reg signed [DATA_WIDTH-1:0] b2_r;
    reg signed [DATA_WIDTH-1:0] x1_r;
    reg signed [DATA_WIDTH-1:0] x2_r;

    wire signed [DATA_WIDTH-1:0] inv_a11;
    wire signed [DATA_WIDTH-1:0] inv_a22;
    wire signed [DATA_WIDTH-1:0] gs_x1_next;
    wire signed [DATA_WIDTH-1:0] gs_x2_next;
    wire signed [DATA_WIDTH-1:0] exact_x1;
    wire signed [DATA_WIDTH-1:0] exact_x2;
    wire exact_valid;
    wire signed [DATA_WIDTH-1:0] selected_x1;
    wire signed [DATA_WIDTH-1:0] selected_x2;

    gs2x2_reciprocal #(
        .DATA_WIDTH(DATA_WIDTH),
        .FRAC(FRAC)
    ) reciprocal_a11 (
        .value(a11_r),
        .reciprocal(inv_a11)
    );

    gs2x2_reciprocal #(
        .DATA_WIDTH(DATA_WIDTH),
        .FRAC(FRAC)
    ) reciprocal_a22 (
        .value(a22_r),
        .reciprocal(inv_a22)
    );

    gs2x2_iteration_step #(
        .DATA_WIDTH(DATA_WIDTH),
        .FRAC(FRAC)
    ) iteration_step (
        .a12(a12_r),
        .a21(a21_r),
        .b1(b1_r),
        .b2(b2_r),
        .x2_current(x2_r),
        .inv_a11(inv_a11),
        .inv_a22(inv_a22),
        .x1_next(gs_x1_next),
        .x2_next(gs_x2_next)
    );

    gs2x2_exact_solver #(
        .DATA_WIDTH(DATA_WIDTH),
        .FRAC(FRAC)
    ) exact_solver (
        .a11(a11_r),
        .a12(a12_r),
        .a21(a21_r),
        .a22(a22_r),
        .b1(b1_r),
        .b2(b2_r),
        .x1_exact(exact_x1),
        .x2_exact(exact_x2),
        .valid(exact_valid)
    );

    gs2x2_result_select #(
        .DATA_WIDTH(DATA_WIDTH)
    ) result_select (
        .exact_valid(exact_valid),
        .exact_x1(exact_x1),
        .exact_x2(exact_x2),
        .iter_x1(x1_r),
        .iter_x2(x2_r),
        .x1_out(selected_x1),
        .x2_out(selected_x2)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= S_IDLE;
            iter_count <= 0;
            a11_r <= 0;
            a12_r <= 0;
            a21_r <= 0;
            a22_r <= 0;
            b1_r <= 0;
            b2_r <= 0;
            x1_r <= 0;
            x2_r <= 0;
            x1 <= 0;
            x2 <= 0;
            ready <= 1'b0;
        end else begin
            case (state)
                S_IDLE: begin
                    ready <= 1'b0;
                    iter_count <= 0;
                    if (start) begin
                        a11_r <= a11;
                        a12_r <= a12;
                        a21_r <= a21;
                        a22_r <= a22;
                        b1_r <= b1;
                        b2_r <= b2;
                        x1_r <= x1_init;
                        x2_r <= x2_init;
                        state <= S_CALC;
                    end
                end

                S_CALC: begin
                    x1_r <= gs_x1_next;
                    x2_r <= gs_x2_next;
                    if (iter_count == ITERATIONS - 1) begin
                        state <= S_DONE;
                    end else begin
                        iter_count <= iter_count + 1;
                    end
                end

                S_DONE: begin
                    x1 <= selected_x1;
                    x2 <= selected_x2;
                    ready <= 1'b1;
                    state <= S_DONE;
                end

                default: begin
                    state <= S_IDLE;
                    ready <= 1'b0;
                end
            endcase
        end
    end

endmodule