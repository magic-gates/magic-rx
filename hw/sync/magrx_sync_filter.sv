module magrx_sync_filter #
( parameter int LEN = 1024
, parameter int CP = 64

, parameter int ID = $clog2(LEN + CP)
)
( input  logic                 clk

, input  logic                 i_valid
, input  logic        [ID-1:0] i_idx

, output logic                 o_valid
, output logic        [   1:0] o_err
);

    localparam logic [ID-1:0] HALF_LEN = ID'((LEN + CP) / 2);

    // 1: Deviation

    wire [ID-1:0] idx = i_idx;

    logic dev_valid;
    logic signed [ID-1:0] dev;

    always_ff @(posedge clk) begin
        if (i_valid) begin
            dev <= idx >= HALF_LEN ? ID'(idx - LEN) : idx;
        end
    end

    always_ff @(posedge clk) begin
        dev_valid <= i_valid;
    end

    // 2: Clamp

    always_ff @(posedge clk) begin
        if (dev_valid) begin
            o_err <= dev < 0 ? -2'sd1 : dev > 0 ? 2'sd1 : 2'sd0;
        end
    end

    always_ff @(posedge clk) begin
        o_valid <= dev_valid;
    end

endmodule
