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
