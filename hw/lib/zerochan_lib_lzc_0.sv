module zerochan_lib_lzc_0 #
( parameter int DATA_WIDTH = 16
, parameter int COUNT_WIDTH = $clog2(DATA_WIDTH) + 1
)
( input  logic [ DATA_WIDTH-1:0] data
, output logic [COUNT_WIDTH-1:0] count
);

    always_comb begin
        count = DATA_WIDTH;

        for (int i = DATA_WIDTH - 1; i >= 0; i--) begin
            if (data[i]) begin
                count = DATA_WIDTH - 1 - i;
                break;
            end
        end
    end

endmodule : zerochan_lib_lzc_0
