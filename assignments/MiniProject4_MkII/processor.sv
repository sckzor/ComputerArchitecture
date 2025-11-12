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

logic [31:0] reg_data = 0;
logic [4:0] reg_addr = 0;

logic [31:0] new_reg_data = 0;
logic [4:0] new_reg_addr = 0;

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
logic [4:0] rd;
logic [4:0] rs1;
logic [4:0] rs2;

logic [31:0] imm_i;
logic [31:0] imm_s;
logic [31:0] imm_b;
logic [31:0] imm_u;
logic [31:0] imm_j;

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
logic [1:0] state = RESET;

logic [31:0] add_1;
logic [31:0] add_2;
assign sum = add_1 + add_2;

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

    reg_data <= new_reg_data;
    reg_addr <= new_reg_addr;

    if(count == CLK_PER_INS) begin
        if(reg_addr > 0) begin
            regs[reg_addr] <= reg_data;
            reg_addr <= 0;
        end

        pc <= new_pc;
        instruction <= new_instruction;

        if(state == MEMORY) begin
            state <= FETCH;
        end else begin
            state <= state + 1;
        end

        count <= 0;
    end else begin
        count <= count + 1;
    end
end

always_comb begin
    new_reg_data = 0;
    new_reg_addr = 0;

    new_pc = pc;
    new_dmem_wren = dmem_wren;
    new_dmem_address = dmem_address;
    new_dmem_data_out = dmem_data_out;
    new_imem_address = imem_address;
    new_instruction = instruction;
    new_reg_data = reg_data;
    new_reg_addr = reg_addr;

    if(state == FETCH) begin
        new_imem_address = pc;
        new_instruction = imem_data_in;

        add_1 = pc;
        add_2 = 4;
        new_pc = sum;
    end

    if(state == DECODE) begin
        case(opcode)
            7'b0110111: begin // LUI
                new_reg_addr = rd;
                new_reg_data = imm_u; 
            end

            7'b0010111: begin // AUIPC
                new_reg_addr = rd;
                new_reg_data = imm_u + pc; 
            end

            7'b1101111: begin // JAL
                new_reg_addr = rd;
                new_reg_data = pc + 4;
                new_pc = pc + imm_j;
            end

            7'b1100111: begin // JALR
                new_reg_addr = rd;
                new_reg_data = pc + 4;
                new_pc = (regs[rs1] + imm_i) & 32'hFFFFFFFE;
            end

            7'b1100011: begin // BEQ, BNE, BLT, BGE, BLTU, BGEU
                case(f3)
                    3'b000: begin // BEQ
                        if(regs[rs1] == regs[rs2]) new_pc = pc + imm_b;
                    end
                    3'b001: begin // BNE
                        if(regs[rs1] != regs[rs2]) new_pc = pc + imm_b;
                    end
                    3'b100: begin // BLT
                        if($signed(regs[rs1]) < $signed(regs[rs2])) new_pc = pc + imm_b;
                    end
                    3'b101: begin // BGE
                        if($signed(regs[rs1]) >= $signed(regs[rs2])) new_pc = pc + imm_b;
                    end
                    3'b110: begin // BLTU
                        if(regs[rs1] < regs[rs2]) new_pc = pc + imm_b;
                    end
                    3'b111: begin // BGEU
                        if(regs[rs1] >= regs[rs2]) new_pc = pc + imm_b;
                    end
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
                new_reg_addr = rd;
                case(f3)
                    3'b000: begin // ADDI
                        new_reg_data = regs[rs1] + $signed(imm_i);
                    end
                    3'b010: begin // SLTI
                        new_reg_data = $signed(regs[rs1]) < $signed(imm_i);
                    end

                    3'b011: begin // SLTIU
                        new_reg_data = regs[rs1] < imm_i;
                    end

                    3'b100: begin // XORI
                        new_reg_data = regs[rs1] ^ imm_i;
                    end

                    3'b110: begin // ORI
                        new_reg_data = regs[rs1] | imm_i;
                    end

                    3'b111: begin // ANDI
                        new_reg_data = regs[rs1] & imm_i;
                    end

                    3'b001: begin // SLLI
                        new_reg_data = regs[rs1] << rs2;
                    end

                    3'b101: case(f7)
                        7'b0000000: begin // SRLI
                            new_reg_data = regs[rs1] >> rs2;
                        end
                        7'b0100000: begin // SRAI
                            new_reg_data = $signed(regs[rs1]) >>> rs2;
                        end
                    endcase
                endcase
            end

            7'b0110011: begin // ADD, SUM, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND
                new_reg_addr = rd;
                case(f3)
                    3'b000: case(f7)
                        7'b0000000: begin // ADD
                            new_reg_data = regs[rs1] + regs[rs2];
                        end

                        7'b0100000: begin // SUB
                            new_reg_data = regs[rs1] - regs[rs2];
                        end
                    endcase

                    3'b001: begin // SLL
                        new_reg_data = regs[rs1] << regs[rs2];
                    end

                    3'b010: begin // SLT
                        new_reg_data = $signed(regs[rs1]) < $signed(regs[rs2]);
                    end

                    3'b011: begin // SLTU
                        new_reg_data = regs[rs1] < regs[rs2];
                    end

                    3'b100: begin // XOR
                        new_reg_data = regs[rs1] ^ regs[rs2];
                    end

                    3'b101: case(f7)
                        7'b0000000: begin // SRL
                            new_reg_data = regs[rs1] >> regs[rs2];
                        end

                        7'b0100000: begin // SRA
                            new_reg_data = $signed(regs[rs1]) >>> regs[rs2];
                        end
                    endcase

                    3'b110: begin // OR
                        new_reg_data = regs[rs1] | regs[rs2];
                    end

                    3'b111: begin // AND
                        new_reg_data = regs[rs1] & regs[rs2];
                    end
                endcase
            end
        endcase
    end

    if(state == MEMORY) begin
        case(opcode)
            7'b0000011: begin // LB, LH, LW, LBU, LHU
                new_reg_addr = rd;
                new_reg_data = dmem_data_in;
            end

            7'b0100011: begin // SB, SH, SW
                new_dmem_wren = 1'b0;
            end
        endcase
    end
end

endmodule
