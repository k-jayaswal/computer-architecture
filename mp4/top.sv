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

module top (
    input  logic clk,
    output logic LED,
    output logic RGB_R,
    output logic RGB_G,
    output logic RGB_B
);

    // CPU <-> Memory Interface - Instruction Memory
    logic [31:0] imem_address;
    logic [31:0] imem_data_out;

    // CPU <-> Memory Interface - Data Memory
    logic        dmem_wren;
    logic [2:0]  funct3;
    logic [31:0] dmem_address;
    logic [31:0] dmem_data_in;
    logic [31:0] dmem_data_out;

    // LED signals from memory (active high)
    logic led_active_high;
    logic red_active_high;
    logic green_active_high;
    logic blue_active_high;

    logic rst = 1'b1; // start with reset asserted
    logic [4:0] delay_rst = 4'b0000;
    always_ff@(posedge clk) begin
        if (delay_rst > 2)
            rst <= 1'b0;
        else delay_rst <= delay_rst + 1;
    end

    // CPU core
    riscv_core cpu(
        .clk(clk),
        .rst(rst),
        .imem_address(imem_address),
        .imem_data_out(imem_data_out),
        .dmem_wren(dmem_wren),
        .funct3(funct3),
        .dmem_address(dmem_address),
        .dmem_data_in(dmem_data_in),
        .dmem_data_out(dmem_data_out)
    );

    // memory
    memory #(
        .IMEM_INIT_FILE_PREFIX("rv32i_test")
    ) mem (
        .clk(clk),
        .funct3(funct3),
        .dmem_wren(dmem_wren),
        .dmem_address(dmem_address),
        .dmem_data_in(dmem_data_in),
        .dmem_data_out(dmem_data_out),
        .imem_address(imem_address),
        .imem_data_out(imem_data_out),
        .reset(memory_reset),
        .led(led_active_high),
        .red(red_active_high),
        .green(green_active_high),
        .blue(blue_active_high)
    );

    // Active-high memory → active-low board LEDs
    assign LED   = ~led_active_high;
    assign RGB_R = ~red_active_high;
    assign RGB_G = ~green_active_high;
    assign RGB_B = ~blue_active_high;

endmodule
