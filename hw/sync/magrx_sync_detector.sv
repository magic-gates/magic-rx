module magrx_sync_detector #
// Metric width
( parameter int W = 6
// Sampling index width
, parameter int ID = 16
// Window length
, parameter int L = 64
// Enter threshold
, parameter logic [W-1:0] ET = 40
// Leave threshold
, parameter logic [W-1:0] LT = 40
)
( input  logic                clk
, input  logic                rst

, input  logic        [ID-1:0] i_idx
, input  logic signed [ W-1:0] i_re
, input  logic signed [ W-1:0] i_im

, output logic                 o_valid
, output logic        [ID-1:0] o_idx
, output logic signed [ W-1:0] o_re
, output logic signed [ W-1:0] o_im
);

    // 1: Magnitude

    logic signed [ID-1:0] idx;
    logic signed [W-1:0] mag;
    logic signed [W-1:0] re, im;

    wire [W-1:0] re_abs = i_re < 0 ? -i_re : i_re;
    wire [W-1:0] im_abs = i_im < 0 ? -i_im : i_im;

    wire [W-1:0] m_max = re_abs > im_abs ? re_abs : im_abs;
    wire [W-1:0] m_min = re_abs < im_abs ? re_abs : im_abs;

    always_ff @(posedge clk) begin
        {idx, re, im} <= {i_idx, i_re, i_im};

        mag <= m_max + (m_min >>> 3) + (m_min >>> 2);
    end

    localparam LW = $clog2(L);

    enum logic [1:0]
    { IDLE = 2'b00
    , FOLLOW = 2'b01
    , DETECT = 2'b10
    } st;

    logic [W-1:0] max;
    logic [LW-1:0] pos;

    wire enter = mag > ET;
    wire leave = (mag < LT) || (pos == LW'(L - 1));
    wire peak = mag > max;

    assign o_valid = st == DETECT;

    always_ff @(posedge clk) begin
        if (rst) begin
            st <= IDLE;
        end else begin
            unique case (st)
                IDLE: if (enter) begin
                    pos <= 0;
                    max <= mag;
                    st <= FOLLOW;
                end
                FOLLOW: if (leave) begin
                    st <= DETECT;
                end else begin
                    pos <= pos + LW'(1);

                    if (peak) begin
                        max <= mag;

                        {o_idx, o_re, o_im} <= {idx, re, im};
                    end
                end
                DETECT: begin
                    st <= IDLE;
                end
                default: st <= st;
            endcase
        end
    end

endmodule
