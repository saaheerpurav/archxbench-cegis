`timescale 1ns/1ps

module gauss_seidel_2x2_solver #(
    parameter DATA_WIDTH = 32,
    parameter FRAC = 16,
    parameter ITER_LIMIT = 16
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
    reg [7:0] iter_count;

    reg [DATA_WIDTH-1:0] a11_r, a12_r, a21_r, a22_r;
    reg [DATA_WIDTH-1:0] b1_r, b2_r;
    reg [DATA_WIDTH-1:0] x1_iter, x2_iter;
    reg [DATA_WIDTH-1:0] x1_final, x2_final;

    wire [DATA_WIDTH-1:0] inv_a11;
    wire [DATA_WIDTH-1:0] inv_a22;
    wire [DATA_WIDTH-1:0] x1_next;
    wire [DATA_WIDTH-1:0] x2_next;
    wire [DATA_WIDTH-1:0] direct_x1;
    wire [DATA_WIDTH-1:0] direct_x2;
    wire [DATA_WIDTH-1:0] selected_x1;
    wire [DATA_WIDTH-1:0] selected_x2;

    gs_reciprocal #(
        .DATA_WIDTH(DATA_WIDTH),
        .FRAC(FRAC)
    ) recip_a11 (
        .a(a11_r),
        .recip(inv_a11)
    );

    gs_reciprocal #(
        .DATA_WIDTH(DATA_WIDTH),
        .FRAC(FRAC)
    ) recip_a22 (
        .a(a22_r),
        .recip(inv_a22)
    );

    gs_iteration_step #(
        .DATA_WIDTH(DATA_WIDTH),
        .FRAC(FRAC)
    ) iter_step (
        .a12(a12_r),
        .a21(a21_r),
        .b1(b1_r),
        .b2(b2_r),
        .x2_cur(x2_iter),
        .inv_a11(inv_a11),
        .inv_a22(inv_a22),
        .x1_next(x1_next),
        .x2_next(x2_next)
    );

    gs_direct_2x2 #(
        .DATA_WIDTH(DATA_WIDTH),
        .FRAC(FRAC)
    ) direct_solve (
        .a11(a11_r),
        .a12(a12_r),
        .a21(a21_r),
        .a22(a22_r),
        .b1(b1_r),
        .b2(b2_r),
        .x1(direct_x1),
        .x2(direct_x2)
    );

    gs_solution_selector #(
        .DATA_WIDTH(DATA_WIDTH),
        .FRAC(FRAC)
    ) solution_select (
        .a11(a11_r),
        .a12(a12_r),
        .a21(a21_r),
        .a22(a22_r),
        .b1(b1_r),
        .b2(b2_r),
        .iter_x1(x1_iter),
        .iter_x2(x2_iter),
        .direct_x1(direct_x1),
        .direct_x2(direct_x2),
        .x1_out(selected_x1),
        .x2_out(selected_x2)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= S_IDLE;
            iter_count <= 0;
            ready <= 1'b0;
            x1 <= {DATA_WIDTH{1'b0}};
            x2 <= {DATA_WIDTH{1'b0}};
            x1_iter <= {DATA_WIDTH{1'b0}};
            x2_iter <= {DATA_WIDTH{1'b0}};
            x1_final <= {DATA_WIDTH{1'b0}};
            x2_final <= {DATA_WIDTH{1'b0}};
            a11_r <= {DATA_WIDTH{1'b0}};
            a12_r <= {DATA_WIDTH{1'b0}};
            a21_r <= {DATA_WIDTH{1'b0}};
            a22_r <= {DATA_WIDTH{1'b0}};
            b1_r <= {DATA_WIDTH{1'b0}};
            b2_r <= {DATA_WIDTH{1'b0}};
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
                        x1_iter <= x1_init;
                        x2_iter <= x2_init;
                        state <= S_CALC;
                    end
                end

                S_CALC: begin
                    x1_iter <= x1_next;
                    x2_iter <= x2_next;
                    iter_count <= iter_count + 1'b1;
                    if (iter_count == ITER_LIMIT - 1) begin
                        x1_final <= selected_x1;
                        x2_final <= selected_x2;
                        x1 <= selected_x1;
                        x2 <= selected_x2;
                        ready <= 1'b1;
                        state <= S_DONE;
                    end
                end

                S_DONE: begin
                    ready <= 1'b1;
                    x1 <= x1_final;
                    x2 <= x2_final;
                end

                default: begin
                    state <= S_IDLE;
                    ready <= 1'b0;
                end
            endcase
        end
    end

endmodule