`timescale 1ns/1ps

module sqrt_newton_raphson_fixedpoint #(
    parameter N = 16,
    parameter M = 8,
    parameter ITER_MAX = 10
)(
    input clk,
    input rst,
    input start,
    input [N-1:0] X,
    output reg [N-1:0] sqrt_result,
    output reg ready
);

    localparam STATE_IDLE = 2'd0;
    localparam STATE_CALC = 2'd1;
    localparam STATE_DONE = 2'd2;

    reg [1:0] state;
    reg [N-1:0] X_reg;
    reg [N-1:0] y_reg;
    reg [31:0] iter_count;

    wire is_zero;
    wire [N-1:0] special_result;
    wire [N-1:0] initial_guess;
    wire [N-1:0] next_y;
    wire converged;

    sqrt_nr_special_case #(
        .N(N)
    ) u_special_case (
        .X(X),
        .is_zero(is_zero),
        .special_result(special_result)
    );

    sqrt_nr_initial_guess #(
        .N(N),
        .M(M)
    ) u_initial_guess (
        .X(X),
        .initial_guess(initial_guess)
    );

    sqrt_nr_iteration_step #(
        .N(N),
        .M(M)
    ) u_iteration_step (
        .X(X_reg),
        .y_current(y_reg),
        .y_next(next_y)
    );

    sqrt_nr_convergence #(
        .N(N)
    ) u_convergence (
        .y_current(y_reg),
        .y_next(next_y),
        .converged(converged)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= STATE_IDLE;
            X_reg <= {N{1'b0}};
            y_reg <= {N{1'b0}};
            iter_count <= 32'd0;
            sqrt_result <= {N{1'b0}};
            ready <= 1'b0;
        end else begin
            case (state)
                STATE_IDLE: begin
                    ready <= 1'b0;
                    iter_count <= 32'd0;

                    if (start) begin
                        X_reg <= X;

                        if (is_zero) begin
                            sqrt_result <= special_result;
                            y_reg <= special_result;
                            state <= STATE_DONE;
                            ready <= 1'b1;
                        end else begin
                            y_reg <= initial_guess;
                            sqrt_result <= {N{1'b0}};
                            state <= STATE_CALC;
                        end
                    end
                end

                STATE_CALC: begin
                    y_reg <= next_y;
                    iter_count <= iter_count + 32'd1;

                    if (converged || (iter_count == (ITER_MAX - 1))) begin
                        sqrt_result <= next_y;
                        ready <= 1'b1;
                        state <= STATE_DONE;
                    end
                end

                STATE_DONE: begin
                    ready <= 1'b1;
                    state <= STATE_DONE;
                end

                default: begin
                    state <= STATE_IDLE;
                    ready <= 1'b0;
                end
            endcase
        end
    end

endmodule