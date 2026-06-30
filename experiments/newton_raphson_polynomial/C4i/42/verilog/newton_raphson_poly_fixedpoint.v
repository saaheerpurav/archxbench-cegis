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

    localparam XW = 64;
    localparam ST_IDLE   = 2'd0;
    localparam ST_CALC   = 2'd1;
    localparam ST_VERIFY = 2'd2;
    localparam ST_DONE   = 2'd3;

    reg [1:0] state;
    reg [31:0] iter_count;

    reg signed [XW-1:0] x_reg;
    reg signed [WIDTH-1:0] c0_reg, c1_reg, c2_reg, c3_reg;

    wire signed [XW-1:0] poly_value;
    wire signed [XW-1:0] deriv_value;
    wire signed [XW-1:0] step_value;
    wire signed [XW-1:0] x_next;
    wire signed [WIDTH-1:0] root_candidate;
    wire signed [XW-1:0] verify_poly_value;
    wire verify_valid;

    assign x_next = x_reg - step_value;
    assign root_candidate = x_reg[WIDTH-1:0];

    nr_poly_eval_fixed #(
        .WIDTH(WIDTH),
        .FRAC(FRAC),
        .XW(XW)
    ) u_poly_eval_iter (
        .x(x_reg),
        .coeff0(c0_reg),
        .coeff1(c1_reg),
        .coeff2(c2_reg),
        .coeff3(c3_reg),
        .poly(poly_value)
    );

    nr_derivative_eval_fixed #(
        .WIDTH(WIDTH),
        .FRAC(FRAC),
        .XW(XW)
    ) u_derivative_eval (
        .x(x_reg),
        .coeff1(c1_reg),
        .coeff2(c2_reg),
        .coeff3(c3_reg),
        .derivative(deriv_value)
    );

    nr_fixed_div_step #(
        .FRAC(FRAC),
        .XW(XW)
    ) u_fixed_div_step (
        .numerator(poly_value),
        .denominator(deriv_value),
        .quotient(step_value)
    );

    nr_poly_eval_fixed #(
        .WIDTH(WIDTH),
        .FRAC(FRAC),
        .XW(XW)
    ) u_poly_eval_verify (
        .x(x_reg),
        .coeff0(c0_reg),
        .coeff1(c1_reg),
        .coeff2(c2_reg),
        .coeff3(c3_reg),
        .poly(verify_poly_value)
    );

    nr_root_verify_fixed #(
        .WIDTH(WIDTH),
        .FRAC(FRAC),
        .XW(XW)
    ) u_root_verify (
        .poly_value(verify_poly_value),
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
            ready <= 1'b0;
            valid <= 1'b0;
        end else begin
            case (state)
                ST_IDLE: begin
                    ready <= 1'b0;
                    valid <= 1'b0;
                    iter_count <= 0;

                    if (start) begin
                        x_reg <= {{(XW-WIDTH){x_init[WIDTH-1]}}, x_init};
                        c0_reg <= coeff0;
                        c1_reg <= coeff1;
                        c2_reg <= coeff2;
                        c3_reg <= coeff3;
                        state <= ST_CALC;
                    end
                end

                ST_CALC: begin
                    if (deriv_value != 0)
                        x_reg <= x_next;
                    else
                        x_reg <= x_reg;

                    if (iter_count == MAX_ITER-1) begin
                        state <= ST_VERIFY;
                    end

                    iter_count <= iter_count + 1;
                end

                ST_VERIFY: begin
                    root <= root_candidate;
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