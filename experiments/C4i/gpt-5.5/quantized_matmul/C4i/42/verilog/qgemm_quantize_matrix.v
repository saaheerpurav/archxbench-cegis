`timescale 1ns/1ps

module qgemm_quantize_matrix #(
  parameter ELEMS      = 512,
  parameter FP_W       = 32,
  parameter QBW        = 8,
  parameter SCALE_W    = 16,
  parameter SCALE_Q    = 15,
  parameter REVERSE_IN = 1
)(
  input  wire [ELEMS*FP_W-1:0]       X_fp,
  input  wire [SCALE_W-1:0]          scale,
  input  wire [QBW-1:0]              zp,
  output reg  [ELEMS*(QBW+1)-1:0]    X_centered
);

  localparam D_W = QBW + 1;

  integer i;
  integer src_i;

  integer q_min;
  integer q_max;
  integer q_unclamped;
  integer q_clamped;
  integer centered;
  integer rounded;

  integer zp_int;
  integer scale_int;
  integer centered_min;
  integer centered_max;

  real x_real;
  real scale_real;
  real ratio;

  reg [31:0] fp_bits;

  function real fp32_to_real;
    input [31:0] bits;

    reg sign_bit;
    integer exp_field;
    integer frac_field;

    real mant;
    real val;

    begin
      sign_bit   = bits[31];
      exp_field  = bits[30:23];
      frac_field = bits[22:0];

      if (exp_field == 255) begin
        /*
         * Infinity is represented as a large finite value so that the
         * quantizer naturally clamps. NaN is treated as zero.
         */
        if (frac_field == 0)
          val = 1.0e30;
        else
          val = 0.0;
      end else if (exp_field == 0) begin
        if (frac_field == 0) begin
          val = 0.0;
        end else begin
          mant = frac_field / 8388608.0;
          val  = mant * (2.0 ** -126);
        end
      end else begin
        mant = 1.0 + (frac_field / 8388608.0);
        val  = mant * (2.0 ** (exp_field - 127));
      end

      if (sign_bit)
        fp32_to_real = -val;
      else
        fp32_to_real = val;
    end
  endfunction

  always @* begin
    X_centered = {ELEMS*D_W{1'b0}};

    q_min = 0;
    q_max = (1 << QBW) - 1;

    zp_int    = zp;
    scale_int = scale;

    centered_min = q_min - zp_int;
    centered_max = q_max - zp_int;

    if (scale_int == 0)
      scale_real = 0.0;
    else
      scale_real = scale_int / (2.0 ** SCALE_Q);

    for (i = 0; i < ELEMS; i = i + 1) begin
      /*
       * The system testbench packs logical element 0 into the most-significant
       * word by repeatedly doing:
       *
       *   X_fp = {X_fp, next_word};
       *
       * Therefore logical element i is physically located at source index
       * ELEMS-1-i when REVERSE_IN is enabled.
       */
      if (REVERSE_IN)
        src_i = ELEMS - 1 - i;
      else
        src_i = i;

      fp_bits = X_fp[src_i*FP_W +: 32];
      x_real  = fp32_to_real(fp_bits);

      if (scale_real == 0.0) begin
        q_clamped = zp_int;
      end else begin
        ratio = x_real / scale_real;

        /*
         * Quantization uses round-half-away-from-zero:
         *
         *   ratio >= 0 : $rtoi(ratio + 0.5)
         *   ratio <  0 : $rtoi(ratio - 0.5)
         *
         * However, avoid calling $rtoi on extreme real values. If the rounded
         * centered value would exceed the valid unsigned quantized range after
         * adding zp, clamp directly.
         */
        if (ratio >= (centered_max + 0.5)) begin
          q_clamped = q_max;
        end else if (ratio <= (centered_min - 0.5)) begin
          q_clamped = q_min;
        end else begin
          if (ratio >= 0.0)
            rounded = $rtoi(ratio + 0.5);
          else
            rounded = $rtoi(ratio - 0.5);

          q_unclamped = rounded + zp_int;

          if (q_unclamped < q_min)
            q_clamped = q_min;
          else if (q_unclamped > q_max)
            q_clamped = q_max;
          else
            q_clamped = q_unclamped;
        end
      end

      centered = q_clamped - zp_int;

      /*
       * Store centered signed value as QBW+1-bit two's-complement.
       */
      X_centered[i*D_W +: D_W] = centered[D_W-1:0];
    end
  end

endmodule