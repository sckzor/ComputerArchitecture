// RISC-V Processor Core
module processor(
    input  logic        clk,
    //input  logic        reset,
    output logic [2:0]  f3,
    output logic        dmem_wren,
    output logic [31:0] dmem_address,
    output logic [31:0] dmem_data_out,
    input  logic [31:0] dmem_data_in,
    output logic [31:0] pc = 32'h00000FFC,
    input  logic [31:0] imem_data_in
);


logic [31:0] regs [31:0];
// logic reset = 1;
// logic [31:0] pc = 32'h00001000;

logic [31:0] reg_data = 0;
logic [4:0] reg_addr = 0;

logic [31:0] new_reg_data = 0;
logic [4:0] new_reg_addr = 0;

logic [31:0] new_pc = 0;
logic        new_dmem_wren = 0;
logic [31:0] new_dmem_address = 32'h0;
logic [31:0] new_dmem_data_out = 32'h0;

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
// Stall for an FPGA clock because the timer seems to take an extra cycle to read?
parameter MEMORY = 5;

// Lengthening this to 32 bits in shortens the critical path by some dark magic
// I am not one to look a gift horse in the mouth...
logic [31:0] state = FETCH;

logic [31:0] add_1;
logic [31:0] add_2;
logic [31:0] sum;
assign sum = add_1 + add_2;

logic [31:0] s_1;
logic [31:0] s_2;

logic [31:0] shift_l;
assign shift_l = s_1 << s_2;

logic [31:0] shift_r;
assign shift_r = s_1 >> s_2;

logic [31:0] shift_ra;
assign shift_ra = $signed(s_1) >>> s_2;


initial begin
    for(int i = 0; i < 32; i++) regs[i] = 32'h0;
end


always_ff @(posedge clk) begin
    dmem_wren <= new_dmem_wren;
    dmem_address <= new_dmem_address;
    dmem_data_out <= new_dmem_data_out;

    reg_data <= new_reg_data;
    reg_addr <= new_reg_addr;

    if(reg_addr != 0) begin
        regs[reg_addr] <= reg_data;
        reg_addr <= 0;
    end

    pc <= new_pc;
    instruction <= new_instruction;

    if(state == MEMORY) begin
        state <= FETCH;
        pc <= pc + 4;
    end else begin
        state <= state + 1;
    end
end

always_comb begin
    new_instruction = instruction;

    if(state == FETCH) begin
        new_instruction = imem_data_in;
    end
end

always_comb begin
    new_reg_data = 0;
    new_reg_addr = 0;

    add_1 = 0;
    add_2 = 0;

    s_1 = 0;
    s_2 = 0;

    new_pc = pc;
    new_dmem_wren = 0;
    new_dmem_address = dmem_address;
    new_dmem_data_out = dmem_data_out;


    if(state == DECODE) begin
        case(opcode)
            7'b0110111: begin // LUI
                new_reg_addr = rd;
                new_reg_data = imm_u; 
            end

            7'b0010111: begin // AUIPC
                new_reg_addr = rd;
                add_1 = imm_u;
                add_2 = pc;
                new_reg_data = sum; 
            end

            7'b1101111: begin // JAL
                new_reg_addr = rd;

                add_1 = pc;
                add_2 = 4;
                new_reg_data = sum;

                add_2 = imm_j;
                new_pc = sum;
            end

            7'b1100111: begin // JALR
                new_reg_addr = rd;

                add_1 = pc;
                add_2 = 4;

                new_reg_data = sum;

                add_1 = regs[rs1];
                add_2 = imm_i;

                new_pc = (sum) & 32'hFFFFFFFE;
            end

            7'b1100011: begin // BEQ, BNE, BLT, BGE, BLTU, BGEU
                if ((regs[rs1] < regs[rs2] & f3 == 3'b110) | // BLTU
                    (regs[rs1] >= regs[rs2] & f3 == 3'b111) | // BGEU
                    ($signed(regs[rs1]) >= $signed(regs[rs2]) & f3 == 3'b101) | // BGE
                    ($signed(regs[rs1]) < $signed(regs[rs2]) & f3 == 3'b100) | // BLT
                    (regs[rs1] != regs[rs2] & f3 == 3'b001 ) | // BNE
                    (regs[rs1] == regs[rs2] & f3 == 3'b000)) // BEQ
                begin
                    add_1 = pc;
                    add_2 = imm_b;
                    new_pc = sum;
                end
            end

            7'b0000011: begin // LB, LH, LW, LBU, LHU
                add_1 = regs[rs1];
                add_2 = imm_i;
                new_dmem_address = sum;
            end

            7'b0100011: begin // SB, SH, SW
                new_dmem_wren = 1'b1;
                add_1 = regs[rs1];
                add_2 = imm_s;
                new_dmem_address = sum;
                new_dmem_data_out = regs[rs2];
            end

            7'b0010011: begin // ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRAI
                new_reg_addr = rd;

                case(f3)
                    3'b000: begin // ADDI
                        add_1 = regs[rs1];
                        add_2 = $signed(imm_i);
                        new_reg_data = sum;
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
                        s_1 = regs[rs1];
                        s_2 = rs2;
                        new_reg_data = shift_l;
                    end

                    3'b101: begin

                        case(f7)
                            7'b0000000: begin // SRLI
                                s_1 = regs[rs1];
                                s_2 = rs2;
                                new_reg_data = shift_r;
                            end

                            7'b0100000: begin // SRAI
                                s_1 = regs[rs1];
                                s_2 = rs2;
                                new_reg_data = shift_ra;
                            end
                        endcase
                    end

                endcase
            end

            7'b0110011: begin // ADD, SUM, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND
                new_reg_addr = rd;
                case(f3)
                    3'b000: begin
                        add_1 = regs[rs1];

                        case(f7)
                            7'b0000000: begin // ADD
                                add_2 = regs[rs2];
                            end

                            7'b0100000: begin // SUB
                                add_2 = -regs[rs2];
                            end
                        endcase

                        new_reg_data = sum;
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

                    3'b001: begin // SLL
                        s_1 = regs[rs1];
                        s_2 = regs[rs2];
                        new_reg_data = shift_l;
                    end

                    3'b101: begin


                        case(f7)
                            7'b0000000: begin // SRL
                                s_1 = regs[rs1];
                                s_2 = regs[rs2];
                                new_reg_data = shift_r;
                            end

                            7'b0100000: begin // SRA
                                s_1 = regs[rs1];
                                s_2 = rs2;
                                new_reg_data = shift_ra;
                            end
                        endcase
                    end

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

    if(opcode == 7'b0000011 && state == MEMORY) begin // LB, LH, LW, LBU, LHU
        new_reg_addr = rd;
        new_reg_data = dmem_data_in;
    end
end

endmodule
