`timescale 1ns/1ps
`include "game_of_life.sv"

module game_of_life_tb;

    logic clk = 0;
    logic update = 0;

    logic [63:0] current_bits;
    logic [63:0] next_bits;

    game_of_life dut (
        .clk(clk),
        .update(update),
        .current_bits(current_bits),
        .next_bits(next_bits)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("game_of_life.vcd");
        $dumpvars(0, game_of_life_tb);

        current_bits = 64'b0;
        current_bits[34] = 1'b1; // (4,2)
        current_bits[35] = 1'b1; // (4,3)
        current_bits[36] = 1'b1; // (4,4)

        // loop over 4 generations
        repeat (4) begin
            #10; update = 1;
            #10; update = 0;

            // wait for next_bits to settle
            #10;

            // apply next state -> current_bits
            current_bits = next_bits;
        end

        $finish;
    end

endmodule
