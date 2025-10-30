module game_of_life (
    input  logic clk,                 
    input  logic update,               
    input  logic [63:0] current_bits, // 1 bit per cell: 1 = alive, 0 = dead
    output logic [63:0] next_bits     // 1 bit per cell for next generation
);

    localparam int ROWS = 8;  
    localparam int COLS = 8;  

    // internal loop variables
    int y, x;                
    int delta_y, delta_x;    // offsets for neighbor scanning (-1, 0, 1)
    int neighbor_row, neighbor_col; // coordinates of neighbor
    int cell_index, neighbor_index; 
    int live_neighbors;      // count of live neighbors 

    always_ff @(posedge clk) begin
        if (update) begin
            for (y = 0; y < ROWS; y = y + 1) begin
                for (x = 0; x < COLS; x = x + 1) begin
                    cell_index = y * COLS + x; // convert coordinates
                    live_neighbors = 0;

                    // scan for all 8 neighbors
                    for (delta_y = -1; delta_y <= 1; delta_y = delta_y + 1) begin
                        for (delta_x = -1; delta_x <= 1; delta_x = delta_x + 1) begin
                            if (!(delta_y == 0 && delta_x == 0)) begin
                                // wrap around edges (toroidal grid)
                                neighbor_row = (y + delta_y + ROWS) % ROWS;
                                neighbor_col = (x + delta_x + COLS) % COLS;
                                neighbor_index = neighbor_row * COLS + neighbor_col;
                                // add 1 if neighbor is alive
                                live_neighbors += current_bits[neighbor_index];
                            end
                        end
                    end

                    // apply rules
                    next_bits[cell_index] <= (live_neighbors == 3) || 
                                             (current_bits[cell_index] && live_neighbors == 2);
                end
            end
        end
    end

endmodule
