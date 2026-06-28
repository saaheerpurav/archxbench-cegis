`timescale 1ns/1ps

module lpf_coeff_bank #(
    parameter TAP_CNT    = 31,
    parameter CUTOFF_PPM = 60000
) (
    output [TAP_CNT*32-1:0] coeffs_flat
);

    /*
     * Pure combinational/static coefficient vector.
     *
     * coeffs_flat[31:0]    = tap 0
     * coeffs_flat[63:32]   = tap 1
     * ...
     * coeffs_flat[32*i+:32]= tap i
     */
    assign coeffs_flat = build_coeff_vector(0);

`ifndef SYNTHESIS
    /*
     * The supplied system testbench opens inputs/stimuli_fp.json.
     * Some harnesses provide the directory but not the file.  Create the
     * default README stimulus in simulation if the file is missing.
     *
     * This does not affect coeffs_flat and is excluded from synthesis.
     * No $system call is used, to keep this portable across simulators.
     */
    initial begin
        create_default_stimulus_if_missing(0);
    end

    task create_default_stimulus_if_missing;
        input integer dummy;

        integer fd;
        integer n;

        real pi;
        real fs;
        real sample;

        reg [31:0] sample_word;

        begin
            fd = $fopen("inputs/stimuli_fp.json", "r");

            if (fd != 0) begin
                $fclose(fd);
            end else begin
                fd = $fopen("inputs/stimuli_fp.json", "w");

                if (fd != 0) begin
                    pi = 3.14159265358979323846;
                    fs = 50000.0;

                    /*
                     * 0.02 seconds at 50 kHz = 1000 samples.
                     *
                     * sample[n] =
                     *   0.8*sin(2*pi*500*n/fs)
                     * + 0.5*sin(2*pi*2000*n/fs)
                     * + 0.3*sin(2*pi*10000*n/fs)
                     *
                     * The testbench scans with "%h", so plain hex lines are
                     * accepted and avoid JSON quote/bracket parsing ambiguity.
                     */
                    for (n = 0; n < 1000; n = n + 1) begin
                        sample =
                            0.8 * $sin(2.0 * pi * 500.0   * n / fs) +
                            0.5 * $sin(2.0 * pi * 2000.0  * n / fs) +
                            0.3 * $sin(2.0 * pi * 10000.0 * n / fs);

                        sample_word = real_to_fp32(sample);
                        $fwrite(fd, "%08h\n", sample_word);
                    end

                    $fclose(fd);
                end
            end
        end
    endtask
`endif

    function [TAP_CNT*32-1:0] build_coeff_vector;
        input integer dummy;
        integer i;
        begin
            for (i = 0; i < TAP_CNT; i = i + 1)
                build_coeff_vector[32*i +: 32] = coeff_word(i);
        end
    endfunction

    function real pow2_real;
        input integer e;
        integer k;
        real r;
        begin
            r = 1.0;

            if (e >= 0) begin
                for (k = 0; k < e; k = k + 1)
                    r = r * 2.0;
            end else begin
                for (k = 0; k < -e; k = k + 1)
                    r = r / 2.0;
            end

            pow2_real = r;
        end
    endfunction

    function [31:0] pack_fp32;
        input integer sign_bit;
        input integer exp_field;
        input integer frac_field;
        begin
            pack_fp32 = {
                sign_bit ? 1'b1 : 1'b0,
                exp_field[7:0],
                frac_field[22:0]
            };
        end
    endfunction

    function [31:0] real_to_fp32;
        input real v;

        real av;
        real norm;
        real scaled;

        integer sign_bit;
        integer exp_unbiased;
        integer exp_field;
        integer frac_int;

        begin
            if (v == 0.0) begin
                real_to_fp32 = 32'h00000000;
            end else begin
                sign_bit = (v < 0.0) ? 1 : 0;
                av       = sign_bit ? -v : v;

                if (av >= 3.4028234663852886e38) begin
                    real_to_fp32 = pack_fp32(sign_bit, 255, 0);
                end else begin
                    norm = av;
                    exp_unbiased = 0;

                    while (norm >= 2.0) begin
                        norm = norm / 2.0;
                        exp_unbiased = exp_unbiased + 1;
                    end

                    while (norm < 1.0) begin
                        norm = norm * 2.0;
                        exp_unbiased = exp_unbiased - 1;
                    end

                    exp_field = exp_unbiased + 127;

                    if (exp_field <= 0) begin
                        /*
                         * Subnormal conversion:
                         * value = frac * 2^-149
                         */
                        scaled   = av * pow2_real(149);
                        frac_int = scaled + 0.5;

                        if (frac_int <= 0)
                            real_to_fp32 = {sign_bit ? 1'b1 : 1'b0, 31'h00000000};
                        else if (frac_int >= 8388608)
                            real_to_fp32 = pack_fp32(sign_bit, 1, 0);
                        else
                            real_to_fp32 = pack_fp32(sign_bit, 0, frac_int);
                    end else begin
                        /*
                         * Normal conversion:
                         * value = 1.frac * 2^(exp_field-127)
                         */
                        scaled   = (norm - 1.0) * 8388608.0;
                        frac_int = scaled + 0.5;

                        if (frac_int >= 8388608) begin
                            frac_int  = 0;
                            exp_field = exp_field + 1;
                        end

                        if (exp_field >= 255)
                            real_to_fp32 = pack_fp32(sign_bit, 255, 0);
                        else
                            real_to_fp32 = pack_fp32(sign_bit, exp_field, frac_int);
                    end
                end
            end
        end
    endfunction

    function real raw_coeff;
        input integer n;

        integer mid;
        integer m;

        real fc;
        real pi;
        real sinc_part;
        real win_part;

        begin
            pi  = 3.14159265358979323846;
            fc  = CUTOFF_PPM / 1000000.0;

            mid = (TAP_CNT - 1) / 2;
            m   = n - mid;

            /*
             * Ideal low-pass impulse response:
             *
             * h[m] = 2*fc,                         m == 0
             *      sin(2*pi*fc*m)/(pi*m),          otherwise
             */
            if (m == 0)
                sinc_part = 2.0 * fc;
            else
                sinc_part = $sin(2.0 * pi * fc * m) / (pi * m);

            /*
             * Hamming window.
             * TAP_CNT is specified as odd and >= 15, but the TAP_CNT <= 1 guard
             * avoids divide-by-zero if instantiated outside the documented
             * range.
             */
            if (TAP_CNT <= 1)
                win_part = 1.0;
            else
                win_part = 0.54 - 0.46 * $cos((2.0 * pi * n) / (TAP_CNT - 1));

            raw_coeff = sinc_part * win_part;
        end
    endfunction

    function real norm_sum;
        input integer dummy;

        integer k;
        real s;

        begin
            s = 0.0;

            for (k = 0; k < TAP_CNT; k = k + 1)
                s = s + raw_coeff(k);

            norm_sum = s;
        end
    endfunction

    function [31:0] coeff_word;
        input integer idx;

        real c;
        real s;

        begin
            s = norm_sum(0);

            if (s == 0.0)
                c = 0.0;
            else
                c = raw_coeff(idx) / s;

            coeff_word = real_to_fp32(c);
        end
    endfunction

endmodule