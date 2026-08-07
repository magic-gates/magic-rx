module zerochan_rx_eq #
( parameter int FFT_N = 1024
, parameter int PILOT_SPACING = 16
, parameter int PILOT_OFFSET = 8
, parameter int INDEX_WIDTH = $clog2(FFT_N)
)
( input  logic                   clk
, input  logic                   i_ce

, input  logic [INDEX_WIDTH-1:0] i_idx
, input  logic [           15:0] i_re
, input  logic [           15:0] i_im

, output logic                   o_valid
, output logic [INDEX_WIDTH-1:0] o_idx
, output logic [           15:0] o_re
, output logic [           15:0] o_im
);

    localparam int OFFSET_WIDTH = $clog2(PILOT_SPACING);

    logic active, pilot;
    logic [INDEX_WIDTH-1:0] ls_idx;
    logic [OFFSET_WIDTH-1:0] pilot_rel;
    logic [31:0] p [0:3];
    logic [15:0] ls_re, ls_im;

    logic no_p0, no_p3;

    zerochan_rx_eq_ls #
    ( .FFT_N(FFT_N)
    , .PILOT_SPACING(PILOT_SPACING)
    , .PILOT_OFFSET(PILOT_OFFSET)
    , .DATA_P(/*488*/488)
    , .DATA_N(/*536*/536)
    ) u_ls
    ( .clk(clk)
    , .i_ce(i_ce)

    , .i_idx(i_idx)
    , .i_re(i_re)
    , .i_im(i_im)

    , .o_idx(ls_idx)
    , .o_active(active)
    , .o_pilot(pilot)
    , .o_pilot_rel(pilot_rel)

    , .o_no_p0(no_p0)
    , .o_no_p3(no_p3)

    , .o_p(p)

    , .o_re(ls_re)
    , .o_im(ls_im)
    );

    logic signed [15:0] h_re, h_im;
    wire [32:0] h_dbg = (h_re * h_re) + (h_im * h_im);

    zerochan_rx_eq_spline_5 #(16, 4) u_spline_re
    ( .clk(clk)
    , .i_ce(i_ce)

    , .i_frac(pilot_rel)

    , .i_no_p0(no_p0)
    , .i_no_p3(no_p3)

    , .i_p0(p[0][31:16])
    , .i_p1(p[1][31:16])
    , .i_p2(p[2][31:16])
    , .i_p3(p[3][31:16])

    , .o_val(h_re)
    );

    zerochan_rx_eq_spline_5 #(16, 4) u_spline_im
    ( .clk(clk)
    , .i_ce(i_ce)

    , .i_frac(pilot_rel)

    , .i_no_p0(no_p0)
    , .i_no_p3(no_p3)

    , .i_p0(p[0][15:0])
    , .i_p1(p[1][15:0])
    , .i_p2(p[2][15:0])
    , .i_p3(p[3][15:0])

    , .o_val(h_im)
    );

    logic signed [15:0] ls_re_1, ls_im_1;
    logic signed [15:0] ls_re_2, ls_im_2;
    logic signed [15:0] ls_re_3, ls_im_3;
    logic signed [15:0] ls_re_4, ls_im_4;
    logic signed [15:0] d_re, d_im;

    logic [INDEX_WIDTH-1:0] idx_1, idx_2, idx_3, idx_4, idx_5;
    logic valid_1, valid_2, valid_3, valid_4, valid_5;

    always_ff @(posedge clk) begin
        if (i_ce) begin
            {ls_re_1, ls_im_1} <= {ls_re, ls_im};
            {ls_re_2, ls_im_2} <= {ls_re_1, ls_im_1};
            {ls_re_3, ls_im_3} <= {ls_re_2, ls_im_2};
            {ls_re_4, ls_im_4} <= {ls_re_3, ls_im_3};
            {d_re, d_im} <= {ls_re_4, ls_im_4};

            idx_1 <= ls_idx;
            idx_2 <= idx_1;
            idx_3 <= idx_2;
            idx_4 <= idx_3;
            idx_5 <= idx_4;

            valid_1 <= active & ~pilot;
            valid_2 <= valid_1;
            valid_3 <= valid_2;
            valid_4 <= valid_3;
            valid_5 <= valid_4;
        end
    end

    zerochan_lib_mult_4 #
    ( .A_WIDTH(16)
    , .B_WIDTH(16)
    , .ROUND(9)
    , .CONJ(1'b1)
    ) u_mult
    ( .clk(clk)
    , .ce(i_ce)

    , .a_re(d_re)
    , .a_im(d_im)

    , .b_re(h_re)
    , .b_im(h_im)

    , .o_re(p_re)
    , .o_im(p_im)
    );

    // Q3.21
    logic signed [23:0] p_re, p_im;
    logic signed [23:0] p_re_1, p_im_1;

    always_ff @(posedge clk) begin
        if (i_ce) begin
            {p_re_1, p_im_1} <= {p_re, p_im};
        end
    end

    logic [4:0] k;
    logic [17:0] rec; // Q2.16

    zerochan_rx_eq_scale_5 u_scale
    ( .clk(clk)
    , .i_ce(i_ce)

    , .i_re(h_re)
    , .i_im(h_im)

    , .o_k(k)
    , .o_rec(rec)
    );

    logic [INDEX_WIDTH-1:0] idx_6, idx_7, idx_8, idx_9, idx_10;
    logic valid_6, valid_7, valid_8, valid_9, valid_10;

    always_ff @(posedge clk) begin
        if (i_ce) begin
            idx_6 <= idx_5;
            idx_7 <= idx_6;
            idx_8 <= idx_7;
            idx_9 <= idx_8;
            idx_10 <= idx_9;

            valid_6 <= valid_5;
            valid_7 <= valid_6;
            valid_8 <= valid_7;
            valid_9 <= valid_8;
            valid_10 <= valid_9;
        end
    end

    logic signed [41:0] s_re, s_im; // Q5.37
    logic [INDEX_WIDTH-1:0] idx_11;
    logic [4:0] k_1;
    logic valid_11;

    always_ff @(posedge clk) begin
        if (i_ce) begin
            s_re <= p_re_1 * $signed({1'b0, rec});
            s_im <= p_im_1 * $signed({1'b0, rec});

            idx_11 <= idx_10;
            valid_11 <= valid_10;
            k_1 <= k;
        end
    end

    logic signed [41:0] st_re, st_im;
    logic [INDEX_WIDTH-1:0] idx_12;
    logic valid_12;

    always_ff @(posedge clk) begin
        if (i_ce) begin
            st_re <= s_re << k_1;
            st_im <= s_im << k_1;
            idx_12 <= idx_11;
            valid_12 <= valid_11;
        end
    end

    logic signed [37:0] cl_re, cl_im; // Q1.37

    zerochan_lib_sclamp_1
        #(42, 38)
    u_clamp_re
        (clk, i_ce, st_re, cl_re);

    zerochan_lib_sclamp_1
        #(42, 38)
    u_clamp_im
        (clk, i_ce, st_im, cl_im);

    logic [INDEX_WIDTH-1:0] idx_13;
    logic valid_13;

    always_ff @(posedge clk) begin
        if (i_ce) begin
            idx_13 <= idx_12;
            valid_13 <= valid_12;
        end
    end

    zerochan_lib_round_1
        #(38, 22)
    u_round_re
        (clk, i_ce, cl_re, o_re);

    zerochan_lib_round_1
        #(38, 22)
    u_round_im
        (clk, i_ce, cl_im, o_im);

    always_ff @(posedge clk) begin
        if (i_ce) begin
            o_idx <= idx_13;
            o_valid <= valid_13;
        end
    end

endmodule : zerochan_rx_eq

module zerochan_rx_eq_ls #
( parameter int FFT_N = 1024
, parameter int PILOT_SPACING = 16
, parameter int PILOT_OFFSET = 8
, parameter int DATA_P = /*488*/512
, parameter int DATA_N = /*536*/512

, parameter int INDEX_WIDTH = $clog2(FFT_N)
, parameter int PILOTS = FFT_N / PILOT_SPACING
, parameter int PILOTS_WIDTH = $clog2(PILOTS)
, parameter int OFFSET_WIDTH = $clog2(PILOT_SPACING)
)
( input  logic                    clk
, input  logic                    i_ce

, input  logic [INDEX_WIDTH-1:0]  i_idx
, input  logic [           15:0]  i_re
, input  logic [           15:0]  i_im

, output logic [INDEX_WIDTH-1:0]  o_idx

, output logic                    o_active
, output logic                    o_pilot
, output logic [OFFSET_WIDTH-1:0] o_pilot_rel

, output logic                    o_no_p0
, output logic                    o_no_p3

, output logic [            31:0] o_p [4]

, output logic [            15:0] o_re
, output logic [            15:0] o_im
);

    logic [32+INDEX_WIDTH-1:0] delay [PILOT_SPACING*2];

    logic signed [15:0] re_d, im_d;
    logic signed [15:0] re_d_1, im_d_1;
    logic [INDEX_WIDTH-1:0] idx_d, idx_d_1;

    logic is_active, is_pilot;
    logic [PILOTS_WIDTH-1:0] pilot_idx;

    logic [15:0] re_1, im_1;
    logic [INDEX_WIDTH-1:0] idx_1;

    assign {re_d, im_d, idx_d} = delay[0];

    always_ff @(posedge clk) begin
        if (i_ce) begin
            delay <= {delay[1:PILOT_SPACING*2-1], {i_re, i_im, i_idx}};

            is_active <= i_idx != 0 && (i_idx <= INDEX_WIDTH'(DATA_P) || i_idx >= INDEX_WIDTH'(DATA_N));
            is_pilot <= i_idx[OFFSET_WIDTH-1:0] == OFFSET_WIDTH'(PILOT_OFFSET);
            pilot_idx <= i_idx[INDEX_WIDTH-1-:PILOTS_WIDTH];

            idx_d_1 <= idx_d;
            {re_d_1, im_d_1} <= {re_d, im_d};
            {re_1, im_1} <= {i_re, i_im};
        end
    end

    logic [1:0] pilot_rom [PILOTS];

    initial $readmemb("pilots.mem", pilot_rom);

    logic signed [15:0] ls_re, ls_im;

    always_comb begin
        unique case (pilot_rom[pilot_idx])
            2'b00: begin
                ls_re = re_1;
                ls_im = im_1;
            end
            2'b01: begin
                ls_re =  im_1;
                ls_im = -re_1;
            end
            2'b10: begin
                ls_re = -re_1;
                ls_im = -im_1;
            end
            2'b11: begin
                ls_re = -im_1;
                ls_im =  re_1;
            end
            default: begin
                ls_re = re_1;
                ls_im = im_1;
            end
        endcase
    end

    localparam logic [PILOTS_WIDTH-1:0] NO_P3_PILOT = ((DATA_P - PILOT_OFFSET) / PILOT_SPACING) + 1;
    localparam logic [PILOTS_WIDTH-1:0] NO_P0_PILOT = ((DATA_N - PILOT_OFFSET) / PILOT_SPACING) + 2;

    localparam logic [INDEX_WIDTH-1:0] WRAP_AROUND = (FFT_N - PILOT_SPACING * 2) + PILOT_OFFSET;

    logic [31:0] p [4];
    logic [31:0] w [4];
    logic sel;

    wire [INDEX_WIDTH-1:0] rel_idx = idx_d_1 - INDEX_WIDTH'(PILOT_OFFSET);

    always_comb begin
        if (o_idx >= WRAP_AROUND) begin
            unique case (sel)
                1'b0: o_p = {p[0], p[1], p[2], w[2]};
                1'b1: o_p = {p[0], p[1], w[2], w[3]};
            endcase
        end else begin
            o_p = p;
        end
    end

    always_ff @(posedge clk) begin
        if (i_ce) begin
            if (is_pilot) begin
                if (is_active) begin
                    p <= {p[1:3], {ls_re, ls_im}};

                    if (pilot_idx == PILOTS_WIDTH'(0)) begin
                        sel <= 1'b0;
                        w[0] <= {ls_re, ls_im};
                        w[2] <= w[0];
                    end else if (pilot_idx == PILOTS_WIDTH'(1)) begin
                        sel <= 1'b1;
                        w[1] <= {ls_re, ls_im};
                        w[3] <= w[1];
                    end else begin
                        sel <= 1'b0;
                    end
                end else begin
                    p <= {p[1:3], p[3]};
                end

                if (pilot_idx == NO_P3_PILOT) begin
                    o_no_p0 <= 1'b0;
                    o_no_p3 <= 1'b1;
                end else if (pilot_idx == NO_P0_PILOT) begin
                    o_no_p0 <= 1'b1;
                    o_no_p3 <= 1'b0;
                end else begin
                    o_no_p0 <= 1'b0;
                    o_no_p3 <= 1'b0;
                end
            end

            {o_re, o_im} <= {re_d_1, im_d_1};
            o_idx <= idx_d_1;
            o_active <= idx_d_1 != 0 && (idx_d_1 <= INDEX_WIDTH'(DATA_P) || idx_d_1 >= INDEX_WIDTH'(DATA_N));
            o_pilot <= idx_d_1[OFFSET_WIDTH-1:0] == OFFSET_WIDTH'(PILOT_OFFSET);
            o_pilot_rel <= rel_idx[OFFSET_WIDTH-1:0];
        end
    end

endmodule : zerochan_rx_eq_ls

module zerochan_rx_eq_scale_5
( input  logic               clk
, input  logic               i_ce

, input  logic signed [15:0] i_re
, input  logic signed [15:0] i_im

, output logic        [ 4:0] o_k
, output logic        [17:0] o_rec
);

    wire [32:0] h_den_0 = (i_re * i_re) + (i_im * i_im);
    logic [29:0] h_den;

    always_ff @(posedge clk) begin
        if (i_ce) begin
            h_den <= (|h_den_0[32-:3]) ? {30{1'b1}} : h_den_0[29:0];
        end
    end

    logic [4:0] lzc, k;

    zerochan_lib_lzc_0 #(30) u_lzc (h_den, lzc);

    logic [29:0] norm_den;

    always_ff @(posedge clk) begin
        if (i_ce) begin
            norm_den <= h_den << lzc;
            k <= lzc;
        end
    end

    logic [4:0] k_1, k_2;

    zerochan_rx_eq_reciprocal_3 #(30, 16) u_rec
        (clk, i_ce, norm_den, o_rec);

    always_ff @(posedge clk) begin
        if (i_ce) begin
            k_1 <= k;
            k_2 <= k_1;
            o_k <= k_2;
        end
    end

endmodule : zerochan_rx_eq_scale_5

module zerochan_rx_eq_spline_5 #
( parameter int DATA_WIDTH = 16
, parameter int FRAC_WIDTH = 4
)
( input  logic                         clk

, input  logic                         i_ce

, input  logic        [FRAC_WIDTH-1:0] i_frac
, input  logic                         i_no_p0
, input  logic                         i_no_p3

, input  logic signed [DATA_WIDTH-1:0] i_p0
, input  logic signed [DATA_WIDTH-1:0] i_p1
, input  logic signed [DATA_WIDTH-1:0] i_p2
, input  logic signed [DATA_WIDTH-1:0] i_p3

, output logic signed [DATA_WIDTH-1:0] o_val
);

    logic signed [DATA_WIDTH+2:0] c0, c1, c2, c3;
    logic signed [DATA_WIDTH+1:0] m0, m1;
    logic [FRAC_WIDTH-1:0] frac_1;

    always_comb begin
        if (i_no_p0) begin
            m0 = i_p2 - i_p1;
        end else begin
            m0 = (i_p2 >>> 1) - (i_p0 >>> 1);
        end

        if (i_no_p3) begin
            m1 = i_p2 - i_p1;
        end else begin
            m1 = (i_p3 >>> 1) - (i_p1 >>> 1);
        end
    end

    always_ff @(posedge clk) begin
        if (i_ce) begin
            c0 <= i_p1;
            c1 <= m0;
            c2 <= (i_p2 + (i_p2 << 1)) - (i_p1 + (i_p1 << 1)) - (m0 << 1) - m1;
            c3 <= (i_p1 << 1) - (i_p2 << 1) + m0 + m1;

            frac_1 <= i_frac;
        end
    end

    logic signed [DATA_WIDTH+4:0] s1;
    logic signed [DATA_WIDTH+2:0] c0_1, c1_1;
    logic [FRAC_WIDTH-1:0] frac_2;

    always_ff @(posedge clk) begin
        if (i_ce) begin
            s1 <= ((c3 * $signed({1'b0, frac_1})) >>> FRAC_WIDTH) + c2;
            c0_1 <= c0;
            c1_1 <= c1;
            frac_2 <= frac_1;
        end
    end

    logic signed [DATA_WIDTH+4:0] s2;
    logic signed [DATA_WIDTH+2:0] c0_2;
    logic [FRAC_WIDTH-1:0] frac_3;

    always_ff @(posedge clk) begin
        if (i_ce) begin
            s2  <= ((s1 * $signed({1'b0, frac_2})) >>> FRAC_WIDTH) + c1_1;
            c0_2 <= c0_1;
            frac_3 <= frac_2;
        end
    end

    logic signed [DATA_WIDTH+4:0] s3;

    always_ff @(posedge clk) begin
        if (i_ce) begin
            s3 <= ((s2 * $signed({1'b0, frac_3})) >>> FRAC_WIDTH) + c0_2;
        end
    end

    zerochan_lib_sclamp_1 #(DATA_WIDTH+5, DATA_WIDTH)
        u_clamp (clk, i_ce, s3, o_val);

endmodule : zerochan_rx_eq_spline_5

module zerochan_rx_eq_reciprocal_3 #
// Denominator for addressing and interpolation
( parameter int DEN = 16
// Reciprical fractional bits
, parameter int WID = DEN
// Final reciprical width (do not change)
, parameter int REC = WID + 2

// ROM depth
, parameter int DEPTH = 8
)
( input  logic           clk

, input  logic           i_ce

, input  logic [DEN-1:0] i_den
, output logic [REC-1:0] o_rec
);

    // 1: Access ROM

    localparam int DX_W = DEN-DEPTH-1;

    wire [DEPTH-1:0] addr_0 = i_den[DEN-2-:DEPTH];
    wire [DX_W-1:0] dx_0 = i_den[DX_W-1:0];

    logic [REC*2-1:0] rom_1 [2 ** DEPTH];
    logic [REC-1:0] slope_1, rec_1;
    logic [DX_W-1:0] dx_1;

    always_ff @(posedge clk) begin
        if (i_ce) begin
            {rec_1, slope_1} <= rom_1[addr_0];
            dx_1 <= dx_0;
        end
    end

    initial begin
        localparam int SEG = 2 ** DEPTH;
        localparam real DX = 0.5 / real'(SEG);

        var automatic int i;

        for (i = 0; i < SEG; i++) begin
            var automatic real x0, x1, y0, y1, slope;
            var automatic int slope_fixed, rec_fixed;

            x0 = 0.5 + real'(i) * DX;
            x1 = x0 + DX;

            y0 = 1.0 / x0;
            y1 = 1.0 / x1;

            slope = (y1 - y0) / DX;

            slope_fixed = $rtoi($floor(-slope * (2.0 ** WID) + 0.5));
            rec_fixed = $rtoi($floor(y0 * (2.0 ** WID) + 0.5));

            rom_1[i] = {rec_fixed[REC-1:0], slope_fixed[REC-1:0]};
        end
    end

    // 2: Compute fine adjustment

    localparam logic [DEN-1:0] ROUND = 1 << (DEN - 1);

    logic [REC+DX_W-1:0] fine_2;
    logic [REC-1:0] rec_2;

    always_ff @(posedge clk) begin
       if (i_ce) begin
           fine_2 <= slope_1 * dx_1 + ROUND;
           rec_2 <= rec_1;
       end
    end

    // 3: Refine

    always_ff @(posedge clk) begin
        if (i_ce) begin
            o_rec <= REC'(rec_2 - (fine_2 >> DEN));
        end
    end

endmodule : zerochan_rx_eq_reciprocal_3
