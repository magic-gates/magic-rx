module magrx_fft_rdx4 #
( parameter int ID = 2
, parameter int DW = 16
, parameter int B1 = 1
, parameter int B2 = 0
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

    logic signed [DW:0] bf1_re, bf1_im;

    logic [ID-1:0] bf1_idx;

    magrx_fft_bf1 #(ID, B1, DW + 0) u_bf1
        (clk, i_ce, i_idx, bf1_idx, i_re, i_im, bf1_re, bf1_im);

    magrx_fft_bf2 #(ID, B2, DW + 1) u_bf2
        (clk, i_ce, bf1_idx, o_idx, bf1_re, bf1_im, o_re, o_im);

endmodule
