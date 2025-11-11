// RISC-V Processor Core

module processor(
    input logic     clk
);


// Register management
logic [31:0] new_reg_val = 0;
logic [31:0] reg_id = 0;
logic [0:0] write_back = 0;

logic [31:0] regs [31:0];


always_comb begin
    regs[0] = 32'b00000000000000000000000000000000;

    if (write_back == 1) begin
        if (reg_id > 0) begin
            regs[reg_id] = new_reg_val;
            write_back = 0;
        end
    end
end


// Instruction decode logic

logic [31:0] instruction = 0;

logic [6:0] opcode;

logic [2:0] f3;
logic [6:0] f7;

logic [4:0] rd;

logic [11:0] imm_i;
logic [11:0] imm_s;
logic [12:0] imm_b;
logic [31:0] imm_u;
logic [20:0] imm_j;

logic [4:0] rs1;
logic [4:0] rs2;

// Opcode locations
assign opcode = instruction[6:0];

// Immediate value locations
assign imm_i = {{21{instruction[31]}}, instruction[30:20]};
assign imm_s = {{21{instruction[31]}}, instruction[30:25], instruction[11:7]};
assign imm_b = {{20{instruction[31]}}, instruction[7], instruction[30:25], instruction[11:8], 1'b0};
assign imm_u = {instruction[31:12], {12{1'b0}}};
assign imm_j = {{12{instruction[31]}}, instruction[19:12], instruction[20], instruction[30:21], 1'b0};

// Function select bit locations
assign f3 = instruction[14:12];
assign f7 = instruction[31:25];

// Register locations
assign rd = instruction[11:7];
assign rs1 = instruction[19:15];
assign rs2 = instruction[24:20];


always_comb begin
end
    
always_comb begin
    case (opcode)
        7'b0110111: begin // LUI          
        end

        7'b0010111: begin // AUIPC
        end

        7'b1101111: begin // JAL
        end

        7'b1100011: begin // BEQ, BNE, BLT, BGE, BLTU, BGEU
            case (f3)
                3'b000: begin // BEQ
                end

                3'b001: begin // BNE
                end

                3'b100: begin // BLT
                end

                3'b101: begin // BGE
                end

                3'b110: begin // BLTU
                end

                3'b111: begin // BGEU
                end
            endcase
        end

        7'b1100111: begin // JALR
        end

        7'b0000011: begin // LB, LH, LW, LBU, LHU
            case (f3)
                3'b000: begin // LB
                end

                3'b001: begin // LH
                end

                3'b010: begin // LW
                end

                3'b100: begin // LBU
                end

                3'b101: begin // LHU
                end
            endcase
        end

        7'b0010011: begin // ADDI, SLTI, SLTIU, XORI, ORI, ANDI
            case (f3)
                3'b000: begin // ADDI
                end

                3'b010: begin // SLTI
                end

                3'b011: begin // SLTIU
                end

                3'b100: begin // XORI
                end

                3'b110: begin // ORI
                end

                3'b111: begin // ANDI
                end
            endcase
        end

        7'b0100011: begin // SB, SN, SW
            case (f3)
                3'b000: begin // SB
                end

                3'b001: begin // SN
                end

                3'b010: begin // SW
                end
            endcase
        end

        7'b0100011: begin // SLLI, SRLI, SRAI
            case (f3)
                3'b001: begin // SLLI
                end

                3'b101: begin // SRLI, SRAI
                    case (f7)
                        7'b0000000: begin // SRLI
                        end
                        7'b0100000: begin // SRAI
                        end
                    endcase
                end
            endcase
        end

        7'b0110011: begin // ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND
            case (f3)
                3'b000: begin // ADD, SUB
                    case (f7)
                        7'b0000000: begin // ADD
                        end
                        7'b0100000: begin // SUB
                        end
                    endcase
                end

                3'b001: begin // SLL
                end

                3'b010: begin // SLT
                end

                3'b011: begin // SLTU
                end

                3'b100: begin // XOR
                end

                3'b101: begin // SRL, SRA
                    case (f7)
                        7'b0000000: begin // SRL
                        end
                        7'b0100000: begin // SRA
                        end
                    endcase
                end

                3'b110: begin // OR
                end

                3'b111: begin // AND
                end
            endcase
        end	
    endcase
end

endmodule
