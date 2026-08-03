module magrx_eq #
( parameter int ID = 10
)
( input  logic          clk
, input  logic          i_ce

, input  logic [ID-1:0] i_idx
, input  logic [  15:0] i_re
, input  logic [  15:0] i_im

, output logic [ID-1:0] o_idx
, output logic [  15:0] o_re
, output logic [  15:0] o_im
);

    localparam logic [ID-1:0] DATA_P = /*488*/512;
    localparam logic [ID-1:0] DATA_N = /*536*/512;

    logic is_active, is_pilot;
    logic [5:0] pilot_idx;
    logic [3:0] pilot_rel;

    logic signed [15:0] re_1, im_1;
    logic [ID-1:0] idx_1;

    always_ff @(posedge clk) begin
        if (i_ce) begin
            is_active <= i_idx <= DATA_P || i_idx >= DATA_N;
            is_pilot <= i_idx[3:0] == 4'b1000;
            pilot_rel <= {~i_idx[3], i_idx[2:0]};
            pilot_idx <= i_idx[9:4];

            {re_1, im_1} <= {i_re, i_im};
            idx_1 <= i_idx;
        end
    end

    logic [1:0] pilot_rom [64];

    initial $readmemb("pilots.mem", pilot_rom);

    logic signed [15:0] ls_re, ls_im;

    always_comb begin
        ls_re = re_1;
        ls_im = im_1;

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
        endcase
    end

    logic [ID-1:0] idx_2;
    logic [3:0] pilot_rel_1;
    logic [31:0] p [4];
    logic [31:0] data [32 + 5];
    logic signed [15:0] d_re, d_im;

    assign {d_re, d_im} = data[0];

    always_ff @(posedge clk) begin
        if (i_ce) begin
            if (is_pilot) begin
                if (is_active) begin
                    p <= {p[1:3], {ls_re, ls_im}};
                end else begin
                    p <= {p[1:3], p[3]};
                end
            end

            data <= {data[1:31 + 5], {re_1, im_1}};
            pilot_rel_1 <= pilot_rel;
            idx_2 <= idx_1 - ID'(31 + 5);
        end
    end

    logic signed [15:0] h_re, h_im;

    wire [32:0] h_dbg = (h_re * h_re) + (h_im * h_im);

    magrx_eq_farrow #(16, 4) u_farrow_re
    ( .clk(clk)
    , .i_ce(i_ce)

    , .i_frac(pilot_rel_1)

    , .i_p0(p[0][31:16])
    , .i_p1(p[1][31:16])
    , .i_p2(p[2][31:16])
    , .i_p3(p[3][31:16])

    , .o_val(h_re)
    );

    magrx_eq_farrow #(16, 4) u_farrow_im
    ( .clk(clk)
    , .i_ce(i_ce)

    , .i_frac(pilot_rel_1)

    , .i_p0(p[0][15:0])
    , .i_p1(p[1][15:0])
    , .i_p2(p[2][15:0])
    , .i_p3(p[3][15:0])

    , .o_val(h_im)
    );

    wire [32:0] h_den_0 = (h_re * h_re) + (h_im * h_im);
    logic [29:0] h_den;

    always_ff @(posedge clk) begin
        if (i_ce) begin
            h_den <= (|h_den_0[32-:3]) ? {30{1'b1}} : h_den_0[29:0];
        end
    end

    logic [4:0] lzc, k;

    always_comb begin
        lzc = 30;

        for (int i = 29; i >= 0; i--) begin
            if (h_den[i]) begin
                lzc = 29 - i;
                break;
            end
        end
    end

    logic [29:0] norm_den;

    always_ff @(posedge clk) begin
        if (i_ce) begin
            norm_den <= h_den << lzc;
            k <= lzc;
        end
    end

    logic [17:0] norm_rec;

    magrx_eq_reciprocal #(30, 16) u_rec
        (clk, i_ce, norm_den, norm_rec);

    logic signed [16:0] s1;
    logic signed [16:0] s2;
    logic signed [16:0] s3;

    logic signed [15:0] h_re_1, h_im_1;
    logic signed [15:0] d_im_1;
    logic [ID-1:0] idx_3;

    always_ff @(posedge clk) begin
        if (i_ce) begin
            s1 <= d_re - d_im;
            s2 <= h_re + h_im;
            s3 <= d_re + d_im;

            h_re_1 <= h_re;
            h_im_1 <= -h_im;
            d_im_1 <= d_im;

            idx_3 <= idx_2;
        end
    end

    logic signed [32:0] p1, p2, p3;
    logic [ID-1:0] idx_4;

    always_ff @(posedge clk) begin
        if (i_ce) begin
            p1 <= s1 * h_re_1;
            p2 <= s2 * d_im_1;
            p3 <= s3 * h_im_1;

            idx_4 <= idx_3;
        end
    end

    wire signed [31:0] r_re = 32'(p1 + p2);
    wire signed [31:0] r_im = 32'(p2 + p3);

    logic signed [24:0] u_re, u_im; // Q2.23

    logic [ID-1:0] idx_5;
    logic [4:0] k_1;

    always_ff @(posedge clk) begin
        if (i_ce) begin
            u_re <= r_re >>> 7;
            u_im <= r_im >>> 7;

            idx_5 <= idx_4;
            k_1 <= k;
        end
    end

    logic signed [24:0] u_re_1, u_im_1;
    logic signed [24:0] u_re_2, u_im_2;
    logic [ID-1:0] idx_6, idx_7;
    logic [4:0] k_2, k_3;

    always_ff @(posedge clk) begin
        if (i_ce) begin
            {u_re_1, u_im_1} <= {u_re, u_im};
            {u_re_2, u_im_2} <= {u_re_1, u_im_1};

            idx_6 <= idx_5;
            idx_7 <= idx_6;
            k_2 <= k_1;
            k_3 <= k_2;
        end
    end

    logic signed [42:0] s_re, s_im; // Q4.39
    logic [ID-1:0] idx_8;
    logic [4:0] k_4;

    always_ff @(posedge clk) begin
        if (i_ce) begin
            s_re <= u_re_2 * $signed({1'b0, norm_rec});
            s_im <= u_im_2 * $signed({1'b0, norm_rec});

            idx_8 <= idx_7;
            k_4 <= k_3;
        end
    end

    logic signed [42:0] st_re, st_im;
    logic [ID-1:0] idx_9;

    always_ff @(posedge clk) begin
        if (i_ce) begin
            st_re <= s_re << k_4;
            st_im <= s_im << k_4;
            idx_9 <= idx_8;
        end
    end

    logic signed [17:0] wo_re, wo_im;

    magrx_round #(41, 24, 0) u_round_re
        (clk, i_ce, st_re[40:0], wo_re);

    magrx_round #(41, 24, 0) u_round_im
        (clk, i_ce, st_im[40:0], wo_im);

    assign o_re = wo_re[15:0];
    assign o_im = wo_im[15:0];

    always_ff @(posedge clk) begin
        if (i_ce) begin
            o_idx <= idx_9;
        end
    end

endmodule

module magrx_eq_farrow #
( parameter int DATA_WIDTH = 16
, parameter int FRAC_WIDTH = 4
)
( input  logic                         clk

, input  logic                         i_ce

, input  logic        [FRAC_WIDTH-1:0] i_frac

, input  logic signed [DATA_WIDTH-1:0] i_p0
, input  logic signed [DATA_WIDTH-1:0] i_p1
, input  logic signed [DATA_WIDTH-1:0] i_p2
, input  logic signed [DATA_WIDTH-1:0] i_p3

, output logic signed [DATA_WIDTH-1:0] o_val
);

    logic signed [DATA_WIDTH+2:0] c0, c1, c2, c3;
    logic [FRAC_WIDTH-1:0] frac_1;

    always_ff @(posedge clk) begin
        if (i_ce) begin
            c0 <= i_p1;
            c1 <= (i_p2 >>> 1) - (i_p0 >>> 1);
            c2 <= i_p0 - (i_p1 << 1) - (i_p1 >>> 1) + (i_p2 << 1) - (i_p3 >>> 1);
            c3 <= (i_p1 >>> 1) + i_p1 - (i_p2 >>> 1) - i_p2 + (i_p3 >>> 1) - (i_p0 >>> 1);

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

    assign o_val = s3[DATA_WIDTH-1:0];

endmodule : magrx_eq_farrow

module magrx_eq_lerp #
( parameter int DW = 16
, parameter int FI = 5
)
( input  logic                 clk

, input  logic                 i_ce

, input  logic        [FI-1:0] i_frac
, input  logic signed [DW-1:0] i_p0
, input  logic signed [DW-1:0] i_p1

, output logic signed [DW-1:0] o_val
);

    // 1: Compute

    localparam logic [FI-2:0] ROUND = 1 << (FI - 1);

    logic signed [DW+FI:0] delta_1;
    logic signed [DW-1:0] y0_1;

    wire signed [DW+FI:0] delta_0 = (i_p1 - i_p0) * $signed({1'b0, i_frac});

    always_ff @(posedge clk) begin
        if (i_ce) begin
            delta_1 <= delta_0[DW+FI] ? delta_0 - ROUND : delta_0 + ROUND;
            y0_1 <= i_p0;
        end
    end

    // 2: Round

    always_ff @(posedge clk) begin
        if (i_ce) begin
            o_val <= DW'(y0_1 + (delta_1 >>> FI));
        end
    end

endmodule

module magrx_eq_reciprocal #
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

endmodule
