`timescale 1ns/1ps

module qgemm_int_gemm #(
  parameter VLEN  = 8,
  parameter K     = 64,
  parameter QBW   = 8,
  parameter ACC_W = 32
)(
  input      [VLEN*K*(QBW+1)-1:0]      A_centered,
  input      [K*VLEN*(QBW+1)-1:0]      B_centered,
  output reg [VLEN*VLEN*ACC_W-1:0]     C_acc
);

  localparam QDW    = QBW + 1;
  localparam PROD_W = 2 * QDW;

  integer i;
  integer j;
  integer kk;

  integer a_idx;
  integer b_idx;
  integer c_idx;

  reg signed [QDW-1:0]     a_val;
  reg signed [QDW-1:0]     b_val;
  reg signed [PROD_W-1:0]  prod;
  reg signed [ACC_W-1:0]   sum;

  always @* begin
    C_acc = {VLEN*VLEN*ACC_W{1'b0}};

    for (i = 0; i < VLEN; i = i + 1) begin
      for (j = 0; j < VLEN; j = j + 1) begin
        sum = {ACC_W{1'b0}};

        for (kk = 0; kk < K; kk = kk + 1) begin
          a_idx = (i*K + kk) * QDW;
          b_idx = (kk*VLEN + j) * QDW;

          a_val = A_centered[a_idx +: QDW];
          b_val = B_centered[b_idx +: QDW];

          prod = a_val * b_val;
          sum  = sum + prod;
        end

        c_idx = (i*VLEN + j) * ACC_W;
        C_acc[c_idx +: ACC_W] = sum;
      end
    end
  end

endmodule