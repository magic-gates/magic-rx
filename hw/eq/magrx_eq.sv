module magrx_eq #
( parameter int N = 1024
, parameter int ID = $clog2(N)
, parameter int DW = 16
, parameter int PD = 6

, parameter int II = PD
, parameter int FI = ID - PD
)
( input  logic                 clk

, input  logic                 i_ce
, input  logic        [ID-1:0] i_idx
, input  logic signed [DW-1:0] i_re
, input  logic signed [DW-1:0] i_im

, output logic        [ID-1:0] o_idx
, output logic signed [DW-1:0] o_re
, output logic signed [DW-1:0] o_im
);

    // 0: Bit-reverse and split index

    logic [ID-1:0] idx_0;
    wire [II-1:0] ii_0;
    wire [FI-1:0] fi_0;

    assign ii_0 = idx_0[ID-1-:II];
    assign fi_0 = idx_0[FI-1:0];

    always_comb begin
        for (int i = 0; i < ID; i++) begin
            idx_0[ID - i - 1] = i_idx[i];
        end
    end

    // 2 <2>: LS estimate

    logic [II-1:0] ii_2;
    logic [FI-1:0] fi_2;

    logic signed [DW-1:0] h_re_2 [2];
    logic signed [DW-1:0] h_im_2 [2];

    logic signed [DW-1:0] re_2, im_2;

    magrx_eq_ls #
    ( .N(N)
    , .DW(DW)
    , .PD(PD)
    ) u_ls
    ( .clk(clk)
    , .i_ce(i_ce)

    , .i_ii(ii_0)
    , .i_fi(fi_0)
    , .i_re(i_re)
    , .i_im(i_im)

    , .o_re(re_2)
    , .o_im(im_2)

    , .o_h_re(h_re_2)
    , .o_h_im(h_im_2)
    );

    magrx_pla #(ID, 2) u_pla_ls
        (clk, i_ce, {ii_0, fi_0}, {ii_2, fi_2});

    // 4 <2>: Linear interpolation

    logic [ID-1:0] idx_4;

    logic signed [DW-1:0] h_re_4, h_im_4;
    logic signed [DW-1:0] re_4, im_4;

    magrx_eq_lerp #(DW, FI) u_lerp_re
    ( .clk(clk)
    , .i_ce(i_ce)

    , .i_fi(fi_2)
    , .i_ps(h_re_2)

    , .o_value(h_re_4)
    );

    magrx_eq_lerp #(DW, FI) u_lerp_im
    ( .clk(clk)
    , .i_ce(i_ce)

    , .i_fi(fi_2)
    , .i_ps(h_im_2)

    , .o_value(h_im_4)
    );

    magrx_pla #(DW*2+ID, 2) u_pla_lerp
        (clk, i_ce, {re_2, im_2, ii_2, fi_2}, {re_4, im_4, idx_4});

    // 9 <5>: Equalization

    wire signed [DW*2:0] dbg_mag = (h_re_4 * h_re_4) + (h_im_4 * h_im_4);

    logic signed [DW-1:0] re_9, im_9;
    logic [ID-1:0] idx_9;

    assign o_idx = idx_9;
    assign o_re = re_9;
    assign o_im = im_9;

    magrx_eq_zf #(DW) u_zf
    ( .clk(clk)

    , .i_ce(i_ce)

    , .i_d_re(re_4)
    , .i_d_im(im_4)

    , .i_h_re(h_re_4)
    , .i_h_im(h_im_4)

    , .o_re(re_9)
    , .o_im(im_9)
    );

    magrx_pla #(ID, 5) u_zf_pla
        (clk, i_ce, idx_4, idx_9);

endmodule
