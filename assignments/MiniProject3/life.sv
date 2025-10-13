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

    parameter TX_BITS = 24;
    parameter LED_BITS = 64;

    parameter LOW = 1'b0;
    parameter HIGH = 1'b1;

    parameter TRUE = 1'b1;
    parameter FALSE = 1'b0;

    // parameter LED_PATTERN = 64'b01111110_10000001_10100101_10000001_11000011_10111101_10000001_01111110;
    // parameter LED_PATTERN = 64'b01010101_10101010_01010101_10101010_01010101_10101010_01010101_10101010;
    parameter LED_PATTERN = 64'b00000000_00000000_00000000_00111000_00011100_00000000_00000000_00000000;

    parameter LED_OFF = 24'b000000000000000000000000;
    parameter LED_COLOR = 24'b111111111111111111111111;

    logic [4:0] period_cntr = 0;
    logic [4:0] bit_cntr = 0;
    logic [6:0] led_cntr = 0;
    logic [TX_BITS-1:0] color_bitstring = LED_OFF;
    logic [LED_BITS-1:0] pattern_bitstring = LED_PATTERN;
    logic [10:0] blanking_counter = 0;

    logic [4:0] bit_checked = 0;
    logic [2:0] neighbors = 0;
    
    initial begin
        _3b = 1'b1;
    end

    // LED Controller Code

    always_ff @(posedge clk) begin
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

            if(period_cntr == PERIOD_TICKS ) begin
                period_cntr <= 0;

                color_bitstring <= color_bitstring >> 1;

                if(bit_cntr >= TX_BITS - 1) begin
                    bit_cntr <= 0;

                    if(pattern_bitstring[0] == 1) begin
                        color_bitstring <= LED_COLOR;
                    end else begin
                        color_bitstring <= LED_OFF;
                    end


                    if(led_cntr == LED_BITS - 1) begin
                        led_cntr <= 0;
                        pattern_bitstring <= LED_PATTERN;
                        blanking_counter <= BLANKING_TIME;
                        
                    end else begin
                        pattern_bitstring <= pattern_bitstring >> 1;
                        led_cntr <= led_cntr + 1;
                    end

                    _3b <= HIGH;
                end else begin
                    bit_cntr <= bit_cntr + 1;
                    _3b <= HIGH;
                end

            end else begin
                period_cntr <= period_cntr + 1;
            end
        end else if(blanking_counter == 1) begin
            _3b <= HIGH;
            blanking_counter <= 0;

            color_bitstring <= LED_COLOR;

            if(pattern_bitstring[0] == 1) begin
                color_bitstring <= LED_COLOR;
            end else begin
                color_bitstring <= LED_OFF;
            end

            pattern_bitstring <= pattern_bitstring >> 1;
        end else begin
            blanking_counter <= blanking_counter - 1;
        end
    end

endmodule
