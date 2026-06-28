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

    localparam [1:0] ST_IDLE = 2'd0;
    localparam [1:0] ST_CALC = 2'd1;
    localparam [1:0] ST_DONE = 2'd2;

    reg [1:0] state;
    reg [N-1:0] X_reg;
    reg [N-1:0] y_reg;
    reg [31:0] iter_count;

    wire [N-1:0] initial_y;
    wire input_is_zero;

    wire [N-1:0] div_quotient;
    wire [N-1:0] next_y;
    wire converged;

    wire final_iteration;

    assign final_iteration = (ITER_MAX <= 1) ? 1'b1 : (iter_count >= (ITER_MAX - 1));

    sqrt_nr_initial_guess #(
        .N(N),
        .M(M)
    ) u_initial_guess (
        .X(X),
        .initial_y(initial_y),
        .is_zero(input_is_zero)
    );

    sqrt_nr_divide #(
        .N(N),
        .M(M)
    ) u_divide (
        .X(X_reg),
        .y(y_reg),
        .quotient(div_quotient)
    );

    sqrt_nr_update #(
        .N(N)
    ) u_update (
        .y(y_reg),
        .quotient(div_quotient),
        .next_y(next_y)
    );

    sqrt_nr_convergence #(
        .N(N)
    ) u_convergence (
        .current_y(y_reg),
        .next_y(next_y),
        .converged(converged)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= ST_IDLE;
            X_reg <= {N{1'b0}};
            y_reg <= {N{1'b0}};
            iter_count <= 32'd0;
            sqrt_result <= {N{1'b0}};
            ready <= 1'b0;
        end else begin
            case (state)
                ST_IDLE: begin
                    ready <= 1'b0;
                    iter_count <= 32'd0;

                    if (start) begin
                        X_reg <= X;

                        if (input_is_zero) begin
                            y_reg <= {N{1'b0}};
                            sqrt_result <= {N{1'b0}};
                            ready <= 1'b1;
                            state <= ST_DONE;
                        end else begin
                            y_reg <= initial_y;
                            sqrt_result <= {N{1'b0}};
                            ready <= 1'b0;
                            state <= ST_CALC;
                        end
                    end
                end

                ST_CALC: begin
                    if (converged || final_iteration) begin
                        y_reg <= next_y;
                        sqrt_result <= next_y;
                        ready <= 1'b1;
                        state <= ST_DONE;
                    end else begin
                        y_reg <= next_y;
                        iter_count <= iter_count + 32'd1;
                        ready <= 1'b0;
                        state <= ST_CALC;
                    end
                end

                ST_DONE: begin
                    ready <= 1'b1;
                    sqrt_result <= sqrt_result;
                    y_reg <= y_reg;
                    X_reg <= X_reg;
                    iter_count <= iter_count;
                    state <= ST_DONE;
                end

                default: begin
                    state <= ST_IDLE;
                    X_reg <= {N{1'b0}};
                    y_reg <= {N{1'b0}};
                    iter_count <= 32'd0;
                    sqrt_result <= {N{1'b0}};
                    ready <= 1'b0;
                end
            endcase
        end
    end

endmodule