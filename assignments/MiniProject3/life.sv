// Conway's Game of Life

module top(
    input logic     clk, 
    output logic    _3b
);
    // CLK frequency is 12MHz
    parameter ON_TICKS = 10; 
    parameter OFF_TICKS = 5;
    parameter PERIOD_TICKS = 15;
    parameter BLANKING_TIME = 2000;

    parameter UPDATE_TIME = 1200000;
    // parameter UPDATE_TIME = 10;

    parameter TX_BITS = 24;
    parameter LED_BITS = 64;

    parameter LOW = 1'b0;
    parameter HIGH = 1'b1;

    parameter TRUE = 1'b1;
    parameter FALSE = 1'b0;

    parameter R_STATE = 0;
    parameter G_STATE = 1;
    parameter B_STATE = 2;

    // parameter LED_PATTERN = 64'b01111110_10000001_10100101_10000001_11000011_10111101_10000001_01111110; // Face
    // parameter LED_PATTERN = 64'b01010101_10101010_01010101_10101010_01010101_10101010_01010101_10101010; // Checkerboard
    // parameter LED_PATTERN = 64'b00000000_00000000_00000000_00111000_00011100_00000000_00000000_00000000; // Toad
    // parameter LED_PATTERN = 64'b01000000_00100000_11100000_00000000_00000000_00000000_00000000_00000000; // Glider

    parameter EMPTY_LED = 64'b00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000;

    parameter LED_OFF = 24'b000000000000000000000000;
    parameter LED_R = 24'b00000000111111110000000;
    parameter LED_G = 24'b00000000000000001111111;
    parameter LED_B = 24'b11111111000000000000000;

    logic [LED_BITS-1:0] mem [0:0];

    
    logic [4:0] period_cntr = 0;
    logic [4:0] bit_cntr = 0;
    logic [6:0] led_cntr = 0;
    logic [TX_BITS-1:0] color_bitstring = LED_OFF;
    
    logic [10:0] blanking_counter = 0;

    logic [6:0] bit_checked = 0;
    logic [4:0] neighbors = 0;

    logic [TX_BITS-1:0] curr_color = LED_R;
    logic [3:0] color_state = 0;

    logic [24:0] update_counter = 0;

    logic [24:0] x = 0;
    logic [24:0] y = 0;
    logic [24:0] dx = 0;
    logic [24:0] dy = 0;
    logic [24:0] nx = 0;
    logic [24:0] ny = 0;
    logic [24:0] n_index = 0;

    logic [LED_BITS-1:0] new_pattern = EMPTY_LED;
    logic [LED_BITS-1:0] pattern_bitstring = EMPTY_LED;

    logic [LED_BITS-1:0] loaded_pattern;
    logic [LED_BITS-1:0] pattern = EMPTY_LED;

    logic [0:0] pattern_read = FALSE;

    initial begin
        _3b = 1'b1;
        $readmemb("pattern.txt",mem);
        loaded_pattern = mem[0];
    end

    // LED Controller Code

    always_ff @(posedge clk) begin

        if(period_cntr == PERIOD_TICKS) begin
            if(bit_cntr == TX_BITS - 1) begin
                if(pattern_bitstring[0] == 1) begin
                    color_bitstring <= curr_color;
                end else begin
                    color_bitstring <= LED_OFF;
                end
            end
        end

        if(blanking_counter == 0) begin

            case(color_bitstring[0])
                FALSE: begin
                    if(period_cntr == OFF_TICKS) begin
                        _3b <= LOW;
                    end
                end

                TRUE: begin
                    if(period_cntr == ON_TICKS) begin
                        _3b <= LOW;
                    end
                end

            endcase

            if(period_cntr == PERIOD_TICKS) begin
                period_cntr <= 0;

                if(bit_cntr == TX_BITS - 1) begin
                    bit_cntr <= 0;

                    if(led_cntr == LED_BITS - 1) begin
                        led_cntr <= 0;
                        pattern_bitstring <= pattern;
                        blanking_counter <= BLANKING_TIME;
                    end else begin
                        pattern_bitstring <= pattern_bitstring >> 1;
                        led_cntr <= led_cntr + 1;
                    end

                end else begin
                    bit_cntr <= bit_cntr + 1;

                    color_bitstring <= color_bitstring >> 1;
                end
                
                _3b <= HIGH;


            end else begin
                period_cntr <= period_cntr + 1;
            end
        end else if(blanking_counter == 1) begin
            _3b <= HIGH;
            blanking_counter <= 0;
            bit_cntr <= -1;

            // color_bitstring <= curr_color;

            if(pattern_bitstring[0] == 1) begin
                color_bitstring <= curr_color;
            end else begin
                color_bitstring <= LED_OFF;
            end

            pattern_bitstring <= pattern >> 1;
        end else begin
            blanking_counter <= blanking_counter - 1;
        end
    end

    // Game of Life Logic

    always_comb begin
        neighbors = 0;

        x = bit_checked % 8;
        y = bit_checked / 8;

        for (dy = -1; dy <= 1; dy = dy + 1) begin
            for (dx = -1; dx <= 1; dx = dx + 1) begin
                if (!(dx == 0 && dy == 0)) begin
                    nx = (x + dx + 8) % 8;
                    ny = (y + dy + 8) % 8;

                    n_index = ny * 8 + nx;

                    if (pattern[n_index] == 1) begin
                        neighbors = neighbors + 1;
                    end
                end
            end
        end
    end

    // Color and Generation Logic

    always_ff @(posedge clk) begin
        if(pattern_read == FALSE) begin
            pattern <= loaded_pattern;
            pattern_read <= TRUE;
        end

        if(update_counter == UPDATE_TIME) begin
            if(bit_checked == LED_BITS) begin
                pattern <= new_pattern;
                new_pattern <= EMPTY_LED;
                bit_checked <= 0;
                update_counter <= 0;

                case(color_state)
                    R_STATE: begin
                        color_state <= G_STATE;
                        curr_color <= LED_G;
                    end

                    G_STATE: begin
                        color_state <= B_STATE;
                        curr_color <= LED_B;
                    end

                    B_STATE: begin
                        color_state <= R_STATE;
                        curr_color <= LED_R;
                    end
                endcase

            end else begin
                case(neighbors)
                    2: begin
                        new_pattern[bit_checked] <= pattern[bit_checked];
                    end

                    3: begin
                        new_pattern[bit_checked] <= 1;
                    end

                    default: begin
                        new_pattern[bit_checked] <= 0;
                    end

                endcase

                bit_checked <= bit_checked + 1;
            end
        end else begin
            update_counter <= update_counter + 1;
        end
    end

endmodule