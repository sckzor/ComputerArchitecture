`timescale 10ns/10ns
`include "top.sv"

module mp4_tb;

    logic clk = 0;
    logic LED, RGB_R, RGB_G, RGB_B;
    logic [7:0] i;


    top u0 (
        .clk            (clk), 
        .LED            (LED), 
        .RGB_R          (RGB_R), 
        .RGB_G          (RGB_G), 
        .RGB_B          (RGB_B)
    );

    initial begin
        $dumpfile("top.vcd");
        $dumpvars(0, mp4_tb);
        for(i = 0; i < 32; i = i + 1) begin
             $dumpvars(1, u0.u1.regs[i]);
        end
        #500000
        $finish;
    end

    always begin
        #4
        clk = ~clk;
    end

endmodule

