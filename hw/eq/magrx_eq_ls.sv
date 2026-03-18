module magrx_eq_ls #
( parameter int N = 1024
, parameter int ID = $clog2(N)
, parameter int DW = 16
, parameter int PD = 5

, parameter int II = PD
, parameter int FI = ID - PD
)
( input  logic                 clk

, input  logic                 i_ce
, input  logic        [II-1:0] i_ii
, input  logic        [FI-1:0] i_fi
, input  logic signed [DW-1:0] i_re
, input  logic signed [DW-1:0] i_im

, output logic signed [DW-1:0] o_re
, output logic signed [DW-1:0] o_im

, output logic signed [DW-1:0] o_h_re [2]
, output logic signed [DW-1:0] o_h_im [2]
);

    logic [1:0] pilot_rom_0 [2 ** II];
    logic [1:0] pilot_0;

    assign pilot_0 = pilot_rom_0[i_ii];

    initial $readmemb("pilots.mem", pilot_rom_0);

    // 1: Estimate

    logic prb_1;

    logic [II-1:0] ii_1;
    logic [FI-1:0] fi_1;

    logic signed [DW-1:0] ls_re_1, ls_im_1;
    logic signed [DW-1:0] re_1, im_1;

    logic [II-1:0] addr_a_1, addr_b_1;

    always_ff @(posedge clk) begin
        if (i_ce) begin
            unique case (pilot_0)
                2'b00: begin
                    ls_re_1 <= i_re;
                    ls_im_1 <= i_im;
                end
                2'b01: begin
                    ls_re_1 <=  i_im;
                    ls_im_1 <= -i_re;
                end
                2'b10: begin
                    ls_re_1 <= -i_re;
                    ls_im_1 <= -i_im;
                end
                2'b11: begin
                    ls_re_1 <= -i_im;
                    ls_im_1 <=  i_re;
                end
            endcase
        end
    end

    always_ff @(posedge clk) begin
        if (i_ce) begin
            prb_1 <= i_fi == 0;
            addr_a_1 <= i_ii;
            addr_b_1 <= II'(i_ii + 'd1);
            {re_1, im_1} <= {i_re, i_im};
        end
    end

    // 2: Store Estimate and Access interpolation points

    localparam logic [II-1:0] POS_IDX = 1;
    localparam logic [II-1:0] NEG_IDX = {II{1'b1}};

    logic [DW*2-1:0] ls_rom_2 [2 ** II];

    logic signed [DW-1:0] h_re_2 [2];
    logic signed [DW-1:0] h_im_2 [2];

    logic signed [DW-1:0] pos_re, pos_im;
    logic signed [DW-1:0] neg_re, neg_im;

    logic signed [DW-1:0] re_2, im_2;

    assign o_h_re = h_re_2;
    assign o_h_im = h_im_2;

    assign {o_re, o_im} = {re_2, im_2};

    always_ff @(posedge clk) begin
        if (i_ce) begin
            if (prb_1) begin
                ls_rom_2[addr_a_1] <= {ls_re_1, ls_im_1};

                if (addr_a_1 == POS_IDX) begin
                    {pos_re, pos_im} <= {ls_re_1, ls_im_1};
                end

                if (addr_a_1 == NEG_IDX) begin
                    {neg_re, neg_im} <= {ls_re_1, ls_im_1};
                end
            end else begin
                if (addr_a_1 == 0) begin
                    h_re_2[0] <= (pos_re + neg_re) >>> 1;
                    h_im_2[0] <= (pos_im + neg_im) >>> 1;
                end else begin
                    {h_re_2[0], h_im_2[0]} <= ls_rom_2[addr_a_1];
                end

                if (addr_b_1 == 0) begin
                    h_re_2[1] <= (pos_re + neg_re) >>> 1;
                    h_im_2[1] <= (pos_im + neg_im) >>> 1;
                end else begin
                    {h_re_2[1], h_im_2[1]} <= ls_rom_2[addr_b_1];
                end
            end
        end
    end

    always_ff @(posedge clk) begin
        if (i_ce) begin
            {re_2, im_2} <= {re_1, im_1};
        end
    end

endmodule
