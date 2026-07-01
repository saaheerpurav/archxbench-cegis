`timescale 1ns/1ps

module qgemm_quantize_matrix #(
  parameter COUNT = 512,
  parameter FP_W = 32,
  parameter QBW = 8,
  parameter SCALE_W = 16,
  parameter SCALE_Q = 15
)(
  input  [COUNT*FP_W-1:0] fp_in,
  input  [SCALE_W-1:0]    scale,
  input  [QBW-1:0]        zp,
  output reg [COUNT*QBW-1:0] q_out
);

  integer i;
  integer qv;
  reg [FP_W-1:0] fp_word;

  function real fp32_to_real;
    input [31:0] bits;
    integer sign;
    integer exp;
    integer frac;
    integer e;
    real mant;
    begin
      sign = bits[31] ? -1 : 1;
      exp = bits[30:23];
      frac = bits[22:0];

      if (exp == 0 && frac == 0) begin
        fp32_to_real = 0.0;
      end else if (exp == 0) begin
        mant = frac / 8388608.0;
        fp32_to_real = sign * mant * (2.0 ** (-126));
      end else if (exp == 255) begin
        fp32_to_real = 0.0;
      end else begin
        e = exp - 127;
        mant = 1.0 + (frac / 8388608.0);
        fp32_to_real = sign * mant * (2.0 ** e);
      end
    end
  endfunction

  function integer round_real_to_int;
    input real x;
    begin
      if (x >= 0.0)
        round_real_to_int = $rtoi(x + 0.5);
      else
        round_real_to_int = $rtoi(x - 0.5);
    end
  endfunction

  function integer quant_one;
    input [31:0] bits;
    input [SCALE_W-1:0] sc;
    input [QBW-1:0] z;
    real f;
    real s;
    integer q;
    integer qmin;
    integer qmax;
    begin
      s = sc / (2.0 ** SCALE_Q);
      f = fp32_to_real(bits);

      qmin = 0;
      qmax = (1 << QBW) - 1;

      if (s == 0.0)
        q = z;
      else
        q = round_real_to_int(f / s) + z;

      if (q < qmin)
        q = qmin;
      if (q > qmax)
        q = qmax;

      quant_one = q;
    end
  endfunction

  always @* begin
    q_out = {COUNT*QBW{1'b0}};

    for (i = 0; i < COUNT; i = i + 1) begin
      fp_word = fp_in[(COUNT-1-i)*FP_W +: FP_W];
      qv = quant_one(fp_word, scale, zp);
      q_out[i*QBW +: QBW] = qv[QBW-1:0];
    end
  end

endmodule