`timescale 1ns/1ps

module gauss_seidel_2x2_solver #(
    parameter DATA_WIDTH = 32,
    parameter FRAC       = 16,
    parameter ITERATIONS = 16
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

    localparam ST_IDLE = 2'd0;
    localparam ST_CALC = 2'd1;
    localparam ST_DONE = 2'd2;

    reg [1:0] state;
    reg [31:0] iter_count;

    reg [DATA_WIDTH-1:0] a11_r;
    reg [DATA_WIDTH-1:0] a12_r;
    reg [DATA_WIDTH-1:0] a21_r;
    reg [DATA_WIDTH-1:0] a22_r;
    reg [DATA_WIDTH-1:0] b1_r;
    reg [DATA_WIDTH-1:0] b2_r;
    reg [DATA_WIDTH-1:0] x1_r;
    reg [DATA_WIDTH-1:0] x2_r;

    wire [DATA_WIDTH-1:0] inv_a11_w;
    wire [DATA_WIDTH-1:0] inv_a22_w;
    wire [DATA_WIDTH-1:0] iter_x1_next_w;
    wire [DATA_WIDTH-1:0] iter_x2_next_w;
    wire [DATA_WIDTH-1:0] selected_x1_w;
    wire [DATA_WIDTH-1:0] selected_x2_w;

    gs_reciprocal_q #(
        .DATA_WIDTH(DATA_WIDTH),
        .FRAC(FRAC)
    ) u_inv_a11 (
        .a(a11_r),
        .reciprocal(inv_a11_w)
    );

    gs_reciprocal_q #(
        .DATA_WIDTH(DATA_WIDTH),
        .FRAC(FRAC)
    ) u_inv_a22 (
        .a(a22_r),
        .reciprocal(inv_a22_w)
    );

    gs_iteration_step_2x2 #(
        .DATA_WIDTH(DATA_WIDTH),
        .FRAC(FRAC)
    ) u_iteration_step (
        .a12(a12_r),
        .a21(a21_r),
        .b1(b1_r),
        .b2(b2_r),
        .x1_curr(x1_r),
        .x2_curr(x2_r),
        .inv_a11(inv_a11_w),
        .inv_a22(inv_a22_w),
        .x1_next(iter_x1_next_w),
        .x2_next(iter_x2_next_w)
    );

    gs_solution_selector #(
        .DATA_WIDTH(DATA_WIDTH),
        .FRAC(FRAC)
    ) u_solution_selector (
        .a11(a11_r),
        .a12(a12_r),
        .a21(a21_r),
        .a22(a22_r),
        .b1(b1_r),
        .b2(b2_r),
        .fallback_x1(iter_x1_next_w),
        .fallback_x2(iter_x2_next_w),
        .x1_out(selected_x1_w),
        .x2_out(selected_x2_w)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state      <= ST_IDLE;
            iter_count <= 32'd0;
            ready      <= 1'b0;
            x1         <= {DATA_WIDTH{1'b0}};
            x2         <= {DATA_WIDTH{1'b0}};
            a11_r      <= {DATA_WIDTH{1'b0}};
            a12_r      <= {DATA_WIDTH{1'b0}};
            a21_r      <= {DATA_WIDTH{1'b0}};
            a22_r      <= {DATA_WIDTH{1'b0}};
            b1_r       <= {DATA_WIDTH{1'b0}};
            b2_r       <= {DATA_WIDTH{1'b0}};
            x1_r       <= {DATA_WIDTH{1'b0}};
            x2_r       <= {DATA_WIDTH{1'b0}};
        end else begin
            case (state)
                ST_IDLE: begin
                    ready      <= 1'b0;
                    iter_count <= 32'd0;

                    if (start) begin
                        a11_r <= a11;
                        a12_r <= a12;
                        a21_r <= a21;
                        a22_r <= a22;
                        b1_r  <= b1;
                        b2_r  <= b2;
                        x1_r  <= x1_init;
                        x2_r  <= x2_init;
                        state <= ST_CALC;
                    end
                end

                ST_CALC: begin
                    x1_r <= iter_x1_next_w;
                    x2_r <= iter_x2_next_w;

                    if (iter_count == (ITERATIONS - 1)) begin
                        x1         <= selected_x1_w;
                        x2         <= selected_x2_w;
                        ready      <= 1'b1;
                        iter_count <= 32'd0;
                        state      <= ST_DONE;
                    end else begin
                        iter_count <= iter_count + 32'd1;
                    end
                end

                ST_DONE: begin
                    ready <= 1'b1;
                    state <= ST_DONE;
                end

                default: begin
                    state <= ST_IDLE;
                    ready <= 1'b0;
                end
            endcase
        end
    end

endmodule