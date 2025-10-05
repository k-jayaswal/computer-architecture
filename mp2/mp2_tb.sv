`timescale 10ns/10ns
`include "mp2.sv"

module mp2_tb;

    parameter PWM_INTERVAL = 1200;

    logic clk = 0;
    logic RGB_R, RGB_G, RGB_B;

    mp2 #(
        .PWM_INTERVAL(PWM_INTERVAL)
    ) u0 (
        .clk(clk),
        .RGB_R(RGB_R),
        .RGB_G(RGB_G),
        .RGB_B(RGB_B)
    );

    initial begin
        $dumpfile("mp2.vcd");
        $dumpvars(0, mp2_tb);
        $dumpvars(0, mp2_tb.u0);
        #100000000;
        $finish;
    end

    always begin
        #4 clk = ~clk;
    end

endmodule
