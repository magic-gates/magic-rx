module zerochan_rx
( input  logic               clk
, input  logic               arst

, input  logic signed [11:0] i_re
, input  logic signed [11:0] i_im

, output logic               o_valid
, output logic        [ 9:0] o_idx
, output logic signed [15:0] o_re
, output logic signed [15:0] o_im
);

    logic rst;

    logic [10:0] sync_idx;
    logic [9:0] fft_idx, comm_idx, eq_idx;
    logic signed [11:0] sync_re, sync_im;
    logic signed [21:0] fft_re, fft_im;
    logic signed [15:0] comm_re, comm_im;
    logic signed [15:0] eq_re, eq_im;

    logic eq_valid;

    logic ce;

    always_ff @(posedge clk) begin
        if (ce) begin
            o_valid <= eq_valid;
            o_idx <= eq_idx;
            o_re <= eq_re;
            o_im <= eq_im;
        end else begin
            o_valid <= 1'b0;
        end
    end

    magrx_rst u_rst (clk, arst, rst);

    zerochan_rx_sync #
    ( .DW(12)
    , .N(1024)
    , .CP(61)
    ) u_sync
    ( .clk(clk)
    , .rst(rst)

    , .i_re(i_re)
    , .i_im(i_im)

    , .o_idx(sync_idx)
    , .o_re(sync_re)
    , .o_im(sync_im)
    );

    zerochan_lib_fft_driver #
    ( .INPUT_WIDTH(12)
    ) u_fft
    ( .clk(clk)

    , .i_idx(sync_idx)
    , .i_re(sync_re)
    , .i_im(sync_im)

    , .o_ce(ce)
    , .o_idx(fft_idx)
    , .o_re(fft_re)
    , .o_im(fft_im)
    );

    zerochan_rx_commutator #(1024, 22, 16) u_commutator
    ( .clk(clk)

    , .i_ce(ce)
    , .i_idx(fft_idx)
    , .o_idx(comm_idx)

    , .i_re(fft_re)
    , .i_im(fft_im)

    , .o_re(comm_re)
    , .o_im(comm_im)
    );

    zerochan_rx_eq #(1024) u_eq
    ( .clk(clk)

    , .i_ce(ce)
    , .i_idx(comm_idx)
    , .i_re(comm_re)
    , .i_im(comm_im)

    , .o_valid(eq_valid)
    , .o_idx(eq_idx)
    , .o_re(eq_re)
    , .o_im(eq_im)
    );

endmodule : zerochan_rx
