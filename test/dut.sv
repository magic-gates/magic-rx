`timescale 1ns / 1ps

module dut
( input  logic               clk
, input  logic               arst

, input  logic signed [11:0] i_re
, input  logic signed [11:0] i_im

, output logic               o_ce
, output logic        [ 9:0] o_idx
, output logic signed [15:0] o_re
, output logic signed [15:0] o_im
);

    magrx u_dut
    ( .clk(clk)
    , .arst(arst)

    , .i_re(i_re)
    , .i_im(i_im)

    , .o_ce(o_ce)
    , .o_idx(o_idx)
    , .o_re(o_re)
    , .o_im(o_im)
    );

    initial begin
        $dumpfile("wave.fst");
        $dumpvars(0, dut);
    end

endmodule
