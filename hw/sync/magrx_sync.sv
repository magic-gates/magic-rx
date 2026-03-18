module magrx_sync #
// Data width
( parameter int DW = 12
// Length of the OFDM symbol
, parameter int LEN = 1024
// Length of the Cyclic Prefix
, parameter int CP = 64

// Sampling index width
, parameter int ID = $clog2(LEN + CP)
)
( input  logic                 clk
, input  logic                 rst

, input  logic signed [DW-1:0] i_re
, input  logic signed [DW-1:0] i_im

, output logic signed [DW-1:0] o_re
, output logic signed [DW-1:0] o_im

// FFT sampling index
, output logic        [ID-1:0] o_idx
);

    localparam int METRIC_WIDTH = $clog2(CP) + 2;

    logic signed [METRIC_WIDTH-1:0] m_re, m_im;

    logic [ID-1:0] m_idx;

    logic d_valid;
    logic [ID-1:0] d_idx;
    logic signed [METRIC_WIDTH-1:0] d_re, d_im;

    logic err_valid;
    logic [ID-1:0] err;

    logic f_valid;
    logic signed [15:0] f_err;

    logic l_valid;
    logic signed [15:0] l_err;

    magrx_sync_mixer #
    ( .DW(DW)
    , .AW(16)
    , .DV($clog2(LEN))
    ) u_mixer
    ( .clk(clk)
    , .rst(rst)

    , .i_re(i_re)
    , .i_im(i_im)

    , .i_valid(l_valid)
    , .i_err(l_err)

    , .o_re(o_re)
    , .o_im(o_im)
    );

    magrx_sync_counter #
    ( .LEN(LEN)
    , .CP(CP)
    ) u_counter
    ( .clk(clk)

    , .o_idx(o_idx)

    , .i_err(err)
    , .i_err_valid(err_valid)
    );

    magrx_sync_metric #
    ( .LEN(LEN)
    , .CP(CP)
    ) u_metric
    ( .clk(clk)

    , .i_idx(o_idx)
    , .i_re(o_re[DW-1])
    , .i_im(o_im[DW-1])

    , .o_idx(m_idx)
    , .o_re(m_re)
    , .o_im(m_im)
    );

    magrx_sync_detector #
    ( .W(METRIC_WIDTH)
    , .ID(ID)
    , .L(64)
    , .ET(32)
    , .LT(16)
    ) u_detector
    ( .clk(clk)
    , .rst(rst)

    , .i_idx(m_idx)
    , .i_re(m_re)
    , .i_im(m_im)

    , .o_valid(d_valid)
    , .o_idx(d_idx)
    , .o_re(d_re)
    , .o_im(d_im)
    );

    magrx_sync_filter #
    ( .LEN(LEN)
    , .CP(CP)
    ) u_filter
    ( .clk(clk)

    , .i_valid(d_valid)
    , .i_idx(d_idx)

    , .o_valid(err_valid)
    , .o_err(err)
    );

    magrx_sync_cordic #
    ( .DW(METRIC_WIDTH)
    , .AW(16)
    , .S(15)
    ) u_cordic
    ( .clk(clk)
    , .rst(rst)

    , .i_load(d_valid)
    , .i_re(d_re)
    , .i_im(d_im)

    , .o_valid(f_valid)
    , .o_angle(f_err)
    );

    magrx_sync_loop #
    ( .DW(16)
    , .KP(3)
    , .KI(8)
    ) u_loop
    ( .clk(clk)
    , .rst(rst)

    , .i_valid(f_valid)
    , .i(f_err)

    , .o_valid(l_valid)
    , .o(l_err)
    );

endmodule
