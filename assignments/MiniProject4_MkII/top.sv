`include "memory.sv"
`include "processor.sv"

module top (
    input logic clk, 
    output logic LED, 
    output logic RGB_R, 
    output logic RGB_G, 
    output logic RGB_B
);


    logic [2:0] funct3; //= 3'b010;
    logic dmem_wren; //= 1'b0;
    logic [31:0] dmem_address; //= 31'd0;
    logic [31:0] dmem_data_in; //= 31'd0;
    logic [31:0] dmem_data_out;
    logic [31:0] imem_address; //= 31'h1000;
    logic [31:0] imem_data_out;

    logic reset_memory;
    logic reset_processor = 0;
    logic led;
    logic red;
    logic green;
    logic blue;

    processor #() u1 (
        .clk (clk),
        .reset (reset_processor),
        .f3 (funct3),
        .dmem_wren (dmem_wren),
        .dmem_address (dmem_address),
        .dmem_data_out (dmem_data_in),
        .dmem_data_in (dmem_data_out),
        .imem_address (imem_address),
        .imem_data_in (imem_data_out)
    );
 

    memory #(
        .IMEM_INIT_FILE_PREFIX  ("rv32i_test")
    ) u2 (
        .clk            (clk), 
        .funct3         (funct3), 
        .dmem_wren      (dmem_wren), 
        .dmem_address   (dmem_address), 
        .dmem_data_in   (dmem_data_in), 
        .imem_address   (imem_address), 
        .imem_data_out  (imem_data_out), 
        .dmem_data_out  (dmem_data_out), 
        .reset          (reset_memory), 
        .led            (led), 
        .red            (red), 
        .green          (green), 
        .blue           (blue)
    );

    assign LED = ~led;
    assign RGB_R = ~red;
    assign RGB_G = ~green;
    assign RGB_B = ~blue;

endmodule
