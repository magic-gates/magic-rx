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
    logic [9:0] fft_idx, eq_idx;
    logic signed [11:0] sync_re, sync_im;
    logic signed [15:0] fft_re, fft_im;
    logic signed [15:0] eq_re, eq_im;

    logic ce;

    assign o_ce = ce;
    assign o_idx = eq_idx;
    assign o_re = eq_re;
    assign o_im = eq_im;

    magrx_rst u_rst (clk, arst, rst);

    magrx_sync #
    ( .DW(12)
    , .LEN(1024)
    , .CP(64)
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

    magrx_eq u_eq
    ( .clk(clk)

    , .i_ce(ce)
    , .i_idx(fft_idx)
    , .i_re(fft_re)
    , .i_im(fft_im)

    , .o_idx(eq_idx)
    , .o_re(eq_re)
    , .o_im(eq_im)
    );

endmodule
