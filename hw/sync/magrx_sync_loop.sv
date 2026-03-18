module magrx_sync_loop #
( parameter int DW = 12
, parameter int KP = 4
, parameter int KI = 10
)
( input  logic                 clk
, input  logic                 rst

, input  logic                 i_valid
, input  logic signed [DW-1:0] i

, output logic                 o_valid
, output logic signed [DW-1:0] o
);

    localparam int AW = DW * 2;

    logic signed [AW-1:0] integrator;
    logic signed [AW-1:0] proportional;
    logic signed [AW-1:0] integral;
    logic signed [AW-1:0] sum;

    assign integral = (i <<< DW) >>> KI;
    assign proportional = (i <<< DW) >>> KP;

    assign sum = integrator + proportional;

    always_ff @(posedge clk) begin
        if (rst) begin
            integrator <= 0;
        end else if (i_valid) begin
            integrator <= integrator + integral;
        end
    end

    always_ff @(posedge clk) begin
        if (i_valid) begin
            o <= sum[DW*2-1:DW];
        end
    end

    always_ff @(posedge clk) begin
        o_valid <= i_valid;
    end

endmodule
