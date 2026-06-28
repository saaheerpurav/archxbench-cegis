`timescale 1ns/1ps

module conv2d_coeff_rom #(
    parameter KERNEL_SIZE = 3,
    parameter COEFF_W     = 16
) (
    output reg [KERNEL_SIZE*KERNEL_SIZE*COEFF_W-1:0] coeffs_flat
);

    /*
     * Return the binomial coefficient C(n, k).
     *
     * For the supported Gaussian-style kernels:
     *   KERNEL_SIZE = 3 -> n = 2 -> 1, 2, 1
     *   KERNEL_SIZE = 5 -> n = 4 -> 1, 4, 6, 4, 1
     *   KERNEL_SIZE = 7 -> n = 6 -> 1, 6, 15, 20, 15, 6, 1
     */
    function integer binom;
        input integer n;
        input integer k;

        integer i;
        integer result;
        integer kk;
        begin
            if ((k < 0) || (k > n)) begin
                binom = 0;
            end else begin
                /*
                 * Use symmetry to keep the intermediate result small:
                 * C(n,k) = C(n,n-k)
                 */
                kk = k;
                if (kk > (n - kk))
                    kk = n - kk;

                result = 1;
                for (i = 1; i <= kk; i = i + 1) begin
                    result = (result * (n - kk + i)) / i;
                end

                binom = result;
            end
        end
    endfunction

    function integer coeff1d;
        input integer size;
        input integer pos;
        begin
            if ((pos < 0) || (pos >= size))
                coeff1d = 0;
            else
                coeff1d = binom(size - 1, pos);
        end
    endfunction

    integer r;
    integer c;
    integer coeff_val;

    always @* begin
        coeffs_flat = {KERNEL_SIZE*KERNEL_SIZE*COEFF_W{1'b0}};

        for (r = 0; r < KERNEL_SIZE; r = r + 1) begin
            for (c = 0; c < KERNEL_SIZE; c = c + 1) begin
                coeff_val = coeff1d(KERNEL_SIZE, r) * coeff1d(KERNEL_SIZE, c);
                coeffs_flat[((r*KERNEL_SIZE + c)*COEFF_W) +: COEFF_W] = coeff_val;
            end
        end
    end

endmodule