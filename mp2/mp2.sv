`include "pwm.sv"

module mp2 (
    input  logic clk,     
    output logic RGB_R,  
    output logic RGB_G,  
    output logic RGB_B    
);

    parameter PWM_INTERVAL   = 1200;     
    parameter CYCLES_PER_SEG = 2000000;  // 12 MHz / 6 segments = 2M
    parameter TOTAL_CYCLES   = 12000000; // full cycle = 1 second

    logic [23:0] hue_counter = 0; // 24 bit counter for a full cycle

    // hue counter logic
    always_ff @(posedge clk) begin
        if (hue_counter == TOTAL_CYCLES-1)
            hue_counter <= 0;
        else
            hue_counter <= hue_counter + 1;
    end

    // splitting 360 degree cycle into 6 segments of 60 degrees
    logic [2:0] segment;
    assign segment = hue_counter / CYCLES_PER_SEG;

    // position in the current segment
    logic [20:0] seg_pos;
    assign seg_pos = hue_counter % CYCLES_PER_SEG;

    // fade value from 0-1200 (color brightness controller)
    logic [$clog2(PWM_INTERVAL)-1:0] fade;
    assign fade = (seg_pos * (PWM_INTERVAL- 1)) / (CYCLES_PER_SEG - 1);

    // pwm values for R, G, B
    logic [$clog2(PWM_INTERVAL)-1:0] r_val, g_val, b_val;

    always_comb begin
        case (segment)
            3'd0: begin r_val = PWM_INTERVAL;       g_val = fade;              b_val = 0;                   end
            3'd1: begin r_val = PWM_INTERVAL-fade;  g_val = PWM_INTERVAL;      b_val = 0;                   end
            3'd2: begin r_val = 0;                  g_val = PWM_INTERVAL;      b_val = fade;                end
            3'd3: begin r_val = 0;                  g_val = PWM_INTERVAL-fade; b_val = PWM_INTERVAL;        end
            3'd4: begin r_val = fade;               g_val = 0;                 b_val = PWM_INTERVAL;        end
            3'd5: begin r_val = PWM_INTERVAL;       g_val = 0;                 b_val = PWM_INTERVAL-fade;   end
            default: begin r_val=0; g_val=0; b_val=0; end
        endcase
    end

    // Pinstantiate pwm for RGB
    logic r_sig, g_sig, b_sig;

    // generates pwm signal
    pwm #(.PWM_INTERVAL(PWM_INTERVAL)) r_pwm_gen (.clk(clk), .pwm_value(r_val), .pwm_out(r_sig));
    pwm #(.PWM_INTERVAL(PWM_INTERVAL)) g_pwm_gen (.clk(clk), .pwm_value(g_val), .pwm_out(g_sig));
    pwm #(.PWM_INTERVAL(PWM_INTERVAL)) b_pwm_gen (.clk(clk), .pwm_value(b_val), .pwm_out(b_sig));

    // inverts pwm signal due to active-low RGB
    assign RGB_R = ~r_sig;
    assign RGB_G = ~g_sig;
    assign RGB_B = ~b_sig;

endmodule
