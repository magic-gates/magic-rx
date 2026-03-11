module magrx_fft_twiddle #
( parameter int N  = 16
, parameter int S  = 0
, parameter int DW = 16
, parameter int TW = 16
, parameter bit IV = 0

, parameter int ID = $clog2(N)
, parameter int AW = $clog2(N) - (S * 2)
)
( input  logic                 clk

, input  logic                 i_ce
, input  logic        [ID-1:0] i_idx
, output logic        [ID-1:0] o_idx

, input  logic signed [DW-1:0] i_re
, input  logic signed [DW-1:0] i_im

, output logic signed [DW-1:0] o_re
, output logic signed [DW-1:0] o_im
);

    logic signed [DW-1:0] r_re, r_im;
    logic signed [TW-1:0] w_re, w_im;

    always_ff @(posedge clk) begin
        if (i_ce) begin
            {r_re, r_im} <= {i_re, i_im};
            o_idx <= i_idx - ID'(3);
        end
    end

    magrx_fft_rom #(N, S, TW, IV) u_rom
        (clk, i_ce, i_idx[AW-1:0], w_re, w_im);

    magrx_fft_rotate #(DW, TW) u_rotate
        (clk, i_ce, r_re, r_im, w_re, w_im, o_re, o_im);

endmodule
