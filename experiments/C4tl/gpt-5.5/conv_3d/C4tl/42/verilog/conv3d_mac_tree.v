`timescale 1ns/1ps

module conv3d_mac_tree #(
    parameter K1 = 3,
    parameter K2 = 3,
    parameter K3 = 3,
    parameter DATA_W = 8,
    parameter LOG_KW = 4
) (
    input  [K1*K2*K3*DATA_W-1:0] window_flat,
    input  [K1*K2*K3*DATA_W-1:0] kernel,
    output [DATA_W+LOG_KW-1:0]   sum_out
);

    function integer clog2_int;
        input integer value;
        integer tmp;
        begin
            tmp = value - 1;
            clog2_int = 0;
            while (tmp > 0) begin
                clog2_int = clog2_int + 1;
                tmp = tmp >> 1;
            end
        end
    endfunction

    localparam integer TAPS   = K1 * K2 * K3;
    localparam integer PROD_W = 2 * DATA_W;
    localparam integer ACC_W  = PROD_W + clog2_int(TAPS);

    integer i;

    reg [ACC_W-1:0]  acc;
    reg [DATA_W-1:0] voxel_i;
    reg [DATA_W-1:0] coeff_i;
    reg [PROD_W-1:0] prod_i;

    always @* begin
        acc     = {ACC_W{1'b0}};
        voxel_i = {DATA_W{1'b0}};
        coeff_i = {DATA_W{1'b0}};
        prod_i  = {PROD_W{1'b0}};

        for (i = 0; i < TAPS; i = i + 1) begin
            voxel_i = window_flat[i*DATA_W +: DATA_W];
            coeff_i = kernel[i*DATA_W +: DATA_W];
            prod_i  = voxel_i * coeff_i;
            acc     = acc + prod_i;
        end
    end

    assign sum_out = acc;

endmodule