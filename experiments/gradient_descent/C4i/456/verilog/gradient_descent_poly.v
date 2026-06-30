`timescale 1ns/1ps

module gradient_descent_poly #(
    parameter N = 16,
    parameter M = 8,
    parameter MAX_ITER = 10
)(
    input clk,
    input rst,
    input start,
    input signed [N-1:0] x,
    input signed [N-1:0] alpha,
    input signed [N-1:0] a,
    input signed [N-1:0] b,
    output reg signed [N-1:0] x_next,
    output reg ready
);

    localparam IDLE = 2'd0;
    localparam CALC = 2'd1;
    localparam DONE = 2'd2;

    reg [1:0] state;
    reg signed [N-1:0] x_reg;
    reg signed [N-1:0] alpha_reg;
    reg signed [N-1:0] a_reg;
    reg signed [N-1:0] b_reg;
    reg [31:0] iter_count;

    wire signed [N-1:0] gradient;
    wire signed [N-1:0] update_step;
    wire signed [N-1:0] updated_x;
    wire iter_done;

    gd_derivative #(
        .N(N),
        .M(M)
    ) derivative_u (
        .x(x_reg),
        .a(a_reg),
        .b(b_reg),
        .gradient(gradient)
    );

    gd_step #(
        .N(N),
        .M(M)
    ) step_u (
        .alpha(alpha_reg),
        .gradient(gradient),
        .step(update_step)
    );

    gd_update #(
        .N(N)
    ) update_u (
        .x_current(x_reg),
        .step(update_step),
        .x_updated(updated_x)
    );

    gd_iter_done iter_done_u (
        .iter_count(iter_count),
        .max_iter(MAX_ITER[31:0]),
        .done(iter_done)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            x_reg <= {N{1'b0}};
            alpha_reg <= {N{1'b0}};
            a_reg <= {N{1'b0}};
            b_reg <= {N{1'b0}};
            iter_count <= 32'd0;
            x_next <= {N{1'b0}};
            ready <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    ready <= 1'b0;
                    iter_count <= 32'd0;
                    if (start) begin
                        x_reg <= x;
                        alpha_reg <= alpha;
                        a_reg <= a;
                        b_reg <= b;
                        state <= (MAX_ITER == 0) ? DONE : CALC;
                        if (MAX_ITER == 0) begin
                            x_next <= x;
                            ready <= 1'b1;
                        end
                    end
                end

                CALC: begin
                    x_reg <= updated_x;
                    iter_count <= iter_count + 32'd1;

                    if (iter_done) begin
                        x_next <= updated_x;
                        ready <= 1'b1;
                        state <= DONE;
                    end
                end

                DONE: begin
                    ready <= 1'b1;
                    state <= DONE;
                end

                default: begin
                    state <= IDLE;
                    ready <= 1'b0;
                end
            endcase
        end
    end

endmodule