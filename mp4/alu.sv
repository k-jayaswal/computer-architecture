module alu(
    input logic [31:0] a,
    input logic [31:0] b,
    // input logic [2:0] funct3,
    // input logic [6:0] funct7,
    input logic alu_op, alu_control,
    output logic [31:0] result
)

// define ALU operation codes
typedef enum logic [4:0] {
    ALU_ADD,    // add (R/I-type, load/store addr, JAL/JALR)
    ALU_SUB,    // subtract (R-type)
    ALU_SLL,    // shift left logical
    ALU_SLT,    // set less than signed
    ALU_SLTU,   // set less than unsigned
    ALU_XOR,    // xor
    ALU_SRL,    // shift right logical
    ALU_SRA,    // shift right arithmetic
    ALU_OR,     // or
    ALU_AND,    // and
    ALU_COPY,   // pass through
    ALU_SLLI,   // shift left logical immediate
    ALU_SRLI,   // shift right logical immediate
    ALU_SRAI,   // shift right arithmetic immediate
    ALU_BEQ,    // branch equal
    ALU_BNE,    // branch not equal
    ALU_BLT,    // branch less than signed
    ALU_BGE,    // branch greater/equal signed
    ALU_BLTU,   // branch less than unsigned
    ALU_BGEU    // branch greater/equal unsigned
} alu_op;

    always_comb begin
        case (alu_control)
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

            // Default
            default:    result = 32'd0;
        endcase
    end


endmodule