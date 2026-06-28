`timescale 1ns/1ps

module qgemm_dequantize_matrix #(
  parameter ELEMS   = 64,
  parameter FP_W    = 32,
  parameter ACC_W   = 32,
  parameter SCALE_W = 16,
  parameter SCALE_Q = 15
)(
  input  wire [ELEMS*ACC_W-1:0]      C_acc,
  input  wire [SCALE_W-1:0]          scale_A,
  input  wire [SCALE_W-1:0]          scale_B,
  output wire [ELEMS*FP_W-1:0]       C_fp
);

  /*
   * Convert unsigned fixed-point magnitude to IEEE-754 FP32.
   *
   * mag represents:
   *
   *   value = mag * 2^(-2*SCALE_Q)
   *
   * For the default Q15 scales this is Q30.
   */
  function [31:0] mag_q_to_fp32;
    input [63:0] mag;
    input        sign_bit;

    integer bit_idx;
    integer msb_pos;
    integer unbiased_exp;
    integer exp_field;
    integer rshift;
    integer lshift;
    integer frac_shift;

    reg [63:0] sig;
    reg [63:0] rem;
    reg [63:0] half;
    reg [63:0] base;
    reg [63:0] frac;

    reg        fp_sign;
    reg [7:0]  fp_exp;
    reg [22:0] fp_frac;
    reg [31:0] tmp32;

    begin
      fp_sign = sign_bit;
      fp_exp  = 8'd0;
      fp_frac = 23'd0;

      if (mag == 64'd0) begin
        mag_q_to_fp32 = 32'h00000000;
      end else begin
        msb_pos = 0;
        for (bit_idx = 0; bit_idx < 64; bit_idx = bit_idx + 1) begin
          if (mag[bit_idx])
            msb_pos = bit_idx;
        end

        unbiased_exp = msb_pos - (2*SCALE_Q);

        if (unbiased_exp > 127) begin
          fp_exp  = 8'hFF;
          fp_frac = 23'd0;
        end else if (unbiased_exp >= -126) begin
          if (msb_pos > 23) begin
            rshift = msb_pos - 23;

            sig  = mag >> rshift;
            base = sig << rshift;
            rem  = mag - base;
            half = 64'd1 << (rshift - 1);

            if ((rem > half) || ((rem == half) && sig[0]))
              sig = sig + 64'd1;
          end else begin
            lshift = 23 - msb_pos;
            sig = mag << lshift;
          end

          if (sig[24]) begin
            sig = sig >> 1;
            unbiased_exp = unbiased_exp + 1;
          end

          if (unbiased_exp > 127) begin
            fp_exp  = 8'hFF;
            fp_frac = 23'd0;
          end else begin
            exp_field = unbiased_exp + 127;
            tmp32     = exp_field;
            fp_exp    = tmp32[7:0];
            fp_frac   = sig[22:0];
          end
        end else begin
          frac_shift = (2*SCALE_Q) - 149;

          if (frac_shift > 0) begin
            if (frac_shift >= 64) begin
              frac = 64'd0;
              rem  = mag;
              half = 64'h8000000000000000;
            end else begin
              frac = mag >> frac_shift;
              base = frac << frac_shift;
              rem  = mag - base;
              half = 64'd1 << (frac_shift - 1);
            end

            if ((rem > half) || ((rem == half) && frac[0]))
              frac = frac + 64'd1;
          end else begin
            lshift = 149 - (2*SCALE_Q);

            if (lshift >= 64)
              frac = 64'hFFFFFFFFFFFFFFFF;
            else
              frac = mag << lshift;
          end

          if (frac >= 64'd8388608) begin
            fp_exp  = 8'd1;
            fp_frac = 23'd0;
          end else begin
            fp_exp  = 8'd0;
            fp_frac = frac[22:0];
          end
        end

        mag_q_to_fp32 = {fp_sign, fp_exp, fp_frac};
      end
    end
  endfunction


  /*
   * Dequantize one signed INT32 accumulator:
   *
   *   fp32(acc * scale_A * scale_B / 2^(2*SCALE_Q))
   *
   * scale_A and scale_B are unsigned 16-bit Q15 values.
   */
  function [31:0] dequant_one;
    input [31:0] acc_bits;
    input [15:0] sA;
    input [15:0] sB;

    reg        sign_bit;
    reg [31:0] acc_abs;
    reg [63:0] acc_abs_64;
    reg [63:0] sA_64;
    reg [63:0] sB_64;
    reg [63:0] prod1;
    reg [63:0] prod2;

    begin
      sign_bit = acc_bits[31];

      if (sign_bit)
        acc_abs = (~acc_bits) + 32'd1;
      else
        acc_abs = acc_bits;

      acc_abs_64 = {32'd0, acc_abs};
      sA_64      = {48'd0, sA};
      sB_64      = {48'd0, sB};

      prod1 = acc_abs_64 * sA_64;
      prod2 = prod1 * sB_64;

      dequant_one = mag_q_to_fp32(prod2, sign_bit);
    end
  endfunction


  genvar g;
  generate
    for (g = 0; g < ELEMS; g = g + 1) begin : GEN_DEQUANT
      assign C_fp[g*FP_W +: FP_W] =
        dequant_one(
          C_acc[g*ACC_W +: ACC_W],
          scale_A[15:0],
          scale_B[15:0]
        );
    end
  endgenerate

endmodule