`timescale 1ns/1ps

module qgemm_quantize_matrix #(
  parameter ROWS    = 8,
  parameter COLS    = 64,
  parameter FP_W    = 32,
  parameter QBW     = 8,
  parameter SCALE_W = 16,
  parameter SCALE_Q = 15
)(
  input      [ROWS*COLS*FP_W-1:0]        fp_matrix,
  input      [SCALE_W-1:0]               scale,
  input      [QBW-1:0]                   zp,
  output reg [ROWS*COLS*(QBW+1)-1:0]     q_centered
);

  localparam ELEMS = ROWS * COLS;
  localparam QDW   = QBW + 1;

  integer idx;
  integer in_lsb;
  integer out_lsb;
  integer max_q;
  integer zp_i;
  integer lo_center;
  integer hi_center;
  integer q_cent;

  reg [31:0] fp_bits;
  real       val_r;
  real       scale_r;
  real       ratio_r;

  function real pow2;
    input integer e;
    integer n;
    real r;
    begin
      r = 1.0;

      if (e >= 0) begin
        for (n = 0; n < e; n = n + 1)
          r = r * 2.0;
      end else begin
        for (n = 0; n < -e; n = n + 1)
          r = r / 2.0;
      end

      pow2 = r;
    end
  endfunction

  function real fp32_to_real;
    input [31:0] bits;

    reg     sign;
    integer exp_f;
    integer exp_u;
    integer frac_i;
    real    mant;
    real    out_r;

    begin
      sign   = bits[31];
      exp_f  = bits[30:23];
      frac_i = bits[22:0];

      if (exp_f == 255) begin
        if (frac_i == 0)
          out_r = sign ? -1.0e30 : 1.0e30;
        else
          out_r = 0.0;
      end else if (exp_f == 0) begin
        if (frac_i == 0) begin
          out_r = 0.0;
        end else begin
          mant  = $itor(frac_i) / 8388608.0;
          out_r = mant * pow2(-126);

          if (sign)
            out_r = -out_r;
        end
      end else begin
        exp_u = exp_f - 127;
        mant  = 1.0 + ($itor(frac_i) / 8388608.0);
        out_r = mant * pow2(exp_u);

        if (sign)
          out_r = -out_r;
      end

      fp32_to_real = out_r;
    end
  endfunction

  function real q15_to_real;
    input [SCALE_W-1:0] s;
    begin
      q15_to_real = $itor(s) / pow2(SCALE_Q);
    end
  endfunction

  function integer round_nearest;
    input real x;
    begin
      if (x >= 0.0)
        round_nearest = $rtoi(x + 0.5);
      else
        round_nearest = $rtoi(x - 0.5);
    end
  endfunction

  always @* begin
    q_centered = {ELEMS*QDW{1'b0}};

    max_q     = (1 << QBW) - 1;
    zp_i      = zp;
    lo_center = -zp_i;
    hi_center = max_q - zp_i;
    scale_r   = q15_to_real(scale);

    for (idx = 0; idx < ELEMS; idx = idx + 1) begin
      /*
       * The supplied testbench packs input matrices by repeatedly doing:
       *
       *   bus = {bus, next_word};
       *
       * Therefore logical matrix element 0 resides in the most-significant
       * FP32 word, and logical element ELEMS-1 resides in the least-significant
       * FP32 word.
       */
      in_lsb  = (ELEMS - 1 - idx) * FP_W;
      out_lsb = idx * QDW;

      fp_bits = fp_matrix[in_lsb +: FP_W];
      val_r   = fp32_to_real(fp_bits);

      if (scale_r <= 0.0) begin
        q_cent = 0;
      end else begin
        /*
         * Quantization:
         *
         *   q_unsigned = round(fp / scale) + zp
         *   q_sat      = clamp(q_unsigned, 0, 2^QBW - 1)
         *   q_centered = q_sat - zp
         *
         * Equivalently:
         *
         *   q_centered = clamp(round(fp / scale),
         *                      -zp,
         *                      2^QBW - 1 - zp)
         */
        ratio_r = val_r / scale_r;

        if (ratio_r > $itor(hi_center))
          q_cent = hi_center;
        else if (ratio_r < $itor(lo_center))
          q_cent = lo_center;
        else
          q_cent = round_nearest(ratio_r);
      end

      q_centered[out_lsb +: QDW] = q_cent[QDW-1:0];
    end
  end

endmodule