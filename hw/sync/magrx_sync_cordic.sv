module magrx_sync_cordic #
( parameter int DW = 16
, parameter int AW = 16
, parameter int S = 16
)
( input  logic                 clk
, input  logic                 rst

, input  logic                 i_load
, input  logic signed [DW-1:0] i_re
, input  logic signed [DW-1:0] i_im

, output logic                 o_valid
, output logic signed [AW-1:0] o_angle
);

    localparam int W = $clog2(S);

    logic signed [AW-1:0] atan [S];
    logic signed [DW-1:0] re, im;

    logic [W-1:0] stage;

    enum
    { LOAD
    , RUN
    , RESET
    } state;

    wire sign = ~im[DW-1];

    wire signed [DW-1:0] re_shr = re >>> stage;
    wire signed [DW-1:0] im_shr = im >>> stage;

    always_ff @(posedge clk) begin
        if (rst) begin
            state <= LOAD;
            o_valid <= 0;
        end else unique case (state)
            LOAD: if (i_load) begin
                state <= RUN;
                stage <= 0;

                unique case ({i_re[DW-1], i_im[DW-1]})
                    2'b00,
                    2'b01: begin
                        re = i_re;
                        im = i_im;
                        o_angle = 0;
                    end
                    2'b10: begin
                        re = i_im;
                        im = -i_re;
                        o_angle = {2'b01, {AW-2{1'b0}}};
                    end
                    2'b11: begin
                        re = -i_im;
                        im = i_re;
                        o_angle = {2'b11, {AW-2{1'b0}}};
                    end
                endcase
            end
            RUN: if (im == 0 || stage == S - 1) begin
                o_valid <= 1'b1;
                state <= RESET;
            end else begin
                re <= sign ? re + im_shr : re - im_shr;
                im <= sign ? im - re_shr : im + re_shr;

                o_angle <= sign ? o_angle + atan[stage] : o_angle - atan[stage];

                stage <= stage + W'(1);
            end
            RESET: begin
                o_valid <= 1'b0;
                state <= LOAD;
            end
            default: state <= state;
        endcase
    end

    generate for (genvar i = 0; i < S; i++) begin : gen_atan
        assign atan[i] = int'($atan(2.0 ** -i) / $atan(1.0) * (2.0 ** (AW - 3)));
    end endgenerate

endmodule
