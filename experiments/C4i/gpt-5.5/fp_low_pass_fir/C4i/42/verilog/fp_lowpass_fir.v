`timescale 1ns/1ps

module fp_lowpass_fir #(
    parameter TAP_CNT     = 31,
    parameter PIPE_DEPTH  = 0,
    parameter CUTOFF_PPM  = 60000
) (
    input                   clk,
    input                   rst,
    input                   valid_in,
    input   [31:0]          data_in,
    output  reg             valid_out,
    output  [31:0]          data_out
);

    function integer clog2;
        input integer value;
        integer v;
        begin
            v = value - 1;
            clog2 = 0;
            while (v > 0) begin
                v = v >> 1;
                clog2 = clog2 + 1;
            end
        end
    endfunction

    localparam CNT_W      = clog2(TAP_CNT + 1);
    localparam MAX_LEVELS = 7;

    reg [31:0] sample_shift [0:TAP_CNT-1];
    reg [CNT_W-1:0] sample_count;

    integer si;

    always @(posedge clk) begin
        if (rst) begin
            for (si = 0; si < TAP_CNT; si = si + 1) begin
                sample_shift[si] <= 32'h00000000;
            end
            sample_count <= {CNT_W{1'b0}};
            valid_out    <= 1'b0;
        end else begin
            valid_out <= valid_in && (sample_count >= (TAP_CNT-1));

            if (valid_in) begin
                for (si = TAP_CNT-1; si > 0; si = si - 1) begin
                    sample_shift[si] <= sample_shift[si-1];
                end
                sample_shift[0] <= data_in;

                if (sample_count < TAP_CNT[CNT_W-1:0])
                    sample_count <= sample_count + {{(CNT_W-1){1'b0}}, 1'b1};
            end
        end
    end

    wire [TAP_CNT*32-1:0] coeffs_flat;

    lpf_coeff_bank #(
        .TAP_CNT    (TAP_CNT),
        .CUTOFF_PPM (CUTOFF_PPM)
    ) u_coeff_bank (
        .coeffs_flat(coeffs_flat)
    );

    wire [31:0] products [0:TAP_CNT-1];

    genvar gi;
    generate
        for (gi = 0; gi < TAP_CNT; gi = gi + 1) begin : GEN_MULTS
            fp32_mul u_mul (
                .a     (sample_shift[gi]),
                .b     (coeffs_flat[32*gi +: 32]),
                .result(products[gi])
            );
        end
    endgenerate

    wire [31:0] adder_stage [0:MAX_LEVELS][0:TAP_CNT-1];

    generate
        for (gi = 0; gi < TAP_CNT; gi = gi + 1) begin : GEN_STAGE0
            assign adder_stage[0][gi] = products[gi];
        end
    endgenerate

    genvar lev, aj;
    generate
        for (lev = 0; lev < MAX_LEVELS; lev = lev + 1) begin : GEN_ADD_LEVEL
            for (aj = 0; aj < TAP_CNT; aj = aj + 1) begin : GEN_ADD_NODE
                if (aj < ((TAP_CNT + (1 << (lev+1)) - 1) >> (lev+1))) begin : ACTIVE_NODE
                    if (((2*aj + 1) < ((TAP_CNT + (1 << lev) - 1) >> lev))) begin : ADD_PAIR
                        fp32_add u_add (
                            .a     (adder_stage[lev][2*aj]),
                            .b     (adder_stage[lev][2*aj+1]),
                            .result(adder_stage[lev+1][aj])
                        );
                    end else begin : COPY_SINGLE
                        assign adder_stage[lev+1][aj] = adder_stage[lev][2*aj];
                    end
                end else begin : UNUSED_NODE
                    assign adder_stage[lev+1][aj] = 32'h00000000;
                end
            end
        end
    endgenerate

    assign data_out = valid_out ? adder_stage[MAX_LEVELS][0] : 32'h00000000;

endmodule