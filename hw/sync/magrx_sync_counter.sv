module magrx_sync_counter #
( parameter int LEN = 1024
, parameter int CP = 64

, parameter int ID = $clog2(LEN + CP)
)
( input  logic                 clk

, input  logic                 i_err_valid
, input  logic signed [ID-1:0] i_err

, output logic        [ID-1:0] o_idx
);

    logic [ID-1:0] boundary;

    always_ff @(posedge clk) begin
        if (o_idx == boundary) begin
            o_idx <= 0;
        end else begin
            o_idx <= o_idx + ID'(1);
        end
    end

    always_ff @(posedge clk) begin
        if (i_err_valid) begin
            if (i_err < -CP) begin
                boundary <= ID'(LEN - 1);
            end else if (i_err > CP) begin
                boundary <= ID'((LEN + CP * 2) - 1);
            end else begin
                boundary <= ID'(LEN + CP - 1) + i_err;
            end
        end
    end

endmodule
