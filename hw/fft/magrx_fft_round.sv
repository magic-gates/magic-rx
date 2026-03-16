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

    wire signed [OW:0] sum = (OW+1)'(i[IW-1:FD] + round_up);

    wire overflow = ~sign & sum[OW];

    always_ff @(posedge clk) begin
        if (ce) begin
            o <= overflow ? {1'b0, {(OW-1){1'b1}}} : sum[OW-1:0];
        end
    end

endmodule : magrx_fft_round
