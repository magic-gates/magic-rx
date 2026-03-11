// Copyright (c) 2026, Magic Gates
// License: GPLv3
// Author: Danil Karpenko

module magrx
( input  logic               clk
, input  logic               arst

, input  logic signed [11:0] i_re
, input  logic signed [11:0] i_im

, output logic               o_ce
, output logic        [ 9:0] o_idx
, output logic signed [15:0] o_re
, output logic signed [15:0] o_im
);

    logic rst;

    logic [10:0] sync_idx;
    logic [9:0] fft_idx;
    logic signed [11:0] sync_re, sync_im;
    logic signed [15:0] fft_re, fft_im;

    logic ce;

    // Equalizer is Work in Progress,
    // use fft output directly for now

    assign o_ce = ce;
    assign o_idx = fft_idx;
    assign o_re = fft_re;
    assign o_im = fft_im;

    magrx_rst u_rst (clk, arst, rst);

    magrx_sync #
    ( .DW(12)
    , .LEN(1024)
    , .CP(64)
    , .SF(4)
    , .DB(8)
    ) u_sync
    ( .clk(clk)
    , .rst(rst)

    , .i_re(i_re)
    , .i_im(i_im)

    , .o_idx(sync_idx)
    , .o_re(sync_re)
    , .o_im(sync_im)
    );

    magrx_fft u_fft
    ( .clk(clk)

    , .i_idx(sync_idx)
    , .i_re(sync_re)
    , .i_im(sync_im)

    , .o_ce(ce)
    , .o_idx(fft_idx)
    , .o_re(fft_re)
    , .o_im(fft_im)
    );

endmodule
