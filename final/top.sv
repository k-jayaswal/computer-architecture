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

    logic [3:0]  current_state; // for debugging purposes

    // LED signals from memory (active high)
    logic led_active_high;
    logic red_active_high;
    logic green_active_high;
    logic blue_active_high;


    parameter SLOW_COUNTER = 1000000;

    logic [$clog2(SLOW_COUNTER) - 1:0] counter = 0;
    logic slow_clk;

    initial begin
        slow_clk = 1'b0;
        counter = 0;
    end

    always_ff @(posedge clk) begin
        if (counter >= SLOW_COUNTER) begin
            slow_clk <= ~slow_clk;
            counter <= 0;
        end else begin
            counter <= counter + 1;
        end
    end

    logic rst = 1'b1; // start with reset asserted
    logic [4:0] delay_rst = 4'b0000;
    always_ff@(posedge slow_clk) begin
        if (delay_rst > 1)
            rst <= 1'b0;
        else delay_rst <= delay_rst + 1;
    end

    // CPU core
    riscv_core cpu(
        .clk(slow_clk),
        .rst(rst),
        .imem_address(imem_address),
        .imem_data_out(imem_data_out),
        .dmem_wren(dmem_wren),
        .funct3(funct3),
        .dmem_address(dmem_address),
        .dmem_data_in(dmem_data_in),
        .dmem_data_out(dmem_data_out),
        .current_state(current_state)
    );

    // memory
    memory #(
        .IMEM_INIT_FILE_PREFIX("rv32i_test")
    ) mem (
        .clk(slow_clk),
        .funct3(funct3),
        .dmem_wren(dmem_wren),
        .dmem_address(dmem_address),
        .dmem_data_in(dmem_data_in),
        .dmem_data_out(dmem_data_out),
        .imem_address(imem_address),
        .imem_data_out(imem_data_out),
        .reset(memory_reset)
    );

    always_comb begin
        // Default to OFF
        led_active_high   = 0; 
        red_active_high = 0; 
        green_active_high = 0; 
        blue_active_high = 0;

        case (current_state)
            // FETCH: 
            4'd0: led_active_high = 1; 
            
            // DECODE: 
            4'd1: blue_active_high = 1;

            // EXECUTE 
            4'd6, 4'd7, 4'd8: green_active_high = 1;

            // MEMORY 
            4'd2, 4'd3, 4'd4, 4'd5: red_active_high = 1;

            // BRANCH / JUMP: 
            4'd9, 4'd10, 4'd11: begin
                red_active_high = 1;
                blue_active_high = 1;
            end
            
            default: led_active_high = 1; 
        endcase
    end
    assign LED   = ~led_active_high;
    assign RGB_R = ~red_active_high;
    assign RGB_G = ~green_active_high;
    assign RGB_B = ~blue_active_high;


endmodule