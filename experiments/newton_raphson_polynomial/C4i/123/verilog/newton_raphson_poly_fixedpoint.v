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
    reg [15:0] iter_count;
    reg signed [WIDTH-1:0] x_reg;
    reg signed [WIDTH-1:0] c0_reg, c1_reg, c2_reg, c3_reg;

    wire signed [WIDTH-1:0] poly_value;
    wire signed [WIDTH-1:0] deriv_value;
    wire signed [WIDTH-1:0] correction;
    wire signed [WIDTH-1:0] x_next;
    wire verify_valid;

    nr_poly_eval_fixed #(
        .WIDTH(WIDTH),
        .FRAC(FRAC)
    ) u_poly_eval (
        .x(x_reg),
        .coeff0(c0_reg),
        .coeff1(c1_reg),
        .coeff2(c2_reg),
        .coeff3(c3_reg),
        .poly(poly_value)
    );

    nr_deriv_eval_fixed #(
        .WIDTH(WIDTH),
        .FRAC(FRAC)
    ) u_deriv_eval (
        .x(x_reg),
        .coeff1(c1_reg),
        .coeff2(c2_reg),
        .coeff3(c3_reg),
        .deriv(deriv_value)
    );

    nr_fixed_div #(
        .WIDTH(WIDTH),
        .FRAC(FRAC)
    ) u_fixed_div (
        .numerator(poly_value),
        .denominator(deriv_value),
        .quotient(correction)
    );

    nr_newton_update #(
        .WIDTH(WIDTH)
    ) u_newton_update (
        .x_current(x_reg),
        .correction(correction),
        .derivative_zero(deriv_value == {WIDTH{1'b0}}),
        .x_next(x_next)
    );

    nr_root_verify #(
        .WIDTH(WIDTH),
        .TOLERANCE(TOLERANCE)
    ) u_root_verify (
        .poly_value(poly_value),
        .valid(verify_valid)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= STATE_IDLE;
            iter_count <= 16'd0;
            x_reg <= {WIDTH{1'b0}};
            c0_reg <= {WIDTH{1'b0}};
            c1_reg <= {WIDTH{1'b0}};
            c2_reg <= {WIDTH{1'b0}};
            c3_reg <= {WIDTH{1'b0}};
            root <= {WIDTH{1'b0}};
            ready <= 1'b0;
            valid <= 1'b0;
        end else begin
            case (state)
                STATE_IDLE: begin
                    ready <= 1'b0;
                    valid <= 1'b0;
                    iter_count <= 16'd0;
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
                    x_reg <= x_next;
                    if (iter_count == MAX_ITER - 1) begin
                        root <= x_next;
                        state <= STATE_VERIFY;
                    end
                    iter_count <= iter_count + 16'd1;
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