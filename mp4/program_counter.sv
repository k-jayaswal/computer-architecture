module program_counter(
    input  logic        clk,        /
    input  logic        rst,        // active-high reset
    input  logic [31:0] next_pc,    // next PC
    output logic [31:0] pc          // current PC
);

    always_ff @(posedge clk) begin
        if (rst) begin
            pc <= 32'd0;           // reset PC to 0
        end
        else begin
            pc <= next_pc;         // update PC on clock edge
        end
    end

endmodule
