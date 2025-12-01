// Control Unit (Finite State Machine)

// Purpose: Orchestrates the entire CPU by generating control signals for the
//          datapath based on the current instruction and execution state.
//
// Why this module exists:
//   A multicycle CPU executes instructions in multiple steps (fetch, decode,
//   execute, memory access, writeback). We need a "conductor" that coordinates
//   when each step happens and what each component should do. The FSM moves
//   through different states, and in each state, it generates the appropriate
//   control signals to tell the datapath what to do. Separating control from
//   datapath is a fundamental design principle that makes the CPU modular,
//   testable, and easier to understand.
//
// What it does:
//   - Implements a 12-state FSM that sequences instruction execution
//   - Generates 10+ control signals that configure the datapath
//   - Determines state transitions based on instruction type (opcode)
//   - Handles all instruction classes: R-type, I-type, Load, Store, Branch, Jump
//   - Controls when to: update PC, read/write memory, write registers, etc.
//
// States: FETCH → DECODE → EXECUTE/MEMORY → WRITEBACK → FETCH (repeat)

module fsm_control_unit(
    input  logic        clk,           
    input  logic        rst,           
    input  logic [6:0]  opcode,        
    input  logic [2:0]  funct3,        
    input  logic        alu_zero, // is ALU result zero? (for branch decisions)
    input  logic [31:0] alu_result, // ALU result (check bit 0 for branch conditions)

    output logic        pc_write, // update PC? (1=yes, 0=no)
    output logic        pc_write_cond, // update PC only if branch condition is true?
    output logic        ir_write, // store the fetched instruction?
    output logic        reg_write, // write to a register?
    output logic        mem_read, // read from memory?
    output logic        mem_write, // write to memory?
    output logic        mem_to_reg, // what to write to register? 
    output logic        alu_src_a, // where does ALU input A come from? 
    output logic [1:0]  alu_src_b, // where does ALU input B come from? 
    output logic [1:0]  pc_source, // next PC?
    output logic [2:0]  imm_type 
);

    // FSM states
    typedef enum logic [3:0] {
        FETCH,      // Step 1: fetch instruction from memory
        DECODE,     // Step 2: decode instruction and read registers
        MEMADR,     // Step 3: calculate memory address (for load/store)
        MEMREAD,    // Step 4: read from memory (for load instructions)
        MEMWB,      // Step 5: write memory data to register (for load)
        MEMWRITE,   // Step 6: write to memory (for store instructions)
        EXECUTER,   // Step 7: execute R-type instruction 
        EXECUTEI,   // Step 8: execute I-type instruction 
        ALUWB,      // Step 9: write ALU result back to register
        BRANCH,     // Step 10: evaluate branch condition
        JUMP,       // Step 11: execute JAL 
        JUMPR       // Step 12: execute JALR
    } state_t;
    
    state_t current_state, next_state;

    // state register: memory for holding current state
    always_ff @(posedge clk) begin
        if (rst)
            current_state <= FETCH; // reset
        else
            current_state <= next_state;
    end
    
    // next state logic: where to go after FETCH
    always_comb begin
        next_state = current_state;
        
        case (current_state)
            // FETCH: gets instruction from memory, goes to DECODE
            FETCH: begin
                next_state = DECODE;
            end
            
            // DECODE: determines which instruction, preparees for execution
            DECODE: begin
                case (opcode)
                    // R-type
                    7'b0110011: next_state = EXECUTER;
                    
                    // I-type arithmetic
                    7'b0010011: next_state = EXECUTEI;
                    
                    // Load
                    7'b0000011: next_state = MEMADR;
                    
                    // Store
                    7'b0100011: next_state = MEMADR;
                    
                    // Branch
                    7'b1100011: next_state = BRANCH;
                    
                    // JAL
                    7'b1101111: next_state = JUMP;
                    
                    // JALR
                    7'b1100111: next_state = JUMPR;
                    
                    // LUI
                    7'b0110111: next_state = ALUWB;
                    
                    // AUIPC
                    7'b0010111: next_state = EXECUTEI;
                    
                    // unknown instruction
                    default: next_state = FETCH;
                endcase
            end
            
            // MEMADR: calculate memory address, go to MEMREAD or MEMWRITE
            MEMADR: begin
                if (opcode == 7'b0000011)
                    next_state = MEMREAD;   // Load instruction
                else
                    next_state = MEMWRITE;  // Store instruction
            end
            
            // MEMREAD: read data from memory, go to MEMWB 
            MEMREAD: begin
                next_state = MEMWB;
            end
            
            // MEMWRITE: write data to memory, go back to FETCH
            MEMWRITE: begin
                next_state = FETCH;
            end
            
            // MEMWB: writes memory data to register, go back to FETCH
            MEMWB: begin
                next_state = FETCH;
            end
           
            // EXECUTE(R): execute R-type instruction (uses ALU), go to ALUWB
            EXECUTER: begin
                next_state = ALUWB;
            end
           
            // EXECUTE(I): execute I-type instruction (uses ALU with immediate), go to ALUWB)
            EXECUTEI: begin
                next_state = ALUWB;
            end
            
            // ALUWB: write ALU result to register, go back to FETCH
            ALUWB: begin
                next_state = FETCH;
            end
            
            // BRANCH: evaluate branch condition, if true jump to target and if false, go back to FETCH
            BRANCH: begin
                next_state = FETCH;
            end
        
            // JUMP: execute JAL, go to ALUWB
            JUMP: begin
                next_state = ALUWB;  // save return address (PC + 4)
            end
            
            // JUMPR: execute JALR, go to ALUWB
            JUMPR: begin
                next_state = ALUWB;  // save return address (PC + 4)
            end
            
            default: begin
                next_state = FETCH;
            end
            
        endcase
    end

    // output logic
    always_comb begin
        
        // default values
        pc_write = 0;
        pc_write_cond = 0;
        ir_write = 0;
        reg_write = 0;
        mem_read = 0;
        mem_write = 0;
        mem_to_reg = 0;
        alu_src_a = 0;
        alu_src_b = 2'b00;
        pc_source = 2'b00;
        imm_type = 3'd0;
        
        // control signals
        case (current_state)

            FETCH: begin
                mem_read = 1;        // turn on memory read
                ir_write = 1;        // store instruction in IR
                alu_src_a = 1;       // ALU input A = PC
                alu_src_b = 2'b10;   // ALU input B = 4
                pc_write = 1;        // update PC
                pc_source = 2'b00;   // next PC = ALU result (PC + 4)
            end
            
            // just for prepping, no writes
            DECODE: begin
                alu_src_a = 0;       // ALU input A = rs1 
                alu_src_b = 2'b01;   // ALU input B = immediate 
            end
            
            MEMADR: begin
                alu_src_a = 0;       // ALU input A = rs1 
                alu_src_b = 2'b01;   // ALU input B = immediate 
                
                // set immediate type based on load or store
                if (opcode == 7'b0000011)
                    imm_type = 3'd0;  // I-type immediate (load)
                else
                    imm_type = 3'd1;  // S-type immediate (store)
            end
            
            MEMREAD: begin
                mem_read = 1;  // turn on memory read
            end
            
            MEMWB: begin
                reg_write = 1;   // turn on register write
                mem_to_reg = 1;  // write memory data (not ALU result)
            end
    
            MEMWRITE: begin
                mem_write = 1;  // turn on memory write
            end
        
            EXECUTER: begin
                alu_src_a = 0;       // ALU input A = rs1
                alu_src_b = 2'b00;   // ALU input B = rs2
            end
        
            EXECUTEI: begin
                // for AUIPC, use PC; otherwise use rs1
                alu_src_a = (opcode == 7'b0010111) ? 1'b1 : 1'b0;
                alu_src_b = 2'b01;   // ALU input B = immediate
                
                // set immediate type
                if (opcode == 7'b0010111)
                    imm_type = 3'd3;  // U-type immediate (AUIPC)
                else
                    imm_type = 3'd0;  // I-type immediate
            end
            
            ALUWB: begin
                reg_write = 1;   // turn on register write
                mem_to_reg = 0;  // write ALU result
            end

            // if true PC=PC+imm, else PC=PC+4
            BRANCH: begin
                alu_src_a = 0;       // ALU input A = rs1
                alu_src_b = 2'b00;   // ALU input B = rs2
                pc_write_cond = 1;   // update PC if branch taken
                pc_source = 2'b01;   // next PC = PC + branch_offset
                imm_type = 3'd2;     // B-type immediate
            end
           
            JUMP: begin
                alu_src_a = 1;       // ALU input A = PC
                alu_src_b = 2'b10;   // ALU input B = 4 
                pc_write = 1;        // update PC
                pc_source = 2'b10;   // next PC = PC + jump_offset
                imm_type = 3'd4;     // J-type immediate
            end
            
            JUMPR: begin
                alu_src_a = 1;       // ALU input A = PC (for return address)
                alu_src_b = 2'b10;   // ALU input B = 4
                pc_write = 1;        // update PC
                pc_source = 2'b10;   // next PC = (rs1 + offset) & ~1
                imm_type = 3'd0;     // I-type immediate
            end

            default: begin
            end
            
        endcase
    end

endmodule