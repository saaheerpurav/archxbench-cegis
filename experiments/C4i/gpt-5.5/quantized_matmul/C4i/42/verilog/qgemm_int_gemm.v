`timescale 1ns/1ps

module qgemm_int_gemm #(
  parameter VLEN  = 8,
  parameter K     = 64,
  parameter QBW   = 8,
  parameter ACC_W = 32
)(
  input  wire [VLEN*K*(QBW+1)-1:0]  A_centered,
  input  wire [K*VLEN*(QBW+1)-1:0]  B_centered,
  output reg  [VLEN*VLEN*ACC_W-1:0] C_acc
);

  localparam D_W = QBW + 1;

  integer i;
  integer j;
  integer k_idx;
  integer a_index;
  integer b_index;
  integer c_index;

  reg signed [D_W-1:0]   a_val;
  reg signed [D_W-1:0]   b_val;
  reg signed [ACC_W-1:0] prod;
  reg signed [ACC_W-1:0] sum;

  function signed [ACC_W-1:0] sext_to_acc;
    input signed [D_W-1:0] x;
    begin
      sext_to_acc = x;
    end
  endfunction

  always @* begin
    C_acc = {VLEN*VLEN*ACC_W{1'b0}};

    for (i = 0; i < VLEN; i = i + 1) begin
      for (j = 0; j < VLEN; j = j + 1) begin
        sum = {ACC_W{1'b0}};

        for (k_idx = 0; k_idx < K; k_idx = k_idx + 1) begin
          a_index = i*K + k_idx;
          b_index = k_idx*VLEN + j;

          a_val = $signed(A_centered[a_index*D_W +: D_W]);
          b_val = $signed(B_centered[b_index*D_W +: D_W]);

          prod = sext_to_acc(a_val) * sext_to_acc(b_val);
          sum  = sum + prod;
        end

        c_index = i*VLEN + j;
        C_acc[c_index*ACC_W +: ACC_W] = sum;
      end
    end
  end

endmodule