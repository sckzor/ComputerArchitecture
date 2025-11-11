`define SIMULATED
`timescale 10ns/10ns
`include "sdr.sv"

module sdr_tb;
    logic    clk = 0;
    logic    _20a;
    logic    _18a;
    logic    _13b;
    logic    _8a;
    logic    _9b;
    logic    _6a;
    logic    _4a;
    logic    _2a;
    logic    _3b;
    logic    _45a;
    logic    _48b;

    top # (
    ) u0 (
        .clk          (clk), 
        ._20a         (_20a),
        ._18a         (_18a),
        ._13b         (_13b),
        ._8a          (_8a),
        ._9b          (_9b),
        ._6a          (_6a),
        ._4a          (_4a),
        ._2a          (_2a),
        ._3b          (_3b),
        ._45a         (_45a),
        ._48b         (_48b)
    );

    initial begin
        $dumpfile("sdr.vcd");
        $dumpvars(0, sdr_tb);
        #2000000
        $finish;
    end

    always begin
        #4
        clk = ~clk;
    end

endmodule


