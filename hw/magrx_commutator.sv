module magrx_commutator #
( parameter int PERMUT_SIZE = 1024
, parameter int DATA_WIDTH = 22
, parameter int OUTPUT_WIDTH = 16

, parameter int INDEX_WIDTH = $clog2(PERMUT_SIZE)
)
( input  logic                           clk

, input  logic                           i_ce
, input  logic        [ INDEX_WIDTH-1:0] i_idx
, output logic        [ INDEX_WIDTH-1:0] o_idx

, input  logic signed [  DATA_WIDTH-1:0] i_re
, input  logic signed [  DATA_WIDTH-1:0] i_im

, output logic signed [OUTPUT_WIDTH-1:0] o_re
, output logic signed [OUTPUT_WIDTH-1:0] o_im
);

    wire [DATA_WIDTH-2:0] agc_re_abs = (i_re < 0) ? (-i_re) : (i_re);
    wire [DATA_WIDTH-2:0] agc_im_abs = (i_im < 0) ? (-i_im) : (i_im);

    logic [DATA_WIDTH-2:0] agc_value;
    logic [DATA_WIDTH-1:0] re_1, im_1;
    logic [INDEX_WIDTH-1:0] idx_1;

    always_ff @(posedge clk) begin
        if (i_ce) begin
            agc_value <= agc_re_abs > agc_im_abs ? agc_re_abs : agc_im_abs;
            {re_1, im_1} <= {i_re, i_im};
            idx_1 <= i_idx;
        end
    end

    logic [DATA_WIDTH-2:0] agc_max, agc_max_1, agc_gain;
    logic [DATA_WIDTH-1:0] re_2, im_2;
    logic [INDEX_WIDTH-1:0] idx_2;

    always_ff @(posedge clk) begin
        if (i_ce) begin
            if (agc_value > agc_max) begin
                agc_max <= agc_value;
            end

            if (idx_1 == 0) begin
                agc_max <= agc_value;
            end

            agc_max_1 <= agc_max;
            {re_2, im_2} <= {re_1, im_1};
            idx_2 <= idx_1;
        end
    end

    localparam int GAIN_WIDTH = $clog2(DATA_WIDTH) + 1;

    logic [DATA_WIDTH-1:0] re_3, im_3;
    logic [INDEX_WIDTH-1:0] fwd_idx, rev_idx;
    logic [GAIN_WIDTH-1:0] agc_lzc, gain;

    // lzc #(DATA_WIDTH-1) u_lzc (agc_max_1, agc_lzc);

    always_comb begin
        agc_lzc = DATA_WIDTH - 1;

        for (int i = DATA_WIDTH - 2; i >= 0; i--) begin
            if (agc_max_1[i]) begin
                agc_lzc = DATA_WIDTH - 2 - i;
                break;
            end
        end
    end

    always_ff @(posedge clk) begin
        if (i_ce) begin
            if (idx_2 == 0) begin
                gain <= agc_lzc;
            end

            {re_3, im_3} <= {re_2, im_2};
            fwd_idx <= idx_2;

            for (int i = 0; i < INDEX_WIDTH; i++) begin
                rev_idx[i] <= idx_2[INDEX_WIDTH-1-i];
            end
        end
    end

    localparam int DEPTH = PERMUT_SIZE;
    localparam int ADDR_WIDTH = $clog2(DEPTH);
    localparam int WORD_WIDTH = DATA_WIDTH * 2;

    logic [WORD_WIDTH-1:0] a_ram [DEPTH];
    logic [WORD_WIDTH-1:0] b_ram [DEPTH];

    logic signed [DATA_WIDTH-1:0] z_re, z_im;
    logic [INDEX_WIDTH-1:0] z_idx;
    logic [GAIN_WIDTH-1:0] z_gain;

    logic flip;

    always_ff @(posedge clk) begin
        if (i_ce) begin
            if (fwd_idx == INDEX_WIDTH'(PERMUT_SIZE - 1)) begin
                flip <= ~flip;
            end

            if (flip) begin
                b_ram[rev_idx] <= {re_3, im_3};
                {z_re, z_im} <= a_ram[fwd_idx];
            end else begin
                a_ram[rev_idx] <= {re_3, im_3};
                {z_re, z_im} <= b_ram[fwd_idx];
            end

            z_gain <= gain;
            z_idx <= fwd_idx;
        end
    end

    logic signed [DATA_WIDTH-1:0] amp_re, amp_im;
    logic [INDEX_WIDTH-1:0] z_idx_1;

    always_ff @(posedge clk) begin
        if (i_ce) begin
            amp_re <= z_re << z_gain;
            amp_im <= z_im << z_gain;
            z_idx_1 <= z_idx;
        end
    end

    magrx_round #(DATA_WIDTH, DATA_WIDTH-OUTPUT_WIDTH, 0) u_round_re
        (clk, i_ce, amp_re, o_re);

    magrx_round #(DATA_WIDTH, DATA_WIDTH-OUTPUT_WIDTH, 0) u_round_im
        (clk, i_ce, amp_im, o_im);

    always_ff @(posedge clk) begin
        if (i_ce) begin
            o_idx <= z_idx_1;
        end
    end

endmodule
