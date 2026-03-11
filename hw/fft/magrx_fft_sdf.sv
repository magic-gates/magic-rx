module magrx_fft_sdf #
( parameter int N  = 4
, parameter int S  = 0
, parameter int DW = 16
, parameter int TW = 16
, parameter bit IV = 0

, parameter int ID = $clog2(N)
, parameter int LV = $clog2(N) - (S * 2) - 1
)
( input  logic                 clk

, input  logic                 i_ce
, input  logic        [ID-1:0] i_idx
, output logic        [ID-1:0] o_idx

, input  logic signed [DW-1:0] i_re
, input  logic signed [DW-1:0] i_im

, output logic signed [DW+1:0] o_re
, output logic signed [DW+1:0] o_im
);

    logic signed [DW+1:0] re_0, im_0;
    logic [ID-1:0] idx_0;

    magrx_fft_rdx4 #(ID, DW, LV, LV - 1) u_rdx4
        (clk, i_ce, i_idx, idx_0, i_re, i_im, re_0, im_0);

    generate if (S < $clog2(N) / 2 - 1) begin : gen_twiddle
        magrx_fft_twiddle #(N, S, DW + 2, TW, IV) u_tw
            (clk, i_ce, idx_0, o_idx, re_0, im_0, o_re, o_im);
    end else begin
        assign {o_re, o_im} = {re_0, im_0};
        assign o_idx = idx_0;
    end endgenerate

endmodule
