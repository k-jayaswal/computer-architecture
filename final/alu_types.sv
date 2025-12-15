`ifndef ALU_TYPES_H
`define ALU_TYPES_H

typedef enum logic [4:0] {
    ALU_ADD,    // Addition: a + b
    ALU_SUB,    // Subtraction: a - b
    ALU_SLL,    // Shift Left Logical: a << b
    ALU_SLT,    // Set Less Than (signed): (a < b) ? 1 : 0
    ALU_SLTU,   // Set Less Than (unsigned): (a < b) ? 1 : 0
    ALU_XOR,    // Exclusive OR: a ^ b
    ALU_SRL,    // Shift Right Logical: a >> b
    ALU_SRA,    // Shift Right Arithmetic: a >>> b (keeps sign)
    ALU_OR,     // Bitwise OR: a | b
    ALU_AND,    // Bitwise AND: a & b
    ALU_COPY,   // Just copy b to output
    ALU_SLLI,   // Shift Left Logical Immediate (same as SLL)
    ALU_SRLI,   // Shift Right Logical Immediate (same as SRL)
    ALU_SRAI,   // Shift Right Arithmetic Immediate (same as SRA)
    ALU_BEQ,    // Branch if Equal: (a == b) ? 1 : 0
    ALU_BNE,    // Branch if Not Equal: (a != b) ? 1 : 0
    ALU_BLT,    // Branch if Less Than (signed)
    ALU_BGE,    // Branch if Greater or Equal (signed)
    ALU_BLTU,   // Branch if Less Than (unsigned)
    ALU_BGEU,   // Branch if Greater or Equal (unsigned)
    ALU_JAL,    // Jump and Link
    ALU_JALR,   // Jump and Link Register
    ALU_AUIPC   // Add Upper Immediate to PC
} alu_op_t;

`endif // ALU_TYPES_H