module magrx_eq_lerp #
( parameter int DW = 16
, parameter int FI = 5
)
( input  logic                 clk

, input  logic                 i_ce

, input  logic        [FI-1:0] i_fi
, input  logic signed [DW-1:0] i_ps [2]

, output logic signed [DW-1:0] o_value
);

    // 1: Compute

    localparam logic [FI-2:0] ROUND = 1 << (FI - 1);

    logic signed [DW+FI:0] delta_1;
    logic signed [DW-1:0] y0_1;

    wire signed [DW+FI:0] delta_0 = (i_ps[1] - i_ps[0]) * $signed({1'b0, i_fi});

    always_ff @(posedge clk) begin
        if (i_ce) begin
            delta_1 <= delta_0[DW+FI] ? delta_0 - ROUND : delta_0 + ROUND;
            y0_1 <= i_ps[0];
        end
    end

    // 2: Round

    always_ff @(posedge clk) begin
        if (i_ce) begin
            o_value <= DW'(y0_1 + (delta_1 >>> FI));
        end
    end

endmodule
