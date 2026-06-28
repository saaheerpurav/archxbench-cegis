`timescale 1ns/1ps

module conv2d_coeff_rom #(
    parameter KERNEL_SIZE = 3,
    parameter COEFF_W     = 16
) (
    output [KERNEL_SIZE*KERNEL_SIZE*COEFF_W-1:0] coeffs_flat
);

    function integer binomial_odd;
        input integer pos;
        input integer size;
        begin
            case (size)
                3: begin
                    case (pos)
                        0: binomial_odd = 1;
                        1: binomial_odd = 2;
                        2: binomial_odd = 1;
                        default: binomial_odd = 0;
                    endcase
                end

                5: begin
                    case (pos)
                        0: binomial_odd = 1;
                        1: binomial_odd = 4;
                        2: binomial_odd = 6;
                        3: binomial_odd = 4;
                        4: binomial_odd = 1;
                        default: binomial_odd = 0;
                    endcase
                end

                7: begin
                    case (pos)
                        0: binomial_odd = 1;
                        1: binomial_odd = 6;
                        2: binomial_odd = 15;
                        3: binomial_odd = 20;
                        4: binomial_odd = 15;
                        5: binomial_odd = 6;
                        6: binomial_odd = 1;
                        default: binomial_odd = 0;
                    endcase
                end

                default: begin
                    binomial_odd = 1;
                end
            endcase
        end
    endfunction

    function [COEFF_W-1:0] coeff_value;
        input integer r;
        input integer c;
        integer v;
        begin
            v = binomial_odd(r, KERNEL_SIZE) * binomial_odd(c, KERNEL_SIZE);
            coeff_value = v[COEFF_W-1:0];
        end
    endfunction

    genvar gr;
    genvar gc;

    generate
        for (gr = 0; gr < KERNEL_SIZE; gr = gr + 1) begin : gen_rows
            for (gc = 0; gc < KERNEL_SIZE; gc = gc + 1) begin : gen_cols
                assign coeffs_flat[((gr*KERNEL_SIZE + gc)*COEFF_W) +: COEFF_W] =
                    coeff_value(gr, gc);
            end
        end
    endgenerate

endmodule