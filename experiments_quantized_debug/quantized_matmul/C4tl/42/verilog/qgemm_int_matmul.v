`timescale 1ns/1ps

module qgemm_int_matmul #(
  parameter VLEN  = 8,
  parameter K     = 64,
  parameter QBW   = 8,
  parameter ACC_W = 32
)(
  input  [VLEN*K*QBW-1:0]       A_q,
  input  [K*VLEN*QBW-1:0]       B_q,
  input  [QBW-1:0]              zp_A,
  input  [QBW-1:0]              zp_B,
  output reg [VLEN*VLEN*ACC_W-1:0] C_acc
);

  integer i;
  integer j;
  integer kk;

  reg signed [QBW:0]       a_centered;
  reg signed [QBW:0]       b_centered;
  reg signed [ACC_W-1:0]   acc;

  always @* begin
    C_acc = {VLEN*VLEN*ACC_W{1'b0}};

    for (i = 0; i < VLEN; i = i + 1) begin
      for (j = 0; j < VLEN; j = j + 1) begin
        acc = {ACC_W{1'b0}};

        for (kk = 0; kk < K; kk = kk + 1) begin
          a_centered = {1'b0, A_q[(i*K + kk)*QBW +: QBW]} - {1'b0, zp_A};
          b_centered = {1'b0, B_q[(kk*VLEN + j)*QBW +: QBW]} - {1'b0, zp_B};

          acc = acc + (a_centered * b_centered);
        end

        C_acc[(i*VLEN + j)*ACC_W +: ACC_W] = acc;
      end
    end
  end

endmodule