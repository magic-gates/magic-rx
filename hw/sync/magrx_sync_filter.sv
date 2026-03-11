module magrx_sync_filter #
( parameter int LEN = 1024
, parameter int CP = 64
// Smoothing factor
, parameter int SF = 4
// Deadband
, parameter int DB = 8

, parameter int ID = $clog2(LEN + CP)
)
( input  logic                 clk

, input  logic                 i_valid
, input  logic        [ID-1:0] i_idx

, output logic                 o_valid
, output logic signed [ID-1:0] o_err
);

    // 1: Wrap around

    localparam int HALF_LEN = (LEN + CP) / 2;

    logic dev_valid;
    logic signed [ID-1:0] dev;

    always_ff @(posedge clk) begin
        dev_valid <= i_valid;

        if (i_valid) begin
            dev <= i_idx >= HALF_LEN ? ID'(i_idx - LEN) : i_idx;
        end
    end

    // 2: Glitch filter

    logic signed [ID-1:0] dev_d;
    logic filtered_valid;

    wire [ID-1:0] diff = dev > dev_d ? dev - dev_d : dev_d - dev;

    always_ff @(posedge clk) begin
        filtered_valid <= dev_valid && diff < CP;

        if (dev_valid) begin
            dev_d <= dev;
        end
    end

    // 3: Smoothing

    logic signed [ID+SF-1:0] acc;
    logic acc_valid;

    always_ff @(posedge clk) begin
        acc_valid <= filtered_valid;

        if (filtered_valid) begin
            acc <= acc + (((dev_d << SF) - acc) >>> SF);
        end
    end

    // 4: Deadband

    wire signed [ID-1:0] err = acc >>> SF;

    always_ff @(posedge clk) begin
        o_valid <= acc_valid;

        if (acc_valid) begin
            if (err > 0 && err < DB) begin
                o_err <= 0;
            end else begin
                o_err <= err;
            end
        end
    end

endmodule
