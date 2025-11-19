module alu(
    input logic [31:0] a,
    input logic [31:0] b,
    input logic [2:0] funct3,
    input logic [6:0] funct7,
    input logic [6:0] op,
    output logic [31:0] result
)

    always_comb begin
        case (op)
            ALU_ADD: result = a + b;
            ALU_SUB: result = a - b; 
            ALU_SLL: result = a << b[4:0];
            ALU_SLT: result = $signed(a) < $signed(b);
            ALU_SLTU: result = a < b;
            ALU_XOR: result = a ^ b;
            ALU_SRL: result = a >> b[4:0];
            ALU_OR: result = a | b;
            ALU_AND: result = a & b;
            ALU_SRA: result = $signed(a) >> b[4:0];
            ALU_COPY: result = a;
            default: result = 32'd0;
        endcase
    end


endmodule