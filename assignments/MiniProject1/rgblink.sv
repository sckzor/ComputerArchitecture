// RGBlink

module top(
    input logic     clk, 
    output logic    RGB_R,
    output logic    RGB_G,
    output logic    RGB_B
);

    // CLK frequency is 12MHz, so 2,000,000 cycles is 0.166s
    parameter BLINK_INTERVAL = 2000000;
    logic [$clog2(BLINK_INTERVAL) - 1:0] count = 0;
    logic [2:0] state = 0;

    initial begin
        RGB_R = 1'b0;
        RGB_G = 1'b0;
        RGB_B = 1'b0;
    end

    always_ff @(posedge clk) begin
        if (count == BLINK_INTERVAL - 1) begin
            case(state)
                3'b000: begin
                    RGB_R <= 1'b1;
                    RGB_G <= 1'b0;
                    RGB_B <= 1'b0;
                    state <= state + 1;
                end

                3'b001: begin
                    RGB_R <= 1'b1;
                    RGB_G <= 1'b1;
                    RGB_B <= 1'b0;
                    state <= state + 1;
                end

                3'b010: begin
                    RGB_R <= 1'b0;
                    RGB_G <= 1'b1;
                    RGB_B <= 1'b0;
                    state <= state + 1;
                end

                3'b011: begin
                    RGB_R <= 1'b0;
                    RGB_G <= 1'b1;
                    RGB_B <= 1'b1;
                    state <= state + 1;
                end

                3'b011: begin
                    RGB_R <= 1'b0;
                    RGB_G <= 1'b0;
                    RGB_B <= 1'b1;
                    state <= state + 1;
                end

                3'b100: begin
                    RGB_R <= 1'b1;
                    RGB_G <= 1'b0;
                    RGB_B <= 1'b1;
                    state <= 3'b000;
                end
            endcase
                
            count <= 0;
            LED <= ~LED;
        end
        else begin
            count <= count + 1;
        end
    end

endmodule
