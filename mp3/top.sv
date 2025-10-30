`timescale 1ns/1ps
`include "memory.sv"
`include "ws2812b.sv"
`include "controller.sv"
`include "game_of_life.sv"

module top(
    input  logic clk,       // 12 MHz system clock
    input  logic SW,        
    input  logic BOOT,      
    output logic _48b,      // ws2812b data output
    output logic _45a       // inverted ws2812b data output
);

    // controller/driver signals
    logic load_sreg;        
    logic transmit_pixel;   
    logic [5:0] pixel;      
    logic [4:0] frame;     

    // ws2812b shift register signals
    logic shift;            
    logic ws2812b_out;      
    logic [23:0] shift_reg; // 24-bit RGB data for ws2812b 

    // frame buffer 
    // each pixel is 8-bit: non-zero = alive, 0 = dead
    logic [7:0] frame_buffer [0:63];

    // memory instance to preload initial state
    logic [10:0] mem_addr;  
    logic [7:0] mem_data;   
    wire read_clk = clk;    

    // load initial pattern from hex file
    memory #(.INIT_FILE("generate_initial_state.hex")) init_mem (
        .clk(read_clk),
        .read_address(mem_addr),
        .read_data(mem_data)
    );

    // loads initial memory contents into frame_buffer
    logic loader_active;
    logic [6:0] loader_idx; 
    logic loader_phase;     // 0 = set address, 1 = capture data

    initial begin
        loader_active = 1'b1; 
        loader_idx    = 7'd0;
        loader_phase  = 1'b0;
    end

    always_ff @(posedge clk) begin
        if (loader_active) begin
            if (loader_phase == 1'b0) begin
                // prsent memory address
                mem_addr <= loader_idx;
                loader_phase <= 1'b1;
            end else begin
                // capture memory data into frame buffer
                frame_buffer[loader_idx] <= mem_data;
                loader_phase <= 1'b0;
                if (loader_idx == 7'd63) begin
                    // finish loading all 64 pixels
                    loader_active <= 1'b0;
                    loader_idx <= 7'd0;
                    mem_addr <= 11'd0;
                end else begin
                    loader_idx <= loader_idx + 7'd1;
                end
            end
        end
    end

    // convert frame_buffer to boolean grid
    logic [63:0] current_bits;
    integer ii;
    always_comb begin
        for (ii = 0; ii < 64; ii = ii + 1)
            current_bits[ii] = (frame_buffer[ii] != 8'h00); // alive = 1, dead = 0
    end

    // game core instance
    logic update_pulse;     // trigger next generation
    logic [63:0] next_bits; // output

    game_of_life gol_u (
        .clk(clk),
        .update(update_pulse),
        .current_bits(current_bits),
        .next_bits(next_bits)
    );

    // generation timing (~1 second at 12 MHz)
    localparam int UPDATE_CYCLES = 12_000_000;
    logic [$clog2(UPDATE_CYCLES)-1:0] update_counter;
    logic update_pending;   // indicates next_bits need to be written
    logic [2:0] hue_index;  // color index for alive cells

    initial begin
        update_counter = '0;
        update_pending = 1'b0;
        hue_index = 3'd0;
        update_pulse = 1'b0;
    end

    always_ff @(posedge clk) begin
        if (loader_active) begin
            update_counter <= '0;
            update_pulse <= 1'b0;
            update_pending <= 1'b0;
        end else begin
            // increment counter until it's time for next generation
            if (update_counter == UPDATE_CYCLES - 1) begin
                update_counter <= '0;
                update_pulse <= 1'b1;
                update_pending <= 1'b1;
            end else begin
                update_counter <= update_counter + 1;
                update_pulse <= 1'b0;
            end

            // apply next generation 
            if (update_pending && (transmit_pixel == 1'b0)) begin
                update_pending <= 1'b0;
                for (ii = 0; ii < 64; ii = ii + 1)
                    frame_buffer[ii] <= next_bits[ii] ? 8'hFF : 8'h00; // alive = 255
                hue_index <= hue_index + 3'd1; // cycle thru colors
            end
        end
    end

    // 8-color palette (RGB)
    function automatic logic [7:0] pal_r(input logic [2:0] idx);
        case (idx)
            3'd0: pal_r = 8'd255; // red
            3'd1: pal_r = 8'd0;   // cyan
            3'd2: pal_r = 8'd255; // orange
            3'd3: pal_r = 8'd127; // purple
            3'd4: pal_r = 8'd0;   // green
            3'd5: pal_r = 8'd255; // magenta
            3'd6: pal_r = 8'd0;   // blue
            3'd7: pal_r = 8'd255; // yellow
            default: pal_r = 8'd0;
        endcase
    endfunction

    function automatic logic [7:0] pal_g(input logic [2:0] idx);
        case (idx)
            3'd0: pal_g = 8'd0;   // red
            3'd1: pal_g = 8'd255; // cyan
            3'd2: pal_g = 8'd92;  // orange
            3'd3: pal_g = 8'd0;   // purple
            3'd4: pal_g = 8'd255; // green
            3'd5: pal_g = 8'd0;   // magenta
            3'd6: pal_g = 8'd0;   // blue
            3'd7: pal_g = 8'd255; // yellow
            default: pal_g = 8'd0;
        endcase
    endfunction

    function automatic logic [7:0] pal_b(input logic [2:0] idx);
        case (idx)
            3'd0: pal_b = 8'd0;   // red
            3'd1: pal_b = 8'd255; // cyan
            3'd2: pal_b = 8'd0;   // orange
            3'd3: pal_b = 8'd255; // purple
            3'd4: pal_b = 8'd0;   // green
            3'd5: pal_b = 8'd127; // magenta
            3'd6: pal_b = 8'd255; // blue
            3'd7: pal_b = 8'd0;   // yellow
            default: pal_b = 8'd0;
        endcase
    endfunction

    // ws2812b shift register logic
    always_ff @(posedge clk) begin
        if (load_sreg) begin
            // load RGB values for current pixel
            if (frame_buffer[pixel] != 8'h00)
                shift_reg <= { pal_g(hue_index), pal_r(hue_index), pal_b(hue_index) };
            else
                shift_reg <= 24'd0; // dead cell = off
        end else if (shift) begin
            // shift out next bit
            shift_reg <= { shift_reg[22:0], 1'b0 };
        end
    end

    // instantiate ws2812b driver
    ws2812b u_ws (
        .clk(clk),
        .serial_in(shift_reg[23]),
        .transmit(transmit_pixel),
        .ws2812b_out(ws2812b_out),
        .shift(shift)
    );

    // instantiate controller
    controller u_ctrl (
        .clk(clk),
        .load_sreg(load_sreg),
        .transmit_pixel(transmit_pixel),
        .pixel(pixel),
        .frame(frame)
    );

    // outputs
    assign _48b = ws2812b_out;
    assign _45a = ~ws2812b_out;

endmodule
