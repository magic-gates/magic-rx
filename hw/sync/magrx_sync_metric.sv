module magrx_sync_metric #
( parameter int LEN = 1024
, parameter int CP = 64

, parameter int ID = $clog2(LEN + CP)
, parameter int W = $clog2(CP) + 2
)
( input  logic                 clk

, input  logic        [ID-1:0] i_idx
, input  logic                 i_re
, input  logic                 i_im

, output logic        [ID-1:0] o_idx
, output logic signed [ W-1:0] o_re
, output logic signed [ W-1:0] o_im
);

    // Delay

    logic [LEN*2-1:0] line;

    wire d_re = line[1];
    wire d_im = line[0];

    always_ff @(posedge clk) begin
        line <= {{i_re, i_im}, line[LEN*2-1:2]};
    end

    // 1: Products

    logic [ID-1:0] idx_0;

    logic signed [1:0] p_re, p_im;

    wire rr = i_re ^ d_re;
    wire ii = i_im ^ d_im;
    wire ir = i_im ^ d_re;
    wire ri = i_re ^ d_im;

    always_ff @(posedge clk) begin
        idx_0 <= i_idx;

        p_re <= {rr & ii, rr ~^ ii};
        p_im <= {ir & ~ri, ir ^ ri};
    end

    // 2: Sum

    logic [CP*4-1:0] hist;

    logic signed [W-1:0] sum_re;
    logic signed [W-1:0] sum_im;

    assign o_re = sum_re;
    assign o_im = sum_im;

    always_ff @(posedge clk) begin
        o_idx <= idx_0;

        hist <= {{p_re, p_im}, hist[CP*4-1:4]};

        sum_re <= sum_re - $signed(hist[3:2]) + p_re;
        sum_im <= sum_im - $signed(hist[1:0]) + p_im;
    end

endmodule
