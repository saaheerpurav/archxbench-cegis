`timescale 1ns/1ps

module qgemm_dequantize_matrix #(
  parameter VLEN    = 8,
  parameter FP_W    = 32,
  parameter ACC_W   = 32,
  parameter SCALE_W = 16,
  parameter SCALE_Q = 15
)(
  input      [VLEN*VLEN*ACC_W-1:0]     C_acc,
  input      [SCALE_W-1:0]             scale_A,
  input      [SCALE_W-1:0]             scale_B,
  output reg [VLEN*VLEN*FP_W-1:0]      C_fp
);

  localparam ELEMS        = VLEN * VLEN;
  localparam SCALE_EXT_W  = SCALE_W + 1;
  localparam PROD1_W      = ACC_W + SCALE_EXT_W;
  localparam PROD_W       = PROD1_W + SCALE_EXT_W;
  localparam MAG_W        = PROD_W + 1;
  localparam FP32_EXP_W   = 8;
  localparam FP32_FRAC_W  = 23;
  localparam FP32_BIAS    = 127;
  localparam FP32_EMIN    = -126;
  localparam FP32_EMAX    = 127;
  localparam TOTAL_Q      = 2 * SCALE_Q;

  integer idx;

  function [MAG_W-1:0] rshift_round_nearest_even;
    input [MAG_W-1:0] x;
    input integer sh;

    reg [MAG_W-1:0] q;
    reg round_bit;
    reg sticky;
    integer b;
    begin
      if (sh <= 0) begin
        rshift_round_nearest_even = x;
      end else begin
        if (sh >= MAG_W)
          q = {MAG_W{1'b0}};
        else
          q = x >> sh;

        round_bit = 1'b0;
        sticky    = 1'b0;

        if ((sh - 1) >= 0 && (sh - 1) < MAG_W)
          round_bit = x[sh - 1];

        for (b = 0; b < MAG_W; b = b + 1) begin
          if (b < (sh - 1))
            sticky = sticky | x[b];
        end

        if (round_bit && (sticky || q[0]))
          q = q + {{(MAG_W-1){1'b0}}, 1'b1};

        rshift_round_nearest_even = q;
      end
    end
  endfunction

  function [31:0] fixed_dequant_to_fp32;
    input signed [ACC_W-1:0] acc;
    input        [SCALE_W-1:0] sA;
    input        [SCALE_W-1:0] sB;

    reg signed [SCALE_EXT_W-1:0] sA_pos;
    reg signed [SCALE_EXT_W-1:0] sB_pos;

    reg signed [PROD1_W-1:0] prod1;
    reg signed [PROD_W-1:0]  prod;

    reg sign_bit;
    reg [MAG_W-1:0] mag;
    reg [MAG_W-1:0] sig_ext;

    integer msb;
    integer bit_idx;
    integer unbiased_exp;
    integer exp_field;
    integer shift_amt;

    reg [7:0]  exp_bits;
    reg [22:0] frac_bits;
    begin
      sA_pos = {1'b0, sA};
      sB_pos = {1'b0, sB};

      prod1 = acc * sA_pos;
      prod  = prod1 * sB_pos;

      sign_bit  = prod[PROD_W-1];
      exp_bits  = 8'd0;
      frac_bits = 23'd0;

      if (prod == {PROD_W{1'b0}}) begin
        fixed_dequant_to_fp32 = 32'h00000000;
      end else begin
        if (sign_bit)
          mag = {1'b0, -prod};
        else
          mag = {1'b0, prod};

        msb = 0;
        for (bit_idx = 0; bit_idx < MAG_W; bit_idx = bit_idx + 1) begin
          if (mag[bit_idx])
            msb = bit_idx;
        end

        unbiased_exp = msb - TOTAL_Q;

        if (unbiased_exp > FP32_EMAX) begin
          exp_bits  = 8'hff;
          frac_bits = 23'd0;
        end else if (unbiased_exp >= FP32_EMIN) begin
          shift_amt = msb - FP32_FRAC_W;

          if (shift_amt >= 0)
            sig_ext = rshift_round_nearest_even(mag, shift_amt);
          else
            sig_ext = mag << (-shift_amt);

          /*
            sig_ext is the rounded 24-bit significand including the hidden bit.
            If rounding produced 2.000000..., renormalize by shifting right one
            and increasing the exponent.
          */
          if (sig_ext[FP32_FRAC_W+1]) begin
            sig_ext = sig_ext >> 1;
            unbiased_exp = unbiased_exp + 1;
          end else if (sig_ext[FP32_FRAC_W]) begin
            /*
              Expected normal case: hidden bit is already at bit 23.
            */
            sig_ext = sig_ext;
          end

          if (unbiased_exp > FP32_EMAX) begin
            exp_bits  = 8'hff;
            frac_bits = 23'd0;
          end else begin
            exp_field = unbiased_exp + FP32_BIAS;
            exp_bits  = exp_field[7:0];
            frac_bits = sig_ext[22:0];
          end
        end else begin
          /*
            Subnormal path.

            FP32 subnormal value is:
              frac * 2^-149

            Exact fixed value is:
              mag * 2^(-TOTAL_Q)

            Therefore:
              frac = round_nearest_even(mag * 2^(149 - TOTAL_Q))
          */
          shift_amt = TOTAL_Q - 149;

          if (shift_amt >= 0)
            sig_ext = rshift_round_nearest_even(mag, shift_amt);
          else
            sig_ext = mag << (-shift_amt);

          if (sig_ext == {MAG_W{1'b0}}) begin
            exp_bits  = 8'd0;
            frac_bits = 23'd0;
          end else if (sig_ext[FP32_FRAC_W]) begin
            /*
              Rounded up to the smallest normal number.
            */
            exp_bits  = 8'd1;
            frac_bits = 23'd0;
          end else begin
            exp_bits  = 8'd0;
            frac_bits = sig_ext[22:0];
          end
        end

        fixed_dequant_to_fp32 = {sign_bit, exp_bits, frac_bits};
      end
    end
  endfunction

  always @* begin
    C_fp = {ELEMS*FP_W{1'b0}};

    for (idx = 0; idx < ELEMS; idx = idx + 1) begin
      C_fp[idx*FP_W +: FP_W] =
        fixed_dequant_to_fp32(
          C_acc[idx*ACC_W +: ACC_W],
          scale_A,
          scale_B
        );
    end
  end

endmodule