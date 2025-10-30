module game_of_life (
    input  logic clk,
    input  logic update,
    input  logic [63:0] current_bits,   // 1 = alive, 0 = dead
    output logic [63:0] next_bits       // next generation
);

    localparam int ROWS = 8;
    localparam int COLS = 8;

    int r, c;                  // current row and column
    int dr, dc;                // neighbor row/col offsets
    int nr, nc;                // neighbor row/col after wrapping
    int pos, npos;             // linear indices
    int neighbors;             // count of alive neighbors
    logic alive;               // current cell alive state
    logic will_live;           // next state flag

    always_ff @(posedge clk) begin
        if (update) begin

            // loop through all columns first, then rows
            for (c = 0; c < COLS; c = c + 1) begin
                for (r = 0; r < ROWS; r = r + 1) begin

                    pos = r * COLS + c;      // convert 2D to 1D index
                    alive = current_bits[pos];
                    neighbors = 0;

                    // check and scan for all 8 neighbors
                    for (dc = -1; dc <= 1; dc = dc + 1) begin
                        for (dr = -1; dr <= 1; dr = dr + 1) begin

                    
                            if (dr != 0 || dc != 0) begin

                                nr = (r + dr + ROWS) % ROWS;
                                nc = (c + dc + COLS) % COLS;
                                npos = nr * COLS + nc;

                                if (current_bits[npos])
                                    neighbors = neighbors + 1;
                            end

                        end
                    end

                    // determine next state
                    will_live = 0;
                    if (alive) begin
                        // alive: survives only with 2 or 3 neighbors
                        if (neighbors == 2 || neighbors == 3)
                            will_live = 1;
                    end else begin
                        // dead: becomes alive only with 3 neighbors
                        if (neighbors == 3)
                            will_live = 1;
                    end

                    // assign next state
                    next_bits[pos] <= will_live;

                end
            end

        end
    end

endmodule