module imm_gen(
    input  logic [31:0] instruction,  
    input  logic [2:0]  imm_type,     // 0:I, 1:S, 2:B, 3:U, 4:J
    output logic [31:0] imm           
);

    always_comb begin
        case (imm_type)
            3'd0: begin // I-type
                // imm[11:0] = instruction[31:20], sign-extended
                imm = {{20{instruction[31]}}, instruction[31:20]};
            end

            3'd1: begin // S-type
                // imm[11:5] = instruction[31:25], imm[4:0] = instruction[11:7]
                imm = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
            end

            3'd2: begin // B-type
                // imm[12|10:5|4:1|11|0] = {instruction[31], instruction[7], instruction[30:25], instruction[11:8], 0}
                imm = {{19{instruction[31]}}, instruction[31], instruction[7], instruction[30:25], instruction[11:8], 1'b0};
            end

            3'd3: begin // U-type
                // imm[31:12] = instruction[31:12], lower 12 bits zero
                imm = {instruction[31:12], 12'd0};
            end

            3'd4: begin // J-type
                // imm[20|10:1|11|19:12|0] = {instruction[31], instruction[19:12], instruction[20], instruction[30:21], 1'b0}
                imm = {{11{instruction[31]}}, instruction[31], instruction[19:12], instruction[20], instruction[30:21], 1'b0};
            end

            default: imm = 32'd0;
        endcase
    end

endmodule
