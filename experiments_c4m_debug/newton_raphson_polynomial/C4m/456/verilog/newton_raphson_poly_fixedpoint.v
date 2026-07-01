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

    localparam EXT = WIDTH * 4;
    localparam S_IDLE   = 2'd0;
    localparam S_CALC   = 2'd1;
    localparam S_VERIFY = 2'd2;
    localparam S_DONE   = 2'd3;

    reg [1:0] state;
    reg [31:0] iter_count;

    reg signed [WIDTH-1:0] x_reg;
    reg signed [WIDTH-1:0] c0_reg;
    reg signed [WIDTH-1:0] c1_reg;
    reg signed [WIDTH-1:0] c2_reg;
    reg signed [WIDTH-1:0] c3_reg;

    wire signed [EXT-1:0] poly_value;
    wire signed [EXT-1:0] deriv_value;
    wire signed [WIDTH-1:0] next_x;
    wire signed [EXT-1:0] verify_poly_value;
    wire verify_valid;

    nr_poly_eval_cubic #(
        .WIDTH(WIDTH),
        .FRAC(FRAC),
        .EXT(EXT)
    ) u_poly_eval_iter (
        .x(x_reg),
        .coeff0(c0_reg),
        .coeff1(c1_reg),
        .coeff2(c2_reg),
        .coeff3(c3_reg),
        .p(poly_value)
    );

    nr_derivative_eval_cubic #(
        .WIDTH(WIDTH),
        .FRAC(FRAC),
        .EXT(EXT)
    ) u_deriv_eval_iter (
        .x(x_reg),
        .coeff1(c1_reg),
        .coeff2(c2_reg),
        .coeff3(c3_reg),
        .dp(deriv_value)
    );

    nr_newton_step #(
        .WIDTH(WIDTH),
        .FRAC(FRAC),
        .EXT(EXT)
    ) u_newton_step (
        .x(x_reg),
        .p(poly_value),
        .dp(deriv_value),
        .x_next(next_x)
    );

    nr_poly_eval_cubic #(
        .WIDTH(WIDTH),
        .FRAC(FRAC),
        .EXT(EXT)
    ) u_poly_eval_verify (
        .x(x_reg),
        .coeff0(c0_reg),
        .coeff1(c1_reg),
        .coeff2(c2_reg),
        .coeff3(c3_reg),
        .p(verify_poly_value)
    );

    nr_root_verify #(
        .WIDTH(WIDTH),
        .FRAC(FRAC),
        .EXT(EXT)
    ) u_root_verify (
        .p(verify_poly_value),
        .tolerance(TOLERANCE),
        .valid(verify_valid)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= S_IDLE;
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
                S_IDLE: begin
                    ready <= 1'b0;
                    valid <= 1'b0;
                    iter_count <= 0;
                    if (start) begin
                        x_reg <= x_init;
                        c0_reg <= coeff0;
                        c1_reg <= coeff1;
                        c2_reg <= coeff2;
                        c3_reg <= coeff3;
                        state <= S_CALC;
                    end
                end

                S_CALC: begin
                    x_reg <= next_x;
                    if (iter_count == MAX_ITER - 1) begin
                        state <= S_VERIFY;
                    end else begin
                        iter_count <= iter_count + 1;
                    end
                end

                S_VERIFY: begin
                    root <= x_reg;
                    valid <= verify_valid;
                    ready <= 1'b1;
                    state <= S_DONE;
                end

                S_DONE: begin
                    ready <= 1'b1;
                    valid <= valid;
                    root <= root;
                end

                default: begin
                    state <= S_IDLE;
                end
            endcase
        end
    end

endmodule