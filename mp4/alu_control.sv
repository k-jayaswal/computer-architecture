`include "alu.sv"

module alu_control(
    input  logic [6:0] opcode,   
    input  logic [2:0] funct3,   
    input  logic [6:0] funct7,   
    output logic [4:0] alu_op   
);

    typedef enum logic [4:0] {
        ALU_ADD, ALU_SUB, ALU_SLL, ALU_SLT, ALU_SLTU, ALU_XOR,
        ALU_SRL, ALU_SRA, ALU_OR, ALU_AND, ALU_COPY,
        ALU_SLLI, ALU_SRLI, ALU_SRAI,
        ALU_BEQ, ALU_BNE, ALU_BLT, ALU_BGE, ALU_BLTU, ALU_BGEU,
        ALU_JAL, ALU_JALR, ALU_AUIPC
    } alu_op_t;

    always_comb begin
        case (opcode)

            // R-type 
            7'b0110011: begin
                case ({funct7, funct3})
                    10'b0000000000: alu_op = ALU_ADD;
                    10'b0100000000: alu_op = ALU_SUB;
                    10'b0000000001: alu_op = ALU_SLL;
                    10'b0000000010: alu_op = ALU_SLT;
                    10'b0000000011: alu_op = ALU_SLTU;
                    10'b0000000100: alu_op = ALU_XOR;
                    10'b0000000101: alu_op = ALU_SRL;
                    10'b0100000101: alu_op = ALU_SRA;
                    10'b0000000110: alu_op = ALU_OR;
                    10'b0000000111: alu_op = ALU_AND;
                    default:        alu_op = ALU_COPY;
                endcase
            end

            // I-type arithmetic 
            7'b0010011: begin
                case (funct3)
                    3'b000: alu_op = ALU_ADD;   // ADDI
                    3'b010: alu_op = ALU_SLT;   // SLTI
                    3'b011: alu_op = ALU_SLTU;  // SLTIU
                    3'b100: alu_op = ALU_XOR;   // XORI
                    3'b110: alu_op = ALU_OR;    // ORI
                    3'b111: alu_op = ALU_AND;   // ANDI
                    3'b001: alu_op = ALU_SLLI;  // SLLI
                    3'b101: alu_op = (funct7 == 7'b0000000) ? ALU_SRLI : ALU_SRAI; // SRLI/SRAI
                    default: alu_op = ALU_COPY;
                endcase
            end

            // load and store
            7'b0000011,  // load
            7'b0100011:  // store
                alu_op = ALU_ADD;

            // B-type branches
            7'b1100011: begin
                case (funct3)
                    3'b000: alu_op = ALU_BEQ;
                    3'b001: alu_op = ALU_BNE;
                    3'b100: alu_op = ALU_BLT;
                    3'b101: alu_op = ALU_BGE;
                    3'b110: alu_op = ALU_BLTU;
                    3'b111: alu_op = ALU_BGEU;
                    default: alu_op = ALU_COPY;
                endcase
            end

            // JAL
            7'b1101111: alu_op = ALU_JAL;

            // JALR
            7'b1100111: alu_op = ALU_JALR;

            // LUI / AUIPC
            7'b0010111: alu_op = ALU_AUIPC; // handled via imm to reg
            7'b0110111: alu_op = ALU_COPY;  // handled via imm to reg

            default: alu_op = ALU_COPY;
        endcase
    end

endmodule
