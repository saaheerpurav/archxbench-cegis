`timescale 1ns/1ps

module qgemm #(
  parameter VLEN    = 8,
  parameter K       = 64,
  parameter FP_W    = 32,
  parameter QBW     = 8,
  parameter ACC_W   = 32,
  parameter SCALE_W = 16,
  parameter SCALE_Q = 15
)(
  input  wire clk,
  input  wire rst,
  input  wire start,
  input  wire [VLEN*K*FP_W-1:0]    A_fp,
  input  wire [K*VLEN*FP_W-1:0]    B_fp,
  input  wire [SCALE_W-1:0]        scale_A,
  input  wire [SCALE_W-1:0]        scale_B,
  input  wire [QBW-1:0]            zp_A,
  input  wire [QBW-1:0]            zp_B,
  output reg  [VLEN*VLEN*FP_W-1:0] C_fp,
  output reg                       done
);

  localparam D_W = QBW + 1;

  wire [VLEN*K*D_W-1:0]     A_centered;
  wire [K*VLEN*D_W-1:0]     B_centered;
  wire [VLEN*VLEN*ACC_W-1:0] C_acc;
  wire [VLEN*VLEN*FP_W-1:0]  C_fp_comb;

  qgemm_quantize_matrix #(
    .ELEMS(VLEN*K),
    .FP_W(FP_W),
    .QBW(QBW),
    .SCALE_W(SCALE_W),
    .SCALE_Q(SCALE_Q),
    .REVERSE_IN(1)
  ) u_quant_A (
    .X_fp(A_fp),
    .scale(scale_A),
    .zp(zp_A),
    .X_centered(A_centered)
  );

  qgemm_quantize_matrix #(
    .ELEMS(K*VLEN),
    .FP_W(FP_W),
    .QBW(QBW),
    .SCALE_W(SCALE_W),
    .SCALE_Q(SCALE_Q),
    .REVERSE_IN(1)
  ) u_quant_B (
    .X_fp(B_fp),
    .scale(scale_B),
    .zp(zp_B),
    .X_centered(B_centered)
  );

  qgemm_int_gemm #(
    .VLEN(VLEN),
    .K(K),
    .QBW(QBW),
    .ACC_W(ACC_W)
  ) u_int_gemm (
    .A_centered(A_centered),
    .B_centered(B_centered),
    .C_acc(C_acc)
  );

  qgemm_dequantize_matrix #(
    .ELEMS(VLEN*VLEN),
    .FP_W(FP_W),
    .ACC_W(ACC_W),
    .SCALE_W(SCALE_W),
    .SCALE_Q(SCALE_Q)
  ) u_dequant (
    .C_acc(C_acc),
    .scale_A(scale_A),
    .scale_B(scale_B),
    .C_fp(C_fp_comb)
  );

  always @(posedge clk) begin
    if (rst) begin
      C_fp <= {VLEN*VLEN*FP_W{1'b0}};
      done <= 1'b0;
    end else begin
      if (start) begin
        C_fp <= C_fp_comb;
        done <= 1'b1;
      end else begin
        done <= 1'b0;
      end
    end
  end

endmodule