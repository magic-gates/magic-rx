module magrx_sync_round #
( parameter int I = 16
, parameter int O = 12
, parameter bit M = 0
)
( input  logic                clk

, input  logic signed [I-1:0] i
, output logic signed [O-1:0] o
);

    localparam int D = I - O - M;

    wire sign    =  i[I-1];

    wire lsb     =  i[D];
    wire halfway =  i[D-1];
    wire sticky  = |i[D-2:0];

    wire round_up = halfway & (sticky | lsb);

    wire signed [O-1:0] sum = O'(i[I-1:D] + round_up);

    wire overflow = ~sign & sum[O-1];

    always_ff @(posedge clk) begin
        o <= overflow ? {1'b0, {(O-1){1'b1}}} : sum;
    end

endmodule
