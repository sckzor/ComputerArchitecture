// RISC-V Processor Core
module processor(
    input  logic        clk,
    input  logic        reset,
    output logic [2:0]  f3,
    output logic        dmem_wren,
    output logic [31:0] dmem_address,
    output logic [31:0] dmem_data_out,
    input  logic [31:0] dmem_data_in,
    output logic [31:0] imem_address,
    input  logic [31:0] imem_data_in
);


logic [31:0] regs [31:0];
logic [31:0] pc = 32'h00001000;

logic [31:0] new_regs [31:0];
logic [31:0] new_pc = 32'h00001000;
logic        new_dmem_wren = 0;
logic [31:0] new_dmem_address = 32'h0;
logic [31:0] new_dmem_data_out = 32'h0;
logic [31:0] new_imem_address = 32'h0;

logic [31:0] instruction = 0;
logic [31:0] new_instruction = 0;

logic [6:0] opcode;
//logic [2:0] f3;
logic [6:0] f7;
logic [4:0] rd, rs1, rs2;

logic [31:0] imm_i, imm_s, imm_b, imm_u, imm_j;

assign opcode = instruction[6:0];
assign f3     = instruction[14:12];
assign f7     = instruction[31:25];
assign rd     = instruction[11:7];
assign rs1    = instruction[19:15];
assign rs2    = instruction[24:20];

assign imm_i = {{21{instruction[31]}}, instruction[30:20]};
assign imm_s = {{21{instruction[31]}}, instruction[30:25], instruction[11:7]};
assign imm_b = {{20{instruction[31]}}, instruction[7], instruction[30:25], instruction[11:8], 1'b0};
assign imm_u = {instruction[31:12], 12'b0};
assign imm_j = {{12{instruction[31]}}, instruction[19:12], instruction[20], instruction[30:21], 1'b0};

parameter RESET  = 0;
parameter FETCH  = 1;
parameter DECODE = 2;
parameter MEMORY = 3;

parameter CLK_PER_INS = 64;
logic [31:0] count = 0;
logic cycle_done = 0;
logic [1:0] state = RESET;

logic new_cycle_done = 0;

initial begin
    for(int i = 0; i < 32; i++) regs[i] = 32'h0;
end

always_ff @(posedge clk) begin
    if (reset) begin
        pc <= 32'h00001000;
        state <= RESET;
        for(int i = 0; i < 32; i++) regs[i] <= 32'h0;
    end

    dmem_wren <= new_dmem_wren;
    dmem_address <= new_dmem_address;
    dmem_data_out <= new_dmem_data_out;
    imem_address <= new_imem_address;

    if(count == CLK_PER_INS) begin
        for(int i = 1; i < 32; i++) regs[i] <= new_regs[i];
        pc <= new_pc;
        instruction <= new_instruction;

        if(state == MEMORY) state <= FETCH;
        else state <= state + 1;

        count <= 0;
    end else begin
        count <= count + 1;
    end
end

always_comb begin
    new_regs[0] = 32'h0;
    for(int i = 1; i < 32; i++) new_regs[i] = regs[i];
    new_pc = pc;
    new_dmem_wren = dmem_wren;
    new_dmem_address = dmem_address;
    new_dmem_data_out = dmem_data_out;
    new_imem_address = imem_address;
    new_instruction = instruction;

    if(state == FETCH) begin
        new_imem_address = pc;
        new_instruction = imem_data_in;
        new_pc = pc + 4;
    end

    if(state == DECODE) begin
        case(opcode)
            7'b0110111: begin // LUI
                new_regs[rd] = imm_u; 
            end

            7'b0010111: begin // AUIPC
                new_regs[rd] = imm_u + pc; 
            end

            7'b1101111: begin // JAL
                new_regs[rd] = pc + 4;
                new_pc = pc + imm_j;
            end

            7'b1100111: begin // JALR
                new_regs[rd] = pc + 4;
                new_pc = (regs[rs1] + imm_i) & 32'hFFFFFFFE;
            end

            7'b1100011: begin // BEQ, BNE, BLT, BGE, BLTU, BGEU
                case(f3)
                    3'b000: if(regs[rs1] == regs[rs2]) new_pc = pc + imm_b; // BEQ
                    3'b001: if(regs[rs1] != regs[rs2]) new_pc = pc + imm_b; // BNE
                    3'b100: if($signed(regs[rs1]) < $signed(regs[rs2])) new_pc = pc + imm_b; // BLT
                    3'b101: if($signed(regs[rs1]) >= $signed(regs[rs2])) new_pc = pc + imm_b; // BGE
                    3'b110: if(regs[rs1] < regs[rs2]) new_pc = pc + imm_b; // BLTU
                    3'b111: if(regs[rs1] >= regs[rs2]) new_pc = pc + imm_b; // BGEU
                endcase
            end

            7'b0000011: begin // LB, LH, LW, LBU, LHU
                new_dmem_address = regs[rs1] + imm_i;
            end

            7'b0100011: begin // SB, SH, SW
                new_dmem_wren = 1'b1;
                new_dmem_address = regs[rs1] + imm_s;
                new_dmem_data_out = regs[rs2];
            end


            7'b0010011: begin // ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRAI
                case(f3)
                    3'b000: new_regs[rd] = regs[rs1] + $signed(imm_i); // ADDI
                    3'b010: new_regs[rd] = $signed(regs[rs1]) < $signed(imm_i); // SLTI
                    3'b011: new_regs[rd] = regs[rs1] < imm_i; // SLTIU
                    3'b100: new_regs[rd] = regs[rs1] ^ imm_i; // XORI
                    3'b110: new_regs[rd] = regs[rs1] | imm_i; // ORI
                    3'b111: new_regs[rd] = regs[rs1] & imm_i; // ANDI
                    3'b001: new_regs[rd] = regs[rs1] << rs2; // SLLI
                    3'b101: case(f7)
                        7'b0000000: new_regs[rd] = regs[rs1] >> rs2; // SRLI
                        7'b0100000: new_regs[rd] = $signed(regs[rs1]) >>> rs2; // SRAI
                    endcase
                endcase
            end

            7'b0110011: begin // ADD, SUM, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND
                case(f3)
                    3'b000: case(f7)
                        7'b0000000: new_regs[rd] = regs[rs1] + regs[rs2]; // ADD
                        7'b0100000: new_regs[rd] = regs[rs1] - regs[rs2]; // SUB
                    endcase
                    3'b001: new_regs[rd] = regs[rs1] << regs[rs2]; // SLL
                    3'b010: new_regs[rd] = $signed(regs[rs1]) < $signed(regs[rs2]); // SLT
                    3'b011: new_regs[rd] = regs[rs1] < regs[rs2]; // SLTU
                    3'b100: new_regs[rd] = regs[rs1] ^ regs[rs2]; // XOR
                    3'b101: case(f7)
                        7'b0000000: new_regs[rd] = regs[rs1] >> regs[rs2]; // SRL
                        7'b0100000: new_regs[rd] = $signed(regs[rs1]) >>> regs[rs2]; // SRA
                    endcase
                    3'b110: new_regs[rd] = regs[rs1] | regs[rs2]; // OR
                    3'b111: new_regs[rd] = regs[rs1] & regs[rs2]; // AND
                endcase
            end
        endcase
    end

    if(state == MEMORY) begin
        case(opcode)
            7'b0000011: begin // LB, LH, LW, LBU, LHU
                new_regs[rd] = dmem_data_in;
            end

            7'b0100011: begin // SB, SH, SW
                new_dmem_wren = 1'b0;
            end
        endcase
    end
end

endmodule
