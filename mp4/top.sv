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
    parameter IMEM_INIT_FILE_PREFIX = "program",  // prefix for instruction memory files
    parameter DMEM_INIT_FILE_PREFIX = "",         // prefix for data memory files
    parameter CLK_FREQ = 12000000                  // 12 MHz clock
)(
    input  logic clk,    
    input  logic rst,     
    output logic LED,      // user LED (active low on board)
    output logic RGB_R,    // red LED (active low on board)
    output logic RGB_G,    // green LED (active low on board)
    output logic RGB_B     // blue LED (active low on board)
);

    // CPU to Memory Interface - Instruction Memory
    logic [31:0] imem_address;     // address of instruction to fetch
    logic [31:0] imem_data_out;    // instruction data from memory
    
    // CPU to Memory Interface - Data Memory
    logic        dmem_wren;        // write enable for data memory
    logic [2:0]  funct3;           // access size (byte/half/word)
    logic [31:0] dmem_address;     // address for data memory
    logic [31:0] dmem_data_in;     // data to write 
    logic [31:0] dmem_data_out;    // data read from memory
    
    // LED signals (active high from memory)
    logic led_active_high;
    logic red_active_high;
    logic green_active_high;
    logic blue_active_high;
    
    // reset from memory (unused but required by memory module)
    logic memory_reset;

    // instantiate CPU core
    riscv_core cpu(
        .clk(clk),
        .rst(rst),

        // instruction memory interface
        .imem_address(imem_address),
        .imem_data_out(imem_data_out),

        // data memory interface
        .dmem_wren(dmem_wren),
        .funct3(funct3),
        .dmem_address(dmem_address),
        .dmem_data_in(dmem_data_in),
        .dmem_data_out(dmem_data_out)
    );
    
    // instantiate memory module
    memory #(
        .IMEM_INIT_FILE_PREFIX(IMEM_INIT_FILE_PREFIX),
        .DMEM_INIT_FILE_PREFIX(DMEM_INIT_FILE_PREFIX),
        .CLK_FREQ(CLK_FREQ)
    ) mem(
        .clk(clk),
        
        // data memory interface
        .funct3(funct3),
        .dmem_wren(dmem_wren),
        .dmem_address(dmem_address),
        .dmem_data_in(dmem_data_in),
        .dmem_data_out(dmem_data_out),
        
        // instruction memory interface
        .imem_address(imem_address),
        .imem_data_out(imem_data_out),
        
        // peripherals
        .reset(memory_reset),
        .led(led_active_high),
        .red(red_active_high),
        .green(green_active_high),
        .blue(blue_active_high)
    );

    // LED output conversion (memory outputs active high, board expects active low)
    assign LED   = ~led_active_high;
    assign RGB_R = ~red_active_high;
    assign RGB_G = ~green_active_high;
    assign RGB_B = ~blue_active_high;

endmodule