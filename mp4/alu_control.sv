// ALU Control Unit

// Purpose: Translates instruction fields into ALU operation codes.
//
// Why this module exists:
//   The instruction format (opcode, funct3, funct7) doesn't directly map to
//   ALU operations. We need a decoder that looks at these fields and determines
//   "what should the ALU actually do?" This separation keeps the ALU simple
//   and makes the instruction decoding logic reusable.
//
// What it does:
//   - Reads opcode (7 bits), funct3 (3 bits), and funct7 (7 bits)
//   - Decodes the instruction type (R-type, I-type, Load, Store, Branch, etc.)
//   - Outputs the appropriate ALU operation code
//   - Handles all 40+ RISC-V instruction variants

`include "alu_types.sv"

module alu_control(
    input  logic [6:0] opcode, // instruction type 
    input  logic [2:0] funct3,    
    input  logic [6:0] funct7,    
    output alu_op_t    alu_op   
);

    always_comb begin
        
        case (opcode)
            // R-TYPE INSTRUCTIONS (0110011): need both funct 3 and funct 7 to evaluate operation
            7'b0110011: begin
                case ({funct7, funct3})
                    10'b0000000_000: alu_op = ALU_ADD;   // ADD
                    10'b0100000_000: alu_op = ALU_SUB;   // SUB 
                    10'b0000000_001: alu_op = ALU_SLL;   // SLL
                    10'b0000000_010: alu_op = ALU_SLT;   // SLT 
                    10'b0000000_011: alu_op = ALU_SLTU;  // SLTU
                    10'b0000000_100: alu_op = ALU_XOR;   // XOR
                    10'b0000000_101: alu_op = ALU_SRL;   // SRL 
                    10'b0100000_101: alu_op = ALU_SRA;   // SRA 
                    10'b0000000_110: alu_op = ALU_OR;    // OR
                    10'b0000000_111: alu_op = ALU_AND;   // AND
                    
                    default: alu_op = ALU_COPY;  // pass through if unknown
                endcase
            end
            
            // I-TYPE ARITHMETIC INSTRUCTIONS (0010011): only need funct3, except for shifts  
            7'b0010011: begin
                case (funct3)
                    3'b000: alu_op = ALU_ADD;    // ADDI 
                    3'b010: alu_op = ALU_SLT;    // SLTI 
                    3'b011: alu_op = ALU_SLTU;   // SLTIU 
                    3'b100: alu_op = ALU_XOR;    // XORI 
                    3'b110: alu_op = ALU_OR;     // ORI 
                    3'b111: alu_op = ALU_AND;    // ANDI 
                    3'b001: alu_op = ALU_SLLI;   // SLLI 
                    
                    3'b101: begin
                        // for right shifts, funct7 tells us if it's logical or arithmetic
                        if (funct7 == 7'b0000000)
                            alu_op = ALU_SRLI;   // SRLI 
                        else
                            alu_op = ALU_SRAI;   // SRAI 
                    end
                    
                    default: alu_op = ALU_COPY;
                endcase
            end
            
            // LOAD INSTRUCTIONS (0000011): read from memory
            7'b0000011: alu_op = ALU_ADD;  
            
            // STORE INSTRUCTIONS (0100011): write to memory
            7'b0100011: alu_op = ALU_ADD;  
            
            // BRANCH INSTRUCTIONS (1100011): conditional jumps
            7'b1100011: begin
                case (funct3)
                    3'b000: alu_op = ALU_BEQ;   // BEQ 
                    3'b001: alu_op = ALU_BNE;   // BNE 
                    3'b100: alu_op = ALU_BLT;   // BLT 
                    3'b101: alu_op = ALU_BGE;   // BGE 
                    3'b110: alu_op = ALU_BLTU;  // BLTU 
                    3'b111: alu_op = ALU_BGEU;  // BGEU 
                    
                    default: alu_op = ALU_COPY;
                endcase
            end
            
            // JAL (1101111): jal x1, function  (jump to function, save return address in x1)
            7'b1101111: alu_op = ALU_JAL;

            // JALR (1100111): jalr x0, 0(x1)  (jump to address in x1)
            7'b1100111: alu_op = ALU_JALR;

            // AUIPC (0010111): auipc x1, 0x12345  (x1 = PC + 0x12345000)
            7'b0010111: alu_op = ALU_AUIPC;
            
            // LUI (0110111): lui x1, 0x12345  (x1 = 0x12345000)
            7'b0110111: alu_op = ALU_COPY;

            default: alu_op = ALU_COPY;
        endcase
    end

endmodule