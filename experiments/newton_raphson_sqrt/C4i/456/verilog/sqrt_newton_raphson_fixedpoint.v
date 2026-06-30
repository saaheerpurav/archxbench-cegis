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
    reg [N-1:0] x_reg;
    reg [N-1:0] y_reg;
    reg [31:0] iter_count;

    wire x_is_zero;
    wire [N-1:0] initial_guess;
    wire [N-1:0] div_term;
    wire [N-1:0] next_y;
    wire converged;

    sqrt_nr_initial_guess #(
        .N(N),
        .M(M)
    ) u_initial_guess (
        .x_in(X),
        .x_is_zero(x_is_zero),
        .initial_y(initial_guess)
    );

    sqrt_nr_divide #(
        .N(N),
        .M(M)
    ) u_divide (
        .x_in(x_reg),
        .y_in(y_reg),
        .quotient(div_term)
    );

    sqrt_nr_iteration #(
        .N(N)
    ) u_iteration (
        .y_in(y_reg),
        .div_term(div_term),
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
            x_reg <= {N{1'b0}};
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
                        x_reg <= X;

                        if (x_is_zero) begin
                            y_reg <= {N{1'b0}};
                            sqrt_result <= {N{1'b0}};
                            ready <= 1'b1;
                            state <= STATE_DONE;
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

                    if (converged || (iter_count >= (ITER_MAX - 1))) begin
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