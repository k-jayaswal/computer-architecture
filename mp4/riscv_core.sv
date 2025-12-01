// RISC-V Core (CPU Datapath)

// Purpose: Implements the complete datapath that connects all CPU components
//          and routes data between them according to control signals.
//
// Why this module exists:
//   This is the "assembly line" of the CPU. While individual modules perform specific
//   operations, we need something to connect them all together and route data correctly.
//   The core instantiates all submodules, implements multiplexers to select data paths, 
//   manages intermediate registers for multicycle operation, and interfaces with
//   memory. It's the structural backbone that makes the CPU function.
//
// What it does:
//   - Instantiates all CPU components 
//   - Implements multiplexers to route data based on control signals
//   - Manages intermediate storage registers (IR, data registers, ALU output)
//   - Connects to instruction and data memory
//   - Executes the fetch-decode-execute-writeback cycle
//   - Interfaces with the outside world (memory reads/writes)

`include "alu.sv"
`include "alu_control.sv"
`include "imm_gen.sv"
`include "program_counter.sv"
`include "register_file.sv"
`include "control_unit.sv"
`include "decoder.sv"

module riscv_core(
    input  logic        clk,
    input  logic        rst,
    
    // instruction memory interface
    output logic [31:0] imem_address,      // address to fetch instruction from
    input  logic [31:0] imem_data_out,     // instruction fetched from memory

    // data memory interface
    output logic        dmem_wren,         // write enable
    output logic [2:0]  funct3,            // access size (byte/half/word)
    output logic [31:0] dmem_address,      // address for data memory
    output logic [31:0] dmem_data_in,      // data to write
    input  logic [31:0] dmem_data_out      // data read from memory
);
    // PC
    logic [31:0] pc;             
    logic [31:0] next_pc;        
    
    // instruction fields 
    logic [31:0] instruction;    
    logic [6:0]  opcode;
    logic [4:0]  rd, rs1, rs2;
    logic [2:0]  funct3_internal;  // internal funct3 (output to memory port)
    logic [6:0]  funct7;
    
    // register file
    logic [31:0] reg_read_data1;  
    logic [31:0] reg_read_data2;  
    logic [31:0] reg_write_data;  
    
    // immediate generator
    logic [31:0] imm;
    
    // ALU
    logic [31:0] alu_a, alu_b;  
    logic [31:0] alu_result;      
    logic        alu_zero;      
    alu_op_t     alu_op;         
    
    // control signals
    logic        pc_write;
    logic        pc_write_cond;
    logic        ir_write;
    logic        reg_write;
    logic        mem_read;
    logic        mem_write;
    logic        mem_to_reg;
    logic        alu_src_a;
    logic [1:0]  alu_src_b;
    logic [1:0]  pc_source;
    logic [2:0]  imm_type;
    
    // intermediate registers 
    logic [31:0] instr_reg;       // stores fetched instruction
    logic [31:0] data_reg;        // stores data read from memory
    logic [31:0] alu_out_reg;     // stores ALU result
    logic [31:0] a_reg, b_reg;    // store register file outputs

    // MODULE INSTANTIATIONS

    program_counter pc_inst(
        .clk(clk),
        .rst(rst),
        .pc_write(pc_write | (pc_write_cond & alu_result[0])),  
        .next_pc(next_pc),
        .pc(pc)
    );
    
    // instruction register: stores the instruction that was just fetched from memory
    always_ff @(posedge clk) begin
        if (rst)
            instr_reg <= 32'd0;
        else if (ir_write)
            instr_reg <= imem_data_out;  // capture instruction during FETCH
    end
    
    // splits instruction into fields 
    decoder dec_inst(
        .instruction(instr_reg),
        .opcode(opcode),
        .rd(rd),
        .funct3(funct3_internal),
        .rs1(rs1),
        .rs2(rs2),
        .funct7(funct7)
    );
    
    // 32 registers (x0-x31)
    register_file rf_inst(
        .clk(clk),
        .rst(rst),
        .reg_write(reg_write),
        .read_reg1(rs1),
        .read_reg2(rs2),
        .write_reg(rd),
        .write_data(reg_write_data),
        .read_data1(reg_read_data1),
        .read_data2(reg_read_data2)
    );
    
    // stores outputs from register file
    always_ff @(posedge clk) begin
        if (rst) begin
            a_reg <= 32'd0;
            b_reg <= 32'd0;
        end
        else begin
            a_reg <= reg_read_data1;  // store rs1 value
            b_reg <= reg_read_data2;  // store rs2 value
        end
    end
    
    // extracts and sign-extends immediate values
    imm_gen imm_gen_inst(
        .instruction(instr_reg),
        .opcode(opcode),
        .imm(imm)
    );
    
    // what operation ALU should perform
    alu_control alu_ctrl_inst(
        .opcode(opcode),
        .funct3(funct3_internal),
        .funct7(funct7),
        .alu_op(alu_op)
    );
    
    // performs ALU operation
    alu alu_inst(
        .a(alu_a),
        .b(alu_b),
        .alu_op_in(alu_op),
        .result(alu_result),
        .zero(alu_zero)
    );
    
    // stores ALU result
    always_ff @(posedge clk) begin
        if (rst)
            alu_out_reg <= 32'd0;
        else
            alu_out_reg <= alu_result;
    end

    // stores data read from memory
    always_ff @(posedge clk) begin
        if (rst)
            data_reg <= 32'd0;
        else
            data_reg <= dmem_data_out;
    end
    
    // generates all control signals
    control_unit ctrl_inst(
        .clk(clk),
        .rst(rst),
        .opcode(opcode),
        .funct3(funct3_internal),
        .alu_zero(alu_zero),
        .alu_result(alu_result),
        .pc_write(pc_write),
        .pc_write_cond(pc_write_cond),
        .ir_write(ir_write),
        .reg_write(reg_write),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .mem_to_reg(mem_to_reg),
        .alu_src_a(alu_src_a),
        .alu_src_b(alu_src_b),
        .pc_source(pc_source),
        .imm_type(imm_type)
    );

    // DATAPATH MULTIPLEXERS: selects which data goes where based on control signals
    
    // ALU
    // selects between rs1 and PC for ALU input A (0=rs1, 1=PC)
    assign alu_a = alu_src_a ? pc : a_reg;
    
    // selects what goes into ALU input B (00=rs2, 01=immediate, 10=4)
    always_comb begin
        case (alu_src_b)
            2'b00:   alu_b = b_reg;    // rs2
            2'b01:   alu_b = imm;      // Immediate
            2'b10:   alu_b = 32'd4;    // Constant 4
            default: alu_b = 32'd0;
        endcase
    end
    
    // PC
    // determines the next PC value (00=PC+4, 01=PC+branch_offset, 10=jump_target)
    always_comb begin
        case (pc_source)
            2'b00: next_pc = alu_result;              // PC + 4 (from ALU)
            2'b01: next_pc = pc + imm;                // PC + branch offset
            2'b10: begin
                if (opcode == 7'b1100111)              // JALR
                    next_pc = (a_reg + imm) & ~32'd1;  // (rs1 + imm) & ~1
                else                                    // JAL
                    next_pc = pc + imm;                // PC + jump offset
            end
            default: next_pc = pc + 32'd4;
        endcase
    end
    
    // Register Write Data
    // selects what data to write back to the register file
    always_comb begin
        if (opcode == 7'b1101111 || opcode == 7'b1100111) begin
            // JAL or JALR: write return address (PC + 4)
            reg_write_data = pc + 32'd4;
        end
        else if (opcode == 7'b0110111) begin
            // LUI: write immediate directly
            reg_write_data = imm;
        end
        else if (mem_to_reg) begin
            // Load instruction: write data from memory
            reg_write_data = data_reg;
        end
        else begin
            // arithmetic/logic: write ALU result
            reg_write_data = alu_out_reg;
        end
    end

    // MEMORY INTERFACE: connect internal signals to memory ports
    
    // instruction memory
    assign imem_address = pc;
    
    // data memory
    assign dmem_address = alu_out_reg;    // address from ALU
    assign dmem_data_in = b_reg;          // data from rs2
    assign dmem_wren = mem_write;         // write enable
    assign funct3 = funct3_internal;      // access size

endmodule