`timescale 10ns/10ns
`include "top.sv"

module top_tb;

    logic clk = 0;
    logic LED, RGB_R, RGB_G, RGB_B;


    top u0 (
        .clk            (clk), 
        .LED            (LED), 
        .RGB_R          (RGB_R), 
        .RGB_G          (RGB_G), 
        .RGB_B          (RGB_B)
    );

    initial begin
        $dumpfile("top.vcd");
        $dumpvars(0, top_tb);
        #100000
        $finish;
    end

    always begin
        #4
        clk = ~clk;
    end

endmodule
