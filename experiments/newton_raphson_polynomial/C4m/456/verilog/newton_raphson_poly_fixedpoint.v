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

    localparam EXT_WIDTH = (WIDTH * 4) + 8;
    localparam ST_IDLE   = 2'd0;
    localparam ST_CALC   = 2'd1;
    localparam ST_VERIFY = 2'd2;
    localparam ST_DONE   = 2'd3;

    reg [1:0] state;
    reg [31:0] iter_count;

    reg signed [WIDTH-1:0] x_reg;
    reg signed [WIDTH-1:0] c0_reg;
    reg signed [WIDTH-1:0] c1_reg;
    reg signed [WIDTH-1:0] c2_reg;
    reg signed [WIDTH-1:0] c3_reg;

    wire signed [EXT_WIDTH-1:0] poly_value;
    wire signed [EXT_WIDTH-1:0] deriv_value;
    wire signed [WIDTH-1:0] x_next;
    wire signed [WIDTH-1:0] step_value;
    wire deriv_zero;
    wire converged;
    wire verify_valid;

    nr_poly_eval #(
        .WIDTH(WIDTH),
        .FRAC(FRAC),
        .EXT_WIDTH(EXT_WIDTH)
    ) u_poly_eval (
        .x(x_reg),
        .coeff0(c0_reg),
        .coeff1(c1_reg),
        .coeff2(c2_reg),
        .coeff3(c3_reg),
        .p(poly_value)
    );

    nr_derivative_eval #(
        .WIDTH(WIDTH),
        .FRAC(FRAC),
        .EXT_WIDTH(EXT_WIDTH)
    ) u_derivative_eval (
        .x(x_reg),
        .coeff1(c1_reg),
        .coeff2(c2_reg),
        .coeff3(c3_reg),
        .p_prime(deriv_value)
    );

    nr_update_step #(
        .WIDTH(WIDTH),
        .FRAC(FRAC),
        .EXT_WIDTH(EXT_WIDTH)
    ) u_update_step (
        .x_current(x_reg),
        .p(poly_value),
        .p_prime(deriv_value),
        .x_next(x_next),
        .step(step_value),
        .derivative_zero(deriv_zero)
    );

    nr_convergence_check #(
        .WIDTH(WIDTH)
    ) u_convergence_check (
        .step(step_value),
        .p_prime_zero(deriv_zero),
        .tolerance(TOLERANCE),
        .converged(converged)
    );

    nr_root_verify #(
        .WIDTH(WIDTH),
        .EXT_WIDTH(EXT_WIDTH)
    ) u_root_verify (
        .p(poly_value),
        .tolerance(TOLERANCE),
        .valid(verify_valid)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= ST_IDLE;
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
                ST_IDLE: begin
                    ready <= 0;
                    valid <= 0;
                    iter_count <= 0;
                    if (start) begin
                        x_reg <= x_init;
                        c0_reg <= coeff0;
                        c1_reg <= coeff1;
                        c2_reg <= coeff2;
                        c3_reg <= coeff3;
                        root <= x_init;
                        state <= ST_CALC;
                    end
                end

                ST_CALC: begin
                    if ((iter_count >= (MAX_ITER - 1)) || converged) begin
                        root <= x_next;
                        x_reg <= x_next;
                        state <= ST_VERIFY;
                    end else begin
                        x_reg <= x_next;
                        root <= x_next;
                        iter_count <= iter_count + 1;
                    end
                end

                ST_VERIFY: begin
                    valid <= verify_valid;
                    ready <= 1'b1;
                    state <= ST_DONE;
                end

                ST_DONE: begin
                    ready <= 1'b1;
                    valid <= valid;
                    root <= root;
                end

                default: begin
                    state <= ST_IDLE;
                end
            endcase
        end
    end

endmodule