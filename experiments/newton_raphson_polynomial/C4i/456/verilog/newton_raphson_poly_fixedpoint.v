`timescale 1ns/1ps

module newton_raphson_poly_fixedpoint #(
    parameter WIDTH = 16,
    parameter FRAC = 8,
    parameter MAX_ITER = 50,
    parameter signed [WIDTH-1:0] TOLERANCE = 8
)(
    input clk,
    input rst,
    input start,
    input signed [WIDTH-1:0] x_init,
    input signed [WIDTH-1:0] coeff0,
    input signed [WIDTH-1:0] coeff1,
    input signed [WIDTH-1:0] coeff2,
    input signed [WIDTH-1:0] coeff3,
    output reg signed [WIDTH-1:0] root,
    output reg ready,
    output reg valid
);

    localparam STATE_IDLE   = 2'd0;
    localparam STATE_CALC   = 2'd1;
    localparam STATE_VERIFY = 2'd2;
    localparam STATE_DONE   = 2'd3;

    reg [1:0] state;
    reg [31:0] iter_count;

    reg signed [WIDTH-1:0] x_reg;
    reg signed [WIDTH-1:0] c0_reg;
    reg signed [WIDTH-1:0] c1_reg;
    reg signed [WIDTH-1:0] c2_reg;
    reg signed [WIDTH-1:0] c3_reg;

    wire signed [WIDTH-1:0] poly_value;
    wire signed [WIDTH-1:0] deriv_value;
    wire signed [WIDTH-1:0] x_next;
    wire signed [WIDTH-1:0] delta_value;
    wire derivative_zero;
    wire converged;
    wire verify_valid;

    nr_poly_deriv_eval #(
        .WIDTH(WIDTH),
        .FRAC(FRAC)
    ) eval_u (
        .x(x_reg),
        .coeff0(c0_reg),
        .coeff1(c1_reg),
        .coeff2(c2_reg),
        .coeff3(c3_reg),
        .poly(poly_value),
        .deriv(deriv_value)
    );

    nr_newton_update #(
        .WIDTH(WIDTH),
        .FRAC(FRAC)
    ) update_u (
        .x_current(x_reg),
        .poly(poly_value),
        .deriv(deriv_value),
        .x_next(x_next),
        .delta(delta_value),
        .derivative_zero(derivative_zero)
    );

    nr_convergence_check #(
        .WIDTH(WIDTH),
        .TOLERANCE(TOLERANCE)
    ) conv_u (
        .delta(delta_value),
        .poly(poly_value),
        .derivative_zero(derivative_zero),
        .converged(converged)
    );

    nr_root_verify #(
        .WIDTH(WIDTH),
        .FRAC(FRAC),
        .TOLERANCE(TOLERANCE)
    ) verify_u (
        .x(x_reg),
        .coeff0(c0_reg),
        .coeff1(c1_reg),
        .coeff2(c2_reg),
        .coeff3(c3_reg),
        .valid(verify_valid)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= STATE_IDLE;
            iter_count <= 0;
            x_reg <= 0;
            c0_reg <= 0;
            c1_reg <= 0;
            c2_reg <= 0;
            c3_reg <= 0;
            root <= 0;
            ready <= 0;
            valid <= 0;
        end else begin
            case (state)
                STATE_IDLE: begin
                    ready <= 0;
                    valid <= 0;
                    iter_count <= 0;

                    if (start) begin
                        x_reg <= x_init;
                        c0_reg <= coeff0;
                        c1_reg <= coeff1;
                        c2_reg <= coeff2;
                        c3_reg <= coeff3;
                        state <= STATE_CALC;
                    end
                end

                STATE_CALC: begin
                    if (!derivative_zero)
                        x_reg <= x_next;

                    iter_count <= iter_count + 1;

                    if (converged || (iter_count >= MAX_ITER - 1))
                        state <= STATE_VERIFY;
                end

                STATE_VERIFY: begin
                    root <= x_reg;
                    valid <= verify_valid;
                    ready <= 1'b1;
                    state <= STATE_DONE;
                end

                STATE_DONE: begin
                    ready <= 1'b1;
                    root <= root;
                    valid <= valid;
                end

                default: begin
                    state <= STATE_IDLE;
                end
            endcase
        end
    end

endmodule