module reg_file(
    input  logic         clk,         
    input  logic         rst,          
    input  logic [4:0]   rs1,          // read register 1 address
    input  logic [4:0]   rs2,          // read register 2 address
    input  logic [4:0]   rd,           // write register address
    input  logic [31:0]  write_data,   // data to write
    input  logic         write_enable, // write enable
    output logic [31:0]  read_data1,   // read data 1
    output logic [31:0]  read_data2    // read data 2
);

    // 32 general purpose registers
    logic [31:0] regs [31:0];

    // initialize all registers to 0 on resetting
    always_ff @(posedge clk) begin
        if (rst) begin
            integer i;
            for (i = 0; i < 32; i=i+1)
                regs[i] <= 32'd0;
        end
        
        else if (write_enable && rd != 5'd0) begin
            // write to rd (except x0)
            regs[rd] <= write_data;
        end
    end

    // asynchronous read
    assign read_data1 = (rs1 != 5'd0) ? regs[rs1] : 32'd0;
    assign read_data2 = (rs2 != 5'd0) ? regs[rs2] : 32'd0;

endmodule
