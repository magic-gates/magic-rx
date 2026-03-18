module magrx_sync_mixer #
( parameter int DW = 12
, parameter int AW = 16
, parameter int DV = 10
)
( input  logic                 clk
, input  logic                 rst

, input  logic                 i_valid
, input  logic signed [AW-1:0] i_err

, input  logic signed [DW-1:0] i_re
, input  logic signed [DW-1:0] i_im

, output logic signed [DW-1:0] o_re
, output logic signed [DW-1:0] o_im
);

    localparam int LUT_WIDTH = DW + 2;

    logic [LUT_WIDTH-1:0] lut [4096];

    logic signed [AW:0] vel;
    logic signed [AW-1:0] acc;

    always_ff @(posedge clk) begin
        if (rst) begin
            vel <= 0;
        end if (i_valid) begin
            vel <= vel - i_err;
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            acc <= 0;
        end else begin
            acc <= acc + $signed(vel[AW:DV]);
        end
    end

    // 1: Generate address

    logic [1:0] quadrant;

    logic [11:0] sin_addr;
    logic [11:0] cos_addr;

    always_ff @(posedge clk) begin
        quadrant <= acc[AW-1:AW-2];
        sin_addr <= acc[AW-3:AW-14];
        cos_addr <= 12'd4095 - acc[AW-3:AW-14];
    end

    // 2: Load sin/cos

    logic [1:0] quadrant_0;

    logic [LUT_WIDTH-1:0] lut_sin;
    logic [LUT_WIDTH-1:0] lut_cos;

    always_ff @(posedge clk) begin
        quadrant_0 <= quadrant;
        lut_sin <= lut[sin_addr];
        lut_cos <= lut[cos_addr];
    end

    // 3: Multiply

    localparam int FW = LUT_WIDTH + 1;

    logic signed [FW-1:0] cos, sin;

    always_comb begin
        unique case (quadrant_0)
            2'b00: begin
                cos = $signed({1'b0, lut_cos});
                sin = $signed({1'b0, lut_sin});
            end
            2'b01: begin
                cos = -$signed({1'b0, lut_sin});
                sin =  $signed({1'b0, lut_cos});
            end
            2'b10: begin
                cos = -$signed({1'b0, lut_cos});
                sin = -$signed({1'b0, lut_sin});
            end
            2'b11: begin
                cos =  $signed({1'b0, lut_sin});
                sin = -$signed({1'b0, lut_cos});
            end
        endcase
    end

    logic signed [DW:0] s1;
    logic signed [FW:0] s2;
    logic signed [DW:0] s3;

    logic signed [DW-1:0] im_0;
    logic signed [FW-1:0] cos_0, sin_0;

    always_ff @(posedge clk) begin
        s1 <= i_re - i_im;
        s2 <= cos - sin;
        s3 <= i_re + i_im;

        im_0 <= i_im;
        cos_0 <= cos;
        sin_0 <= sin;
    end

    logic signed [DW+FW:0] p1, p2, p3;

    always_ff @(posedge clk) begin
        p1 <= s1 * cos_0;
        p2 <= s2 * im_0;
        p3 <= s3 * sin_0;
    end

    logic signed [DW+FW-1:0] m_re, m_im;

    always_ff @(posedge clk) begin
        m_re <= (DW+FW)'(p1 + p2);
        m_im <= (DW+FW)'(p2 + p3);
    end

    // 4: Round

    magrx_sync_round #(DW+FW, FW-1) u_round_re
        (clk, m_re, o_re);

    magrx_sync_round #(DW+FW, FW-1) u_round_im
        (clk, m_im, o_im);

    initial begin : gen_lut
        int i;

        for (i = 0; i < 4096; i++) begin
           var automatic real theta;
           var automatic int cos, sin;

           theta = ($atan(1.0) * 2) / 4096 * real'(i);
           sin = scale($sin(theta));

           lut[i] = sin;
        end
    end

    function automatic [LUT_WIDTH-1:0] scale(real x);
        localparam int MAX = ((1 << LUT_WIDTH) - 1);

        var automatic real scaled = x * (1 << LUT_WIDTH);
        var automatic int v = $rtoi(scaled + 0.5);

        if (v > MAX) v = MAX;

        return v;
    endfunction

endmodule
