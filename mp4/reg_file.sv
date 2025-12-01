// Register File

// Purpose: Provides fast storage for the CPU's 32 general-purpose registers.
//
// Why this module exists:
//   The CPU needs a small amount of very fast memory to hold data it's
//   currently working with. Reading from main memory is slow, so we keep
//   frequently-used values in registers. The RISC-V ISA defines 32 registers
//   (x0-x31), and this module implements them with the required behavior
//   (x0 always reads as zero, two simultaneous reads, one write per cycle).
//
// What it does:
//   - Stores 32 registers, each holding a 32-bit value
//   - Supports two simultaneous reads (for instructions like add x3, x1, x2)
//   - Supports one write per clock cycle
//   - Enforces that x0 (register 0) always reads as zero
//   - Provides synchronous write and asynchronous read

module reg_file(
    input  logic        clk,
    input  logic        rst,
    input  logic        reg_write, // 1 = write enabled, 0 = don't write
    input  logic [4:0]  write_reg, // which register to write to (0-31)
    input  logic [31:0] write_data, // the number to write
    input  logic [4:0]  read_reg1, // which register to read (0-31)
    output logic [31:0] read_data1, // the number we read
    input  logic [4:0]  read_reg2, // which register to read (0-31)
    output logic [31:0] read_data2 // the number we read
);
    logic [31:0] registers [0:31];
    integer i;

    initial begin // set everything to 0
        for (i = 0; i < 32; i = i + 1) begin
            registers[i] = 32'd0; 
        end
    end

    always_ff @(posedge clk) begin // write data to register
        if (rst) begin // clear all registers if reset is high
            for (i = 0; i < 32; i = i + 1) begin
                registers[i] <= 32'd0;
            end
        end
        
        else if (reg_write && write_reg != 5'd0) begin // save data to register except for x0
            registers[write_reg] <= write_data;
        end
    end

    // read port 1 and port 2
    assign read_data1 = (read_reg1 == 5'd0) ? 32'd0 : registers[read_reg1];
    assign read_data2 = (read_reg2 == 5'd0) ? 32'd0 : registers[read_reg2];

endmodule