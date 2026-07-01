`timescale 1ns/1ps

module qgemm_dequantize_matrix #(
  parameter COUNT = 64,
  parameter FP_W = 32,
  parameter ACC_W = 32,
  parameter SCALE_W = 16,
  parameter SCALE_Q = 15
)(
  input  [COUNT*ACC_W-1:0] C_acc,
  input  [SCALE_W-1:0]     scale_A,
  input  [SCALE_W-1:0]     scale_B,
  output reg [COUNT*FP_W-1:0] C_fp
);

  integer i;
  reg signed [ACC_W-1:0] acc_word;
  real scale_a_real;
  real scale_b_real;
  real value;
  real q_divisor;

  function [31:0] real_to_fp32;
    input real x;

    integer exp_unbiased;
    integer exp_biased;
    integer frac;
    reg sign;
    real ax;
    real norm;

    begin
      if (x == 0.0) begin
        real_to_fp32 = 32'h00000000;
      end else begin
        sign = (x < 0.0);
        ax = sign ? -x : x;

        exp_unbiased = 0;
        norm = ax;

        while (norm >= 2.0) begin
          norm = norm / 2.0;
          exp_unbiased = exp_unbiased + 1;
        end

        while (norm < 1.0) begin
          norm = norm * 2.0;
          exp_unbiased = exp_unbiased - 1;
        end

        exp_biased = exp_unbiased + 127;

        if (exp_biased <= 0) begin
          real_to_fp32 = {sign, 31'b0};
        end else if (exp_biased >= 255) begin
          real_to_fp32 = {sign, 8'hff, 23'b0};
        end else begin
          frac = $rtoi((norm - 1.0) * 8388608.0 + 0.5);

          if (frac >= 8388608) begin
            frac = 0;
            exp_biased = exp_biased + 1;
          end

          if (exp_biased >= 255)
            real_to_fp32 = {sign, 8'hff, 23'b0};
          else
            real_to_fp32 = {sign, exp_biased[7:0], frac[22:0]};
        end
      end
    end
  endfunction

  always @* begin
    C_fp = {COUNT*FP_W{1'b0}};

    q_divisor = 1.0;
    for (i = 0; i < SCALE_Q; i = i + 1)
      q_divisor = q_divisor * 2.0;

    scale_a_real = $itor(scale_A) / q_divisor;
    scale_b_real = $itor(scale_B) / q_divisor;

    for (i = 0; i < COUNT; i = i + 1) begin
      acc_word = C_acc[i*ACC_W +: ACC_W];
      value = $itor(acc_word) * scale_a_real * scale_b_real;
      C_fp[i*FP_W +: FP_W] = real_to_fp32(value);
    end
  end

endmodule