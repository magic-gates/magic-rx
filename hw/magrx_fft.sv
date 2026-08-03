module magrx_fft
( input  logic               clk

, input  logic        [10:0] i_idx

, input  logic signed [11:0] i_re
, input  logic signed [11:0] i_im

, output logic               o_ce
, output logic        [ 9:0] o_idx
, output logic signed [21:0] o_re
, output logic signed [21:0] o_im
);

    logic ce;
    logic [9:0] t_idx, f_idx;

    logic signed [11:0] t_re, t_im;
    logic signed [21:0] f_re, f_im;

    assign o_ce = ce;

    assign o_re = f_re;
    assign o_im = f_im;
    assign o_idx = f_idx;

    always @(posedge clk) begin
        ce <= ~i_idx[10];
        t_idx <= i_idx[9:0];
        t_re <= i_re;
        t_im <= i_im;
    end

    magrx_fft_1024 #
    ( .IW(12)
    , .OW(22)
    , .TW(16)
    ) u_fft_1024
    ( .clk(clk)

    , .i_ce(ce)
    , .i_idx(t_idx)
    , .o_idx(f_idx)

    , .i_re(t_re)
    , .i_im(t_im)

    , .o_re(f_re)
    , .o_im(f_im)
    );

endmodule

module magrx_fft_1024 #
( parameter int IW = 12
, parameter int OW = 22
, parameter int TW = 16
)
( input  logic                 clk

, input  logic                 i_ce
, input  logic        [   9:0] i_idx
, output logic        [   9:0] o_idx

, input  logic signed [IW-1:0] i_re
, input  logic signed [IW-1:0] i_im

, output logic signed [OW-1:0] o_re
, output logic signed [OW-1:0] o_im
);

    localparam int N = 1024;

    logic signed [IW+1:0] re_0, im_0;
    logic signed [IW+3:0] re_1, im_1;
    logic signed [IW+5:0] re_2, im_2;
    logic signed [IW+7:0] re_3, im_3;
    logic signed [IW+9:0] re_4, im_4;

    logic [9:0] idx_0, idx_1, idx_2, idx_3, idx_4;

    magrx_fft_sdf #(N, 0, IW + 0, TW)
        u_sdf0 (clk, i_ce, i_idx, idx_0, i_re, i_im, re_0, im_0);

    magrx_fft_sdf #(N, 1, IW + 2, TW)
        u_sdf1 (clk, i_ce, idx_0, idx_1, re_0, im_0, re_1, im_1);

    magrx_fft_sdf #(N, 2, IW + 4, TW)
        u_sdf2 (clk, i_ce, idx_1, idx_2, re_1, im_1, re_2, im_2);

    magrx_fft_sdf #(N, 3, IW + 6, TW)
        u_sdf3 (clk, i_ce, idx_2, idx_3, re_2, im_2, re_3, im_3);

    magrx_fft_sdf #(N, 4, IW + 8, TW)
        u_sdf4 (clk, i_ce, idx_3, idx_4, re_3, im_3, re_4, im_4);

    always_ff @(posedge clk) begin
        if (i_ce) begin
            o_re <= re_4;
            o_im <= im_4;
            o_idx <= idx_4;
        end
    end

    // magrx_fft_round #(IW + 10, OW)
    //     u_round_re (clk, i_ce, re_4, o_re);

    // magrx_fft_round #(IW + 10, OW)
    //     u_round_im (clk, i_ce, im_4, o_im);

endmodule

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

    logic [ID-1:0] idx_1, idx_2, idx_3, idx_4;

    always_ff @(posedge clk) begin
        if (i_ce) begin
            {r_re, r_im} <= {i_re, i_im};
            o_idx <= i_idx - ID'(4);
        end
    end

    magrx_fft_rom #(N, S, TW, IV) u_rom
        (clk, i_ce, i_idx[AW-1:0], w_re, w_im);

    magrx_fft_rotate #(DW, TW) u_rotate
        (clk, i_ce, r_re, r_im, w_re, w_im, o_re, o_im);

endmodule

module magrx_fft_bf1 #
( parameter int ID = 0
, parameter int LV = 0
, parameter int DW = 16
)
( input  logic                 clk

, input  logic                 i_ce
, input  logic        [ID-1:0] i_idx
, output logic        [ID-1:0] o_idx

, input  logic signed [DW-1:0] i_re
, input  logic signed [DW-1:0] i_im

, output logic signed [  DW:0] o_re
, output logic signed [  DW:0] o_im
);

    logic signed [DW:0] f_re, f_im;
    logic signed [DW:0] d_re, d_im;

    wire mux = i_idx[LV];

    always_comb begin
        if (mux) begin
            f_re = d_re - i_re;
            f_im = d_im - i_im;
        end else begin
            f_re = i_re;
            f_im = i_im;
        end
    end

    always_ff @(posedge clk) begin
        if (i_ce) begin
            if (mux) begin
                o_re <= d_re + i_re;
                o_im <= d_im + i_im;
            end else begin
                o_re <= d_re;
                o_im <= d_im;
            end
        end
    end

    always_ff @(posedge clk) begin
        if (i_ce) begin
            o_idx <= i_idx - ID'(1 << LV);
        end
    end

    magrx_fft_delay #(LV, DW + 1) u_delay
        (clk, i_ce, i_idx[LV:0], f_re, f_im, d_re, d_im);

endmodule

