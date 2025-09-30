`timescale 10ns/10ns
`include "rgbsweep.sv"

module rgbsweep_tb;


    logic clk = 0;
    logic RGB_R;
    logic RGB_G;
    logic RGB_B;

    top # (
    ) u0 (
        .clk            (clk), 
        .RGB_R          (RGB_R),
        .RGB_G          (RGB_G),
        .RGB_B          (RGB_B)
    );

    initial begin
        $dumpfile("rgbsweep.vcd");
        $dumpvars(0, rgbsweep_tb);
        #150000000
        $finish;
    end

    always begin
        #4
        clk = ~clk;
    end

endmodule
