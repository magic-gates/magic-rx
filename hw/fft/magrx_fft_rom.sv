module magrx_fft_rom #
( parameter int N  = 16
, parameter int S  = 0
, parameter int W  = 16
, parameter bit IV = 0

, parameter int AW = $clog2(N) - (S * 2)
)
( input  logic                 clk

, input  logic                 ce
, input  logic        [AW-1:0] addr

, output logic signed [ W-1:0] re
, output logic signed [ W-1:0] im
);

    localparam int A = N / (2 ** (2 + 2 * S));
    localparam int D = N / (4 ** S);

    logic [W*2-1:0] rom [1 << AW];

    always_ff @(posedge clk) begin
        if (ce) begin
            {re, im} <= rom[addr];
        end
    end

    initial begin : init_rom
        int c, x;

        for (c = 0; c < 4; c++) begin
            var automatic real theta;
            var automatic int s, l, k, cos, sin;

            s = {c[0], c[1]} * (4 ** S);
            l = c * A;

            for (x = c * A; x < c * A + A; x++) begin
                k = s * (x - l);
                theta = $atan(1.0) * 8 * (real'(k) / real'(N));

                cos = scale($cos(IV ? theta : -theta));
                sin = scale($sin(IV ? theta : -theta));

                rom[x] = {cos[W-1:0], sin[W-1:0]};
            end
        end
    end

    function automatic signed [W-1:0] scale(real x);
        localparam int MAX = ((1 << W - 1) - 1);
        localparam int MIN = (0 - (1 << W - 1));

        var automatic real scaled = x * (1 << W - 1);
        var automatic int v = $rtoi(scaled >= 0.0 ? scaled + 0.5 : scaled - 0.5);

        if (v > MAX) v = MAX;
        if (v < MIN) v = MIN;

        return v;
    endfunction

endmodule
