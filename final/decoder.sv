// Instruction Decoder

// Purpose: Extracts individual fields from a 32-bit RISC-V instruction.
//
// Why this module exists:
//   Every RISC-V instruction is 32 bits with different fields packed into
//   specific bit positions (opcode, rd, rs1, rs2, funct3, funct7). Rather
//   than repeatedly slicing these bits throughout the design, we extract
//   them once in a dedicated decoder module.
//
// What it does:
//   - Takes a 32-bit instruction as input
//   - Extracts and outputs each field:
//     • opcode [6:0]   - Instruction type
//     • rd [11:7]      - Destination register
//     • funct3 [14:12] - Function code (operation details)
//     • rs1 [19:15]    - Source register 1
//     • rs2 [24:20]    - Source register 2
//     • funct7 [31:25] - Function code (for R-type)

module decoder(
    input  logic [31:0] instruction, 
    output logic [6:0]  opcode,      
    output logic [4:0]  rd, // register destination: where to write result
    output logic [4:0]  rs1, // source register 1
    output logic [4:0]  rs2, // source register 2
    output logic [2:0]  funct3, 
    output logic [6:0]  funct7
);

    assign opcode = instruction[6:0];    
    assign rd     = instruction[11:7];   
    assign funct3 = instruction[14:12];   
    assign rs1    = instruction[19:15];  
    assign rs2    = instruction[24:20];   
    assign funct7 = instruction[31:25];  

endmodule