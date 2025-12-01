// Top-Level System Module

// Purpose: Integrates the complete RISC-V system by connecting the CPU core
//          to memory and peripherals.
//
// Why this module exists:
//   This is the highest level of the design hierarchy - the "motherboard"
//   that connects all major components. It instantiates the CPU core and
//   memory module, wires them together, and provides external I/O connections
//   (clock, reset, LEDs). This is the module that gets synthesized to the
//   FPGA or simulated in a testbench. It represents the complete working system.
//
// What it does:
//   - Instantiates the RISC-V CPU core
//   - Instantiates the memory module (instruction + data memory + peripherals)
//   - Connects CPU memory interface signals to the memory module
//   - Routes clock and reset to all components
//   - Provides LED outputs to the outside world
//   - Serves as the single entry point for synthesis or simulation

`include "riscv_core.sv"
`include "memory.sv"

module top #(
    parameter INIT_FILE = "program.hex"  // memory initialization file
)(
    input  logic clk,    
    input  logic rst,     
    output logic led,   
    output logic red,  
    output logic green,  
    output logic blue   
);

    // CPU to Memory Interface
    logic [31:0] instr_addr; // address of instruction to fetch
    logic [31:0] instr_data; // instruction data from memory
    
    // Data Memory Interface (CPU reads/writes data)
    logic        data_mem_write;  // write enable for data memory
    logic [2:0]  data_funct3; 
    logic [31:0] data_write_addr; // address to write to
    logic [31:0] data_write_data; // data to write 
    logic [31:0] data_read_addr; // address to read from
    logic [31:0] data_read_data; // data read from memory

    riscv_core cpu(
        .clk(clk),
        .rst(rst),

        .instr_addr(instr_addr),
        .instr_data(instr_data),

        .mem_write(data_mem_write),
        .mem_funct3(data_funct3),
        .mem_write_addr(data_write_addr),
        .mem_write_data(data_write_data),
        .mem_read_addr(data_read_addr),
        .mem_read_data(data_read_data)
    );
    
    memory #(
        .INIT_FILE(INIT_FILE)
    ) mem(
        .clk(clk),
        
        .write_mem(data_mem_write),
        .funct3(data_funct3),
        .write_address(data_write_addr),
        .write_data(data_write_data),
     
        .read_address(instr_addr),  // during FETCH, read instruction
        .read_data(instr_data),
        
        .led(led),
        .red(red),
        .green(green),
        .blue(blue)
    );

endmodule