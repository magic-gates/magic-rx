module magrx_pla #
( parameter int W = 32
, parameter int L = 10
)
( input  logic         clk

, input  logic         i_ce
, input  logic [W-1:0] i
, output logic [W-1:0] o
);

    generate if (L == 1) begin
        always_ff @(posedge clk) begin
            if (i_ce) begin
                o <= i;
            end
        end
    end else if (L == 2) begin
        logic [W-1:0] d;

        always_ff @(posedge clk) begin
            if (i_ce) begin
                d <= i;
                o <= d;
            end
        end
    end else begin
        logic [W-1:0] line [L - 1];

        always_ff @(posedge clk) begin
            if (i_ce) begin
                line <= {line[1:L-2], i};
                o <= line[0];
            end
        end
    end endgenerate

endmodule
