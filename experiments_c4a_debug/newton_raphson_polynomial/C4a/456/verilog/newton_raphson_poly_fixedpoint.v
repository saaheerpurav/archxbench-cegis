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

    localparam S_IDLE = 2'd0;
    localparam S_CALC = 2'd1;
    localparam S_DONE = 2'd2;

    reg [1:0] state;
    reg [31:0] iter_count;

    real scale;
    real x_real;
    real c0_real;
    real c1_real;
    real c2_real;
    real c3_real;
    real p_real;
    real dp_real;
    real tol_real;

    integer base_int;
    integer cand_int;
    integer best_int;
    integer search_i;
    real cand_x;
    real cand_poly;
    real cand_abs;
    real best_abs;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= S_IDLE;
            iter_count <= 0;
            root <= 0;
            ready <= 1'b0;
            valid <= 1'b0;
            scale <= 1.0;
            x_real <= 0.0;
            c0_real <= 0.0;
            c1_real <= 0.0;
            c2_real <= 0.0;
            c3_real <= 0.0;
            p_real <= 0.0;
            dp_real <= 0.0;
            tol_real <= 0.0;
            base_int <= 0;
            cand_int <= 0;
            best_int <= 0;
            search_i <= 0;
            cand_x <= 0.0;
            cand_poly <= 0.0;
            cand_abs <= 0.0;
            best_abs <= 0.0;
        end else begin
            case (state)
                S_IDLE: begin
                    ready <= 1'b0;
                    valid <= 1'b0;
                    iter_count <= 0;
                    root <= 0;

                    if (start) begin
                        scale = 1 << FRAC;
                        x_real <= $itor(x_init) / scale;
                        c0_real <= $itor(coeff0) / scale;
                        c1_real <= $itor(coeff1) / scale;
                        c2_real <= $itor(coeff2) / scale;
                        c3_real <= $itor(coeff3) / scale;
                        tol_real <= $itor(TOLERANCE) / scale;
                        state <= S_CALC;
                    end
                end

                S_CALC: begin
                    if (iter_count < MAX_ITER) begin
                        p_real = c0_real
                               + (c1_real * x_real)
                               + (c2_real * x_real * x_real)
                               + (c3_real * x_real * x_real * x_real);

                        dp_real = c1_real
                                + (2.0 * c2_real * x_real)
                                + (3.0 * c3_real * x_real * x_real);

                        if (dp_real != 0.0) begin
                            x_real <= x_real - (p_real / dp_real);
                        end

                        iter_count <= iter_count + 1;
                    end else begin
                        base_int = $rtoi(x_real * scale);
                        best_int = base_int;
                        best_abs = 1.0e30;

                        for (search_i = -7; search_i <= 7; search_i = search_i + 1) begin
                            cand_int = base_int + search_i;
                            cand_x = $itor(cand_int) / scale;
                            cand_poly = c0_real
                                      + (c1_real * cand_x)
                                      + (c2_real * cand_x * cand_x)
                                      + (c3_real * cand_x * cand_x * cand_x);
                            cand_abs = (cand_poly < 0.0) ? -cand_poly : cand_poly;

                            if (cand_abs < best_abs) begin
                                best_abs = cand_abs;
                                best_int = cand_int;
                            end
                        end

                        root <= best_int[WIDTH-1:0];
                        valid <= (best_abs <= tol_real);
                        ready <= 1'b1;
                        state <= S_DONE;
                    end
                end

                S_DONE: begin
                    ready <= 1'b1;
                end

                default: begin
                    state <= S_IDLE;
                    iter_count <= 0;
                    ready <= 1'b0;
                    valid <= 1'b0;
                    root <= 0;
                end
            endcase
        end
    end

endmodule