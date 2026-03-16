module magrx_eq_zf #
( parameter int DW = 16
)
( input  logic                 clk

, input  logic                 i_ce

, input  logic signed [DW-1:0] i_d_re
, input  logic signed [DW-1:0] i_d_im

, input  logic signed [DW-1:0] i_h_re
, input  logic signed [DW-1:0] i_h_im

, output logic signed [DW-1:0] o_re
, output logic signed [DW-1:0] o_im
);

    wire signed [DW*2:0] mag_0 = (i_h_re * i_h_re) + (i_h_im * i_h_im);
    wire signed [DW*2:0] re_0 = (i_d_re * i_h_re) + (i_d_im * i_h_im);
    wire signed [DW*2:0] im_0 = (i_d_im * i_h_re) - (i_d_re * i_h_im);

    // wire [DW-1:0] h_re_abs = i_h_re < 0 ? -i_h_re : i_h_re;
    // wire [DW-1:0] h_im_abs = i_h_im < 0 ? -i_h_im : i_h_im;

    // wire [DW-1:0] h_max_0 = h_re_abs > h_im_abs ? h_re_abs : h_im_abs;
    // wire [DW-1:0] h_min_0 = h_re_abs < h_im_abs ? h_re_abs : h_im_abs;

    // 1: Partial Equalization and magnitude

    logic [DW-1:0] mag_1;

    logic signed [DW-1:0] re_1, im_1;

    always_ff @(posedge clk) begin
        if (i_ce) begin
            mag_1 <= mag_0[DW*2-2:DW-1];
            // mag_1 <= h_max_0 + (h_min_0 >> 2) + (h_min_0 >> 3);

            re_1 <= re_0 >>> (DW-1);
            im_1 <= im_0 >>> (DW-1);
        end
    end

    // (2 .. 4): Reciprocal

    logic [$clog2(DW)-1:0] zc_1;
    wire [DW-1:0] den_1 = (mag_1 << zc_1);

    logic [$clog2(DW)-1:0] zc_4;
    logic [DW+1:0] rec_4;
    logic signed [DW-1:0] re_4, im_4;

    always_comb begin
        zc_1 = DW - 1;

        for (int i = DW - 1; i >= 0; i--) begin
            if (mag_1[i]) begin
                zc_1 = DW - 1 - i;
                break;
            end
        end
    end

    magrx_eq_reciprocal #(DW) u_reciprocal
    ( .clk(clk)

    , .i_ce(i_ce)
    , .i_den(den_1)

    , .o_rec(rec_4)
    );

    magrx_pla #(DW*2 + $clog2(DW), 3) u_pla_rec
        (clk, i_ce, {re_1, im_1, zc_1}, {re_4, im_4, zc_4});

    // 5: Scale

    localparam logic [16:0] ROUND = 1 << 17;

    wire signed [18+16-1:0] scale_4 = rec_4 << zc_4;
    wire signed [34+16-1:0] prod_re_4 = re_4 * $signed({1'b0, scale_4});
    wire signed [34+16-1:0] prod_im_4 = im_4 * $signed({1'b0, scale_4});

    always_ff @(posedge clk) begin
        if (i_ce) begin
            o_re <= (prod_re_4[18+16] ? prod_re_4 - ROUND : prod_re_4 + ROUND) >>> 18;
            o_im <= (prod_im_4[18+16] ? prod_im_4 - ROUND : prod_im_4 + ROUND) >>> 18;
        end
    end

endmodule
