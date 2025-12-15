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

    logic [31:0] imm_i_type;
    logic [31:0] imm_s_type;
    logic [31:0] imm_b_type;
    logic [31:0] imm_u_type;
    logic [31:0] imm_j_type;

    assign imm_i_type = {{20{instruction[31]}}, instruction[31:20]};

    assign imm_s_type = {{20{instruction[31]}},
                        instruction[31:25],
                        instruction[11:7]};

    assign imm_b_type = {{20{instruction[31]}},
                        instruction[7],
                        instruction[30:25],
                        instruction[11:8],
                        1'b0};

    assign imm_u_type = {instruction[31:12], 12'b0};

    assign imm_j_type = {{12{instruction[31]}},
                        instruction[19:12],
                        instruction[20],
                        instruction[30:21],
                        1'b0};

    always_comb begin
        case (opcode)
            7'b0010011,
            7'b0000011,
            7'b1100111: imm = imm_i_type;  // I-type immediate

            7'b0100011: imm = imm_s_type;  // S-type immediate

            7'b1100011: imm = imm_b_type; // B-type immediate

            7'b0110111,
            7'b0010111: imm = imm_u_type; // U-type immediate

            7'b1101111: imm = imm_j_type;  // J-type immediate

            default:    imm = 32'b0;
        endcase
    end

endmodule