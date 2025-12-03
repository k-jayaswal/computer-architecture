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

`include "alu_types.sv"

module alu(
    input  logic [31:0] a,
    input  logic [31:0] b,
    input  alu_op_t     alu_op_in,
    output logic [31:0] result,
    output logic        zero
);

    logic [4:0] shamt;
    assign shamt = b[4:0];

    always_comb begin
        case (alu_op_in)
            // R-type instructions
            ALU_ADD:   result = a + b;
            ALU_SUB:   result = a - b;
            ALU_SLL:   result = a << shamt;
            ALU_SLT:   result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;
            ALU_SLTU:  result = (a < b) ? 32'd1 : 32'd0;
            ALU_XOR:   result = a ^ b;
            ALU_SRL:   result = a >> shamt;
            ALU_OR:    result = a | b;
            ALU_AND:   result = a & b;
            ALU_SRA:   result = $signed(a) >>> shamt;
            ALU_COPY:  result = a;

            // I-type instructions
            ALU_SLLI:  result = a << shamt;
            ALU_SRLI:  result = a >> shamt;
            ALU_SRAI:  result = $signed(a) >>> shamt;

            // B-type instructions
            ALU_BEQ:   result = (a == b) ? 32'd1 : 32'd0;
            ALU_BNE:   result = (a != b) ? 32'd1 : 32'd0;
            ALU_BLT:   result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;
            ALU_BGE:   result = ($signed(a) >= $signed(b)) ? 32'd1 : 32'd0;
            ALU_BLTU:  result = (a < b) ? 32'd1 : 32'd0;
            ALU_BGEU:  result = (a >= b) ? 32'd1 : 32'd0;

            // JAL / JALR / AUIPC
            ALU_JAL:   result = a + b;
            ALU_JALR:  result = a + b;
            ALU_AUIPC: result = a + b;

            default:   result = 32'd0;
        endcase
    end

    assign zero = (result == 32'd0);

endmodule
