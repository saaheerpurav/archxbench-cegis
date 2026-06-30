`timescale 1ns/1ps

module gd_poly_update #(
    parameter N = 16,
    parameter STEP_W = (3*N) + 2,
    parameter OUT_W = STEP_W + 1
)(
    input  signed [N-1:0]      x_current,
    input  signed [STEP_W-1:0] step,
    output signed [OUT_W-1:0]  x_updated
);

    wire signed [OUT_W-1:0] x_ext;
    wire signed [OUT_W-1:0] step_ext;

    assign x_ext    = {{(OUT_W-N){x_current[N-1]}}, x_current};
    assign step_ext = {{(OUT_W-STEP_W){step[STEP_W-1]}}, step};

    assign x_updated = x_ext - step_ext;

endmodule