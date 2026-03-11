module magrx_fft_1024 #
( parameter int DW = 16
, parameter int TW = 16
)
( input  logic                 clk

, input  logic                 i_ce
, input  logic        [   9:0] i_idx
, output logic        [   9:0] o_idx

, input  logic signed [DW-1:0] i_re
, input  logic signed [DW-1:0] i_im

, output logic signed [DW-1:0] o_re
, output logic signed [DW-1:0] o_im
);

    localparam int N = 1024;

    logic signed [DW+1:0] re_0, im_0;
    logic signed [DW+3:0] re_1, im_1;
    logic signed [DW+5:0] re_2, im_2;
    logic signed [DW+7:0] re_3, im_3;
    logic signed [DW+9:0] re_4, im_4;

    logic [9:0] idx_0, idx_1, idx_2, idx_3, idx_4;

    always_ff @(posedge clk) begin
        if (i_ce) begin
            o_idx <= idx_4;
        end
    end

    magrx_fft_sdf #(N, 0, DW + 0, TW)
        u_sdf0 (clk, i_ce, i_idx, idx_0, i_re, i_im, re_0, im_0);

    magrx_fft_sdf #(N, 1, DW + 2, TW)
        u_sdf1 (clk, i_ce, idx_0, idx_1, re_0, im_0, re_1, im_1);

    magrx_fft_sdf #(N, 2, DW + 4, TW)
        u_sdf2 (clk, i_ce, idx_1, idx_2, re_1, im_1, re_2, im_2);

    magrx_fft_sdf #(N, 3, DW + 6, TW)
        u_sdf3 (clk, i_ce, idx_2, idx_3, re_2, im_2, re_3, im_3);

    magrx_fft_sdf #(N, 4, DW + 8, TW)
        u_sdf4 (clk, i_ce, idx_3, idx_4, re_3, im_3, re_4, im_4);

    always_ff @(posedge clk) begin
        if (i_ce) begin
            o_re <= re_4 >>> 4;
            o_im <= im_4 >>> 4;
        end
    end

    // magrx_fft_round #(DW + 10, DW)
    //     u_round_re (clk, i_ce, re_4, o_re);

    // magrx_fft_round #(DW + 10, DW)
    //     u_round_im (clk, i_ce, im_4, o_im);

endmodule
