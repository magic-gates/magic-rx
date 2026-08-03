module magrx_round #
( parameter int INPUT = 16
, parameter int ROUND = 16
, parameter bit SIGNED = 1
, parameter int OUTPUT = INPUT - ROUND - SIGNED
)
( input  logic                     clk

, input  logic                     ce

, input  logic signed [ INPUT-1:0] i
, output logic signed [OUTPUT-1:0] o
);

    wire sign    =  i[INPUT-1];

    wire lsb     =  i[ROUND];
    wire halfway =  i[ROUND-1];
    wire sticky  = |i[ROUND-2:0];

    wire round_up = halfway && (sticky || lsb);

    wire signed [OUTPUT:0] sum = $signed(i[INPUT-1:ROUND]) + round_up;
    wire overflow = ~sign & sum[OUTPUT];

    always_ff @(posedge clk) begin
        if (ce) begin
            o <= overflow ? {1'b0, {(OUTPUT-1){1'b1}}} : sum[OUTPUT-1:0];
        end
    end

endmodule
