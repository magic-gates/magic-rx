module magrx_fft_rotate #
( parameter int DW = 16
, parameter int TW = 16
)
( input  logic                 clk

, input  logic                 i_ce

, input  logic signed [DW-1:0] i_re
, input  logic signed [DW-1:0] i_im

, input  logic signed [TW-1:0] w_re
, input  logic signed [TW-1:0] w_im

, output logic signed [DW-1:0] o_re
, output logic signed [DW-1:0] o_im
);

    logic signed [DW:0] s1;
    logic signed [TW:0] s2;
    logic signed [DW:0] s3;

    logic signed [TW-1:0] w_re_0, w_im_0;
    logic signed [DW-1:0] i_im_0;

    always_ff @(posedge clk) begin
        if (i_ce) begin
            s1 <= i_re - i_im;
            s2 <= w_re - w_im;
            s3 <= i_re + i_im;

            w_re_0 <= w_re;
            w_im_0 <= w_im;
            i_im_0 <= i_im;
        end
    end

    logic signed [DW+TW:0] p1, p2, p3;

    always_ff @(posedge clk) begin
        if (i_ce) begin
            p1 <= s1 * w_re_0;
            p2 <= s2 * i_im_0;
            p3 <= s3 * w_im_0;
        end
    end

    logic signed [DW+TW-1:0] r_re, r_im;

    always_ff @(posedge clk) begin
        if (i_ce) begin
            r_re <= (DW+TW)'(p1 + p2);
            r_im <= (DW+TW)'(p2 + p3);
        end
    end

    magrx_fft_round #(DW+TW, TW-1, 1) u_round_re
        (clk, i_ce, r_re, o_re);

    magrx_fft_round #(DW+TW, TW-1, 1) u_round_im
        (clk, i_ce, r_im, o_im);

endmodule
