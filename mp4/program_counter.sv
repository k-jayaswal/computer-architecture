// Program Counter (PC)

// Purpose: Keeps track of which instruction to execute next.
//
// Why this module exists:
//   The CPU needs to remember where it is in the program. The PC is like a
//   bookmark that points to the current instruction's memory address. After
//   each instruction, the PC updates to point to the next instruction (or
//   jumps to a different location for branches/jumps). Separating this into
//   its own module makes the design cleaner and easier to control.
//
// What it does:
//   - Stores the current instruction address (32-bit value)
//   - Updates to next_pc on each clock cycle when pc_write is enabled
//   - Resets to 0x1000 (start of instruction memory) on reset
//   - Can be held constant during multi-cycle instruction execution
//
// Typical behavior:
//   - Normal execution: PC = PC + 4 (next instruction)
//   - Branch taken: PC = PC + offset
//   - Jump: PC = target address

module program_counter(
    input  logic        clk,        
    input  logic        rst,        // active-high reset
    input  logic        pc_write,   // enable signal for PC update
    input  logic [31:0] next_pc,    // next PC value
    output logic [31:0] pc          // current PC
);

    always_ff @(posedge clk) begin
        if (rst) begin
            pc <= 32'h00001000;    // reset PC to start of instruction memory (0x1000)
        end
        else if (pc_write) begin
            pc <= next_pc;         // update PC only when pc_write is high
        end
    end

endmodule