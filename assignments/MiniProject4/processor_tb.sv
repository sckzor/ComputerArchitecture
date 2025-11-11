`timescale 10ns/10ns
`include "processor.sv"

module processor_tb;


    logic clk = 0;

    top # (
    ) u0 (
        .clk            (clk)
    );

    initial begin
        $dumpfile("processor.vcd");
        $dumpvars(0, processor_tb);
        #150000000
        $finish;
    end

    always begin
        #4
        clk = ~clk;
    end

endmodule
