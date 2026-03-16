module magrx_eq_reciprocal #
( parameter int I = 16
, parameter int O = I + 2

, parameter int S = 8
)
( input  logic         clk

, input  logic         i_ce

// Q0.I Demoninator in range 0.5 .. 1
, input  logic [I-1:0] i_den
// Q2.I Reciprocal in range 1 .. 2
, output logic [O-1:0] o_rec
);

    wire [S-1:0] addr_0 = i_den[I-2-:S];
    wire [I-S-2:0] dx_0 = i_den[I-S-2:0];

    // 1: Access ROM

    logic [O*2-1:0] rom_1 [2 ** S];
    logic [O-1:0] slope_1, rec_1;
    logic [I-S-2:0] dx_1;

    always_ff @(posedge clk) begin
        if (i_ce) begin
            {rec_1, slope_1} <= rom_1[addr_0];
            dx_1 <= dx_0;
        end
    end

    initial begin
        localparam int SEG = 2 ** S;
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

            slope_fixed = $rtoi($floor(-slope * (2.0 ** I) + 0.5));
            rec_fixed = $rtoi($floor(y0 * (2.0 ** I) + 0.5));

            rom_1[i] = {rec_fixed[O-1:0], slope_fixed[O-1:0]};
        end
    end

    // 2: Compute fine adjustment

    localparam logic [O+S-2:0] ROUND = 1 << (I - 1);

    logic [O+S-2:0] fine_2;
    logic [O-1:0] rec_2;

    always_ff @(posedge clk) begin
       if (i_ce) begin
           fine_2 <= (O+S-1)'(slope_1 * dx_1 + ROUND);
           rec_2 <= rec_1;
       end
    end

    // 3: Refine

    logic [O-1:0] rec_3;

    assign o_rec = rec_3;

    always_ff @(posedge clk) begin
        if (i_ce) begin
            rec_3 <= O'(rec_2 - (fine_2 >> I));
        end
    end

endmodule