module magrx_fft_bf2 #
( parameter int ID = 0
, parameter int LV = 0
, parameter int DW = 16
)
( input  logic                 clk

, input  logic                 i_ce
, input  logic        [ID-1:0] i_idx
, output logic        [ID-1:0] o_idx

, input  logic signed [DW-1:0] i_re
, input  logic signed [DW-1:0] i_im

, output logic signed [  DW:0] o_re
, output logic signed [  DW:0] o_im
);

    logic mux, swap;

    logic signed [DW:0] f_re, f_im;
    logic signed [DW:0] d_re, d_im;

    assign mux  = i_idx[LV];
    assign swap = i_idx[LV+1] & i_idx[LV];

    always_comb begin
        if (mux) begin
            if (swap) begin
                f_re = d_re - i_im;
                f_im = d_im + i_re;
            end else begin
                f_re = d_re - i_re;
                f_im = d_im - i_im;
            end
        end else begin
            f_re = i_re;
            f_im = i_im;
        end
    end

    always_ff @(posedge clk) begin
        if (i_ce) begin
            if (mux) begin
                if (swap) begin
                    o_re <= d_re + i_im;
                    o_im <= d_im - i_re;
                end else begin
                    o_re <= d_re + i_re;
                    o_im <= d_im + i_im;
                end
            end else begin
                o_re <= d_re;
                o_im <= d_im;
            end
        end
    end

    always_ff @(posedge clk) begin
        if (i_ce) begin
            o_idx <= i_idx - ID'(1 << LV);
        end
    end

    magrx_fft_delay #(LV, DW + 1) u_delay
        (clk, i_ce, i_idx[LV:0], f_re, f_im, d_re, d_im);

endmodule

module magrx_fft_delay #
( parameter int LV = 0
, parameter int DW = 16
)
( input  logic                 clk

, input  logic                 i_ce
, input  logic        [  LV:0] idx

, input  logic signed [DW-1:0] i_re
, input  logic signed [DW-1:0] i_im

, output logic signed [DW-1:0] o_re
, output logic signed [DW-1:0] o_im
);

    generate if (LV > 0) begin : gen_delay
        logic [DW*2-1:0] buffer [1 << LV];
        wire [LV-1:0] addr = idx[LV-1:0];

        always_ff @(posedge clk) begin
            if (i_ce) begin
                buffer[addr] <= {i_re, i_im};
                {o_re, o_im} <= buffer[addr + LV'(1)];
            end
        end
    end else begin
        always_ff @(posedge clk) begin
            if (i_ce) begin
                {o_re, o_im} <= {i_re, i_im};
            end
        end
    end endgenerate

endmodule

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

    magrx_round #(DW+TW, TW-1, 1) u_round_re
        (clk, i_ce, r_re, o_re);

    magrx_round #(DW+TW, TW-1, 1) u_round_im
        (clk, i_ce, r_im, o_im);

endmodule

module magrx_fft_rom #
( parameter int N  = 16
, parameter int S  = 0
, parameter int W  = 16
, parameter bit IV = 0

, parameter int AW = $clog2(N) - (S * 2)
)
( input  logic                 clk

, input  logic                 ce
, input  logic        [AW-1:0] addr

, output logic signed [ W-1:0] re
, output logic signed [ W-1:0] im
);

    localparam int A = N / (2 ** (2 + 2 * S));
    localparam int D = N / (4 ** S);

    logic [W*2-1:0] rom [1 << AW];

    always_ff @(posedge clk) begin
        if (ce) begin
            {re, im} <= rom[addr];
        end
    end

    initial begin : init_rom
        int c, x;

        for (c = 0; c < 4; c++) begin
            var automatic real theta;
            var automatic int s, l, k, cos, sin;

            s = {c[0], c[1]} * (4 ** S);
            l = c * A;

            for (x = c * A; x < c * A + A; x++) begin
                k = s * (x - l);
                theta = $atan(1.0) * 8 * (real'(k) / real'(N));

                cos = scale($cos(IV ? theta : -theta));
                sin = scale($sin(IV ? theta : -theta));

                rom[x] = {cos[W-1:0], sin[W-1:0]};
            end
        end
    end

    function automatic signed [W-1:0] scale(real x);
        localparam int MAX = ((1 << W - 1) - 1);
        localparam int MIN = (0 - (1 << W - 1));

        var automatic real scaled = x * (1 << W - 1);
        var automatic int v = $rtoi(scaled >= 0.0 ? scaled + 0.5 : scaled - 0.5);

        if (v > MAX) v = MAX;
        if (v < MIN) v = MIN;

        return v;
    endfunction

endmodule

module magrx_fft_round #
( parameter int IW = 16
, parameter int FD = 16
, parameter bit SG = 1
, parameter int OW = IW - FD - SG
)
( input  logic                 clk

, input  logic                 ce

, input  logic signed [IW-1:0] i
, output logic signed [OW-1:0] o
);

    wire sign    =  i[IW-1];

    wire lsb     =  i[FD];
    wire halfway =  i[FD-1];
    wire sticky  = |i[FD-2:0];

    wire round_up = halfway && (sticky || lsb);

    wire signed [OW-1:0] i_trunc = $signed(i[IW-1:FD]);
    wire signed [OW:0] sum = i_trunc + round_up;
    wire overflow = ~sign & sum[OW];

    always_ff @(posedge clk) begin
        if (ce) begin
            o <= overflow ? {1'b0, {(OW-1){1'b1}}} : sum[OW-1:0];
        end
    end

endmodule : magrx_fft_round
