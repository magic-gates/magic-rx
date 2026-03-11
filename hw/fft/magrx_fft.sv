module magrx_fft
( input                clk

, input         [10:0] i_idx

, input  signed [11:0] i_re
, input  signed [11:0] i_im

, output               o_ce
, output        [ 9:0] o_idx
, output signed [15:0] o_re
, output signed [15:0] o_im
);

    logic ce;
    logic [9:0] t_idx, f_idx;

    logic signed [15:0] t_re, t_im;

    assign o_ce = ce;

    always @(posedge clk) begin
        ce <= ~i_idx[10];
        t_idx <= i_idx[9:0];
        t_re <= {i_re, 4'd0};
        t_im <= {i_im, 4'd0};
    end

    magrx_fft_1024 #(16, 16) u_fft_1024
    ( .clk(clk)

    , .i_ce(ce)
    , .i_idx(t_idx)
    , .o_idx(o_idx)

    , .i_re(t_re)
    , .i_im(t_im)

    , .o_re(o_re)
    , .o_im(o_im)
    );

endmodule
