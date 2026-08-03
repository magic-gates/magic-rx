module magrx_rst
( input  logic clk
, input  logic arst

, output logic rst
);

    (* ASYNC_REG = "TRUE" *)
    logic _0, _1;

    assign rst = _1;

    always @(posedge clk) begin
        _0 <= arst;
        _1 <= _0;
    end

endmodule
