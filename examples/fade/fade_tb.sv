`timescale 10ns/10ns
`include "fade.sv"
`include "pwm.sv"

module fade_tb;

    parameter PWM_INTERVAL = 1200;

    logic clk = 0;
    logic [$clog2(PWM_INTERVAL) - 1:0] pwm_value;
    logic pwm_out;

    fade #(
        .PWM_INTERVAL   (PWM_INTERVAL)
    ) u0 (
        .clk            (clk), 
        .pwm_value      (pwm_value)
    );

    pwm #(
        .PWM_INTERVAL   (PWM_INTERVAL)
    ) u1 (
        .clk            (clk), 
        .pwm_value      (pwm_value), 
        .pwm_out        (pwm_out)
    );


    initial begin
        $dumpfile("fade.vcd");
        $dumpvars(0, fade_tb);
        #100000000
        $finish;
    end

    always begin
        #4
        clk = ~clk;
    end

endmodule

