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

// module reg_file(
//     input  logic        clk,
//     input  logic        rst,
//     input  logic        write_enable,
//     input  logic [4:0]  write_address,
//     input  logic [31:0] write_data,
//     input  logic [4:0]  read_address1,
//     output logic [31:0] read_data1,
//     input  logic [4:0]  read_address2,
//     output logic [31:0] read_data2
// );

//     // PACKED array so GTKWave can plot all 32 registers easily
//     logic [31:0] registers [0:31];
//     integer i;

//     initial begin
//         for (i = 0; i < 32; i++)
//             registers[i] = 32'd0;
//     end

//     always_ff @(posedge clk) begin
//         if (rst) begin
//             for (i = 0; i < 32; i++)
//                 registers[i] <= 32'd0;
//         end else if (write_enable && write_address != 5'd0) begin
//             registers[write_address] <= write_data;
//         end
//     end

//     assign read_data1 = (read_address1 == 0) ? 32'd0 : registers[read_address1];
//     assign read_data2 = (read_address2 == 0) ? 32'd0 : registers[read_address2];

// endmodule


module reg_file(
    input  logic        clk,
    input  logic        rst,
    input  logic        write_enable,
    input  logic [4:0]  write_address,
    input  logic [31:0] write_data,
    input  logic [4:0]  read_address1,
    output logic [31:0] read_data1,
    input  logic [4:0]  read_address2,
    output logic [31:0] read_data2
);

    // Explicit registers, all visible in GTKWave
    (* keep *) logic [31:0] x0  = 32'd0;
    (* keep *) logic [31:0] x1  = 32'd0;
    (* keep *) logic [31:0] x2  = 32'd0;
    (* keep *) logic [31:0] x3  = 32'd0;
    (* keep *) logic [31:0] x4  = 32'd0;
    (* keep *) logic [31:0] x5  = 32'd0;
    (* keep *) logic [31:0] x6  = 32'd0;
    (* keep *) logic [31:0] x7  = 32'd0;
    (* keep *) logic [31:0] x8  = 32'd0;
    (* keep *) logic [31:0] x9  = 32'd0;
    (* keep *) logic [31:0] x10 = 32'd0;
    (* keep *) logic [31:0] x11 = 32'd0;
    (* keep *) logic [31:0] x12 = 32'd0;
    (* keep *) logic [31:0] x13 = 32'd0;
    (* keep *) logic [31:0] x14 = 32'd0;
    (* keep *) logic [31:0] x15 = 32'd0;
    (* keep *) logic [31:0] x16 = 32'd0;
    (* keep *) logic [31:0] x17 = 32'd0;
    (* keep *) logic [31:0] x18 = 32'd0;
    (* keep *) logic [31:0] x19 = 32'd0;
    (* keep *) logic [31:0] x20 = 32'd0;
    (* keep *) logic [31:0] x21 = 32'd0;
    (* keep *) logic [31:0] x22 = 32'd0;
    (* keep *) logic [31:0] x23 = 32'd0;
    (* keep *) logic [31:0] x24 = 32'd0;
    (* keep *) logic [31:0] x25 = 32'd0;
    (* keep *) logic [31:0] x26 = 32'd0;
    (* keep *) logic [31:0] x27 = 32'd0;
    (* keep *) logic [31:0] x28 = 32'd0;
    (* keep *) logic [31:0] x29 = 32'd0;
    (* keep *) logic [31:0] x30 = 32'd0;
    (* keep *) logic [31:0] x31 = 32'd0;

    // Vector of wires that point to the registers (NOT a memory)
    logic [31:0] reg_array [31:0];

    assign reg_array[0]  = x0;
    assign reg_array[1]  = x1;
    assign reg_array[2]  = x2;
    assign reg_array[3]  = x3;
    assign reg_array[4]  = x4;
    assign reg_array[5]  = x5;
    assign reg_array[6]  = x6;
    assign reg_array[7]  = x7;
    assign reg_array[8]  = x8;
    assign reg_array[9]  = x9;
    assign reg_array[10] = x10;
    assign reg_array[11] = x11;
    assign reg_array[12] = x12;
    assign reg_array[13] = x13;
    assign reg_array[14] = x14;
    assign reg_array[15] = x15;
    assign reg_array[16] = x16;
    assign reg_array[17] = x17;
    assign reg_array[18] = x18;
    assign reg_array[19] = x19;
    assign reg_array[20] = x20;
    assign reg_array[21] = x21;
    assign reg_array[22] = x22;
    assign reg_array[23] = x23;
    assign reg_array[24] = x24;
    assign reg_array[25] = x25;
    assign reg_array[26] = x26;
    assign reg_array[27] = x27;
    assign reg_array[28] = x28;
    assign reg_array[29] = x29;
    assign reg_array[30] = x30;
    assign reg_array[31] = x31;

    // Synchronous writes
    always_ff @(posedge clk) begin
        if (rst) begin
            x1 <= 0; x2 <= 0; x3 <= 0; x4 <= 0;
            x5 <= 0; x6 <= 0; x7 <= 0; x8 <= 0;
            x9 <= 0; x10 <= 0; x11 <= 0; x12 <= 0;
            x13 <= 0; x14 <= 0; x15 <= 0; x16 <= 0;
            x17 <= 0; x18 <= 0; x19 <= 0; x20 <= 0;
            x21 <= 0; x22 <= 0; x23 <= 0; x24 <= 0;
            x25 <= 0; x26 <= 0; x27 <= 0; x28 <= 0;
            x29 <= 0; x30 <= 0; x31 <= 0;
        end else if (write_enable && write_address != 0) begin
            case (write_address)
                1:  x1  <= write_data;
                2:  x2  <= write_data;
                3:  x3  <= write_data;
                4:  x4  <= write_data;
                5:  x5  <= write_data;
                6:  x6  <= write_data;
                7:  x7  <= write_data;
                8:  x8  <= write_data;
                9:  x9  <= write_data;
                10: x10 <= write_data;
                11: x11 <= write_data;
                12: x12 <= write_data;
                13: x13 <= write_data;
                14: x14 <= write_data;
                15: x15 <= write_data;
                16: x16 <= write_data;
                17: x17 <= write_data;
                18: x18 <= write_data;
                19: x19 <= write_data;
                20: x20 <= write_data;
                21: x21 <= write_data;
                22: x22 <= write_data;
                23: x23 <= write_data;
                24: x24 <= write_data;
                25: x25 <= write_data;
                26: x26 <= write_data;
                27: x27 <= write_data;
                28: x28 <= write_data;
                29: x29 <= write_data;
                30: x30 <= write_data;
                31: x31 <= write_data;
            endcase
        end
    end

    // Reads
    assign read_data1 = reg_array[read_address1];
    assign read_data2 = reg_array[read_address2];

endmodule
