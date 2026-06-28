`timescale 1ns/1ps

module gs_iteration_step_2x2 #(
    parameter DATA_WIDTH = 32,
    parameter FRAC       = 16
)(
    input  [DATA_WIDTH-1:0] a12,
    input  [DATA_WIDTH-1:0] a21,
    input  [DATA_WIDTH-1:0] b1,
    input  [DATA_WIDTH-1:0] b2,
    input  [DATA_WIDTH-1:0] x1_curr,
    input  [DATA_WIDTH-1:0] x2_curr,
    input  [DATA_WIDTH-1:0] inv_a11,
    input  [DATA_WIDTH-1:0] inv_a22,
    output reg [DATA_WIDTH-1:0] x1_next,
    output reg [DATA_WIDTH-1:0] x2_next
);

    reg signed [DATA_WIDTH-1:0] a12_s;
    reg signed [DATA_WIDTH-1:0] a21_s;
    reg signed [DATA_WIDTH-1:0] b1_s;
    reg signed [DATA_WIDTH-1:0] b2_s;
    reg signed [DATA_WIDTH-1:0] x1_curr_s;
    reg signed [DATA_WIDTH-1:0] x2_curr_s;
    reg signed [DATA_WIDTH-1:0] inv_a11_s;
    reg signed [DATA_WIDTH-1:0] inv_a22_s;

    reg signed [(2*DATA_WIDTH)-1:0] prod_a12_x2;
    reg signed [(2*DATA_WIDTH)-1:0] prod_a12_x2_q;
    reg signed [(2*DATA_WIDTH)-1:0] rhs1;

    reg signed [(3*DATA_WIDTH)-1:0] prod_rhs1_inv;
    reg signed [(3*DATA_WIDTH)-1:0] x1_next_wide;
    reg signed [DATA_WIDTH-1:0]     x1_next_s;

    reg signed [(2*DATA_WIDTH)-1:0] prod_a21_x1n;
    reg signed [(2*DATA_WIDTH)-1:0] prod_a21_x1n_q;
    reg signed [(2*DATA_WIDTH)-1:0] rhs2;

    reg signed [(3*DATA_WIDTH)-1:0] prod_rhs2_inv;
    reg signed [(3*DATA_WIDTH)-1:0] x2_next_wide;
    reg signed [DATA_WIDTH-1:0]     x2_next_s;

    always @* begin
        a12_s     = a12;
        a21_s     = a21;
        b1_s      = b1;
        b2_s      = b2;
        x1_curr_s = x1_curr;
        x2_curr_s = x2_curr;
        inv_a11_s = inv_a11;
        inv_a22_s = inv_a22;

        /*
         * x1_next = (b1 - a12*x2_curr) * inv_a11
         *
         * a12*x2_curr is Q(FRAC)*Q(FRAC), so shift right by FRAC
         * to return to Q(FRAC).
         */
        prod_a12_x2   = a12_s * x2_curr_s;
        prod_a12_x2_q = prod_a12_x2 >>> FRAC;

        rhs1 = {{DATA_WIDTH{b1_s[DATA_WIDTH-1]}}, b1_s} - prod_a12_x2_q;

        prod_rhs1_inv = rhs1 * inv_a11_s;
        x1_next_wide  = prod_rhs1_inv >>> FRAC;
        x1_next_s     = x1_next_wide[DATA_WIDTH-1:0];

        /*
         * x2_next = (b2 - a21*x1_next) * inv_a22
         *
         * Gauss-Seidel uses the newly computed x1_next, not x1_curr.
         * Use the signed internal x1_next_s to avoid unsigned multiply
         * behavior from the output port declaration.
         */
        prod_a21_x1n   = a21_s * x1_next_s;
        prod_a21_x1n_q = prod_a21_x1n >>> FRAC;

        rhs2 = {{DATA_WIDTH{b2_s[DATA_WIDTH-1]}}, b2_s} - prod_a21_x1n_q;

        prod_rhs2_inv = rhs2 * inv_a22_s;
        x2_next_wide  = prod_rhs2_inv >>> FRAC;
        x2_next_s     = x2_next_wide[DATA_WIDTH-1:0];

        x1_next = x1_next_s;
        x2_next = x2_next_s;
    end

endmodule