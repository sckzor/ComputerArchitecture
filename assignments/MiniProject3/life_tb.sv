`timescale 10ns/10ns
`include "life.sv"

module life_tb;


    logic clk = 0;
    logic _3b;


    top # (
    ) u0 (
        .clk            (clk), 
        ._3b          (_3b)
    );

    initial begin
        $dumpfile("life.vcd");
        $dumpvars(0, life_tb);
        #1500000
        $finish;
    end

    always begin
        #4
        clk = ~clk;
    end

endmodule
