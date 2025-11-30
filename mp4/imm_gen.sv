// Immediate Generator

// Purpose: Extracts and sign-extends immediate values from instructions.
//
// Why this module exists:
//   Many RISC-V instructions contain constant values (immediates) encoded
//   directly in the instruction bits. However, these immediates are stored
//   in different bit positions depending on the instruction type (I, S, B,
//   U, J). Rather than extracting them in multiple places, we centralize
//   this logic in one module that handles all five formats correctly.
//
// What it does:
//   - Takes a 32-bit instruction and its opcode
//   - Identifies the instruction type (I, S, B, U, or J)
//   - Extracts the immediate from the correct bit positions
//   - Sign-extends it to 32 bits
//   - Outputs a ready-to-use immediate value
    
module imm_gen(
    input  logic [31:0] instruction,
    input  logic [6:0]  opcode,
    output logic [31:0] imm
);

    always_comb begin
        case (opcode)
            // I-type: ADDI, SLTI, XORI, ORI, ANDI, LW, LH, LB, JALR
            7'b0010011, 7'b0000011, 7'b1100111:
                imm = {{20{instruction[31]}}, instruction[31:20]};

            // S-type: SW, SH, SB
            7'b0100011:
                imm = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};

            // B-type: BEQ, BNE, BLT, BGE, BLTU, BGEU
            7'b1100011:
                imm = {{19{instruction[31]}}, instruction[31], instruction[7], 
                       instruction[30:25], instruction[11:8], 1'b0};

            // U-type: LUI, AUIPC
            7'b0110111, 7'b0010111:
                imm = {instruction[31:12], 12'd0};

            // J-type: JAL
            7'b1101111:
                imm = {{11{instruction[31]}}, instruction[31], instruction[19:12],
                       instruction[20], instruction[30:21], 1'b0};

            default:
                imm = 32'd0;
        endcase
    end

endmodule