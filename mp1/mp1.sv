module mp1(
    input logic clk,
    output logic RGB_R,
    output logic RGB_G,
    output logic RGB_B
);

    // each color flashes for 1/6 of a second, so 12M Hz / 6
    parameter int COLOR_TIME = 2000000;

    // counter for clock ticks
    logic [$clog2(COLOR_TIME)-1:0] count = 0;

    // need 3 bits for 6 colors
    logic [2:0] color_index = 0;

    // counts ticks and moves to next color
    always_ff @(posedge clk) begin
        if (count >= COLOR_TIME - 1) begin
            count <= 0;
            if (color_index == 5)
                color_index <= 0;
            else
                color_index <= color_index + 1;
        end 

        else begin
            count <= count + 1;
        end
    end

    // active-low LED drive, use 1 = OFF, 0 = ON
    always_comb begin
        RGB_R = 1;  // off by default
        RGB_G = 1;
        RGB_B = 1;

        case (color_index)
            3'd0: RGB_R = 0;                      // red
            3'd1: begin RGB_R = 0; RGB_G = 0; end // yellow
            3'd2: RGB_G = 0;                      // green
            3'd3: begin RGB_G = 0; RGB_B = 0; end // cyan
            3'd4: RGB_B = 0;                      // blue
            3'd5: begin RGB_R = 0; RGB_B = 0; end // magenta
            default: begin RGB_R = 1; RGB_G = 1; RGB_B = 1; end
        endcase
    end

endmodule
