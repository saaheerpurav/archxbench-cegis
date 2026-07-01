`timescale 1ns/1ps

module nr_convergence_check #(
    parameter WIDTH = 16
)(
    input  signed [WIDTH-1:0] step,
    input                     p_prime_zero,
    input  signed [WIDTH-1:0] tolerance,
    output                    converged
);

    wire signed [WIDTH:0] step_ext = {step[WIDTH-1], step};
    wire signed [WIDTH:0] tol_ext  = {tolerance[WIDTH-1], tolerance};

    wire [WIDTH:0] abs_step = step_ext[WIDTH] ? -step_ext : step_ext;
    wire [WIDTH:0] abs_tol  = tol_ext[WIDTH]  ? -tol_ext  : tol_ext;

    assign converged = p_prime_zero || (abs_step <= abs_tol);

endmodule