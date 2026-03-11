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
