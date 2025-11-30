// ALU (Arithmetic Logic Unit)

// Purpose: Performs all arithmetic and logical operations for the processor.
//
// Why this module exists:
//   Every CPU needs a component that can do math (add, subtract) and logic
//   (AND, OR, XOR). Rather than duplicating this logic throughout the design,
//   we centralize all computational operations in one reusable ALU module.
//
// What it does:
//   - Takes two 32-bit inputs (a and b)
//   - Performs one of 23 different operations based on alu_op_in
//   - Outputs a 32-bit result
//   - Provides a zero flag for branch decisions
//
// Operations supported:
//   Arithmetic: ADD, SUB
//   Logical: AND, OR, XOR
//   Shifts: SLL, SRL, SRA
//   Comparisons: SLT, SLTU, BEQ, BNE, BLT, BGE, BLTU, BGEU

module alu(
    input  logic [31:0] a,            
    input  logic [31:0] b,           
    input  alu_op_t     alu_op_in,  
    output logic [31:0] result,      
    output logic        zero // for branches
);

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
    ALU_JAL,    // Jump and Link (not really used in ALU)
    ALU_JALR,   // Jump and Link Register (not really used in ALU)
    ALU_AUIPC   // Add Upper Immediate to PC (not really used in ALU)
} alu_op_t;

    always_comb begin
        case (alu_op_in)
            // R-type instructions
            ALU_ADD:   result = a + b;
            ALU_SUB:   result = a - b;
            ALU_SLL:   result = a << b[4:0];
            ALU_SLT:   result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;
            ALU_SLTU:  result = (a < b) ? 32'd1 : 32'd0;
            ALU_XOR:   result = a ^ b;
            ALU_SRL:   result = a >> b[4:0];
            ALU_OR:    result = a | b;
            ALU_AND:   result = a & b;
            ALU_SRA:   result = $signed(a) >>> b[4:0];
            ALU_COPY:  result = a;

            // I-type instructions
            ALU_SLLI:   result = a << b[4:0];
            ALU_SRLI:   result = a >> b[4:0];
            ALU_SRAI:   result = $signed(a) >>> b[4:0];

            // B-type instructions
            ALU_BEQ:    result = (a == b) ? 32'd1 : 32'd0;
            ALU_BNE:    result = (a != b) ? 32'd1 : 32'd0;
            ALU_BLT:    result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;
            ALU_BGE:    result = ($signed(a) >= $signed(b)) ? 32'd1 : 32'd0;
            ALU_BLTU:   result = (a < b) ? 32'd1 : 32'd0;
            ALU_BGEU:   result = (a >= b) ? 32'd1 : 32'd0;

            // for JAL/JALR/AUIPC, ALU just passes through or adds
            ALU_JAL:   result = a + b; 
            ALU_JALR:  result = a + b;  
            ALU_AUIPC: result = a + b;  
            
            default:    result = 32'd0;
        endcase
    end

    assign zero = (result == 32'd0);

endmodule