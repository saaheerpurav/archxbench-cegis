`timescale 1ns/1ps

module gd_poly_update #(
    parameter N = 16,
    parameter STEP_W = (3*N) + 4
)(
    input  signed [N-1:0] x_current,
    input  signed [STEP_W-1:0] step,
    output signed [N-1:0] x_updated
);

    wire signed [STEP_W-1:0] x_ext;
    wire signed [STEP_W-1:0] updated_ext;

    assign x_ext = {{(STEP_W-N){x_current[N-1]}}, x_current};
    assign updated_ext = x_ext - step;
    assign x_updated = updated_ext[N-1:0];

endmodule