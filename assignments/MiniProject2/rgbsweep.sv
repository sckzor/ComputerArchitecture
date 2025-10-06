// RGBSweep

module top(
    input logic     clk, 
    output logic    RGB_R,
    output logic    RGB_G,
    output logic    RGB_B
);
    // CLK frequency is 12MHz
    parameter CLK_PER_MS = 12000;
    parameter TCK_PER_MS = 10;

    parameter RED_START = 666 * TCK_PER_MS;
    parameter GREEN_START = 0 * TCK_PER_MS;
    parameter BLUE_START = 333 * TCK_PER_MS;

    parameter STOP = 0;
    parameter UP = 1;
    parameter HOLD = 2;
    parameter DOWN = 3;

    parameter UP_OVER = 167 * TCK_PER_MS;
    parameter HOLD_OVER = 500 * TCK_PER_MS;
    parameter DOWN_OVER = 667 * TCK_PER_MS;
    parameter CYCLE_OVER = 1000 * TCK_PER_MS;

    logic [12:0] div_cntr = 0;
    logic [12:0] pwm_cntr = 0;
    logic [14:0] tck_cntr = 0;

    logic [2:0] red_dir = HOLD;
    logic [2:0] green_dir = UP;
    logic [2:0] blue_dir = STOP;

    logic [13:0] red_pos = 333 * TCK_PER_MS;
    logic [13:0] green_pos = 0;
    logic [13:0] blue_pos = 666 * TCK_PER_MS;

    logic [13:0] red_pwm = 0;
    logic [13:0] green_pwm = 0;
    logic [13:0] blue_pwm = 0;

    initial begin
        RGB_R = 1'b1;
        RGB_G = 1'b1;
        RGB_B = 1'b1;
    end

    always_ff @(posedge clk) begin
        if(div_cntr == (CLK_PER_MS/TCK_PER_MS)) begin
            div_cntr <= 0;

            red_pos <= red_pos + 1;
            green_pos <= green_pos + 1;
            blue_pos <= blue_pos + 1;

            tck_cntr <= tck_cntr + 1;
        end else begin
            div_cntr <= div_cntr + 1;
        end

        case(tck_cntr)
            RED_START: begin
                red_dir <= UP;
                red_pos <= 0;
            end
            GREEN_START: begin
                green_dir <= UP;
                green_pos <= 0;
            end
            BLUE_START: begin
                blue_dir <= UP;
                blue_pos <= 0;
            end
            CYCLE_OVER: begin
                tck_cntr <= 0;
            end
        endcase

        case(red_pos)
            UP_OVER: begin
                red_dir <= HOLD;
            end
            HOLD_OVER: begin
                red_dir <= DOWN;
            end
            DOWN_OVER: begin
                red_dir <= STOP;
            end
        endcase

        case(green_pos)
            UP_OVER: begin
                green_dir <= HOLD;
            end
            HOLD_OVER: begin
                green_dir <= DOWN;
            end
            DOWN_OVER: begin
                green_dir <= STOP;
            end
        endcase

        case(blue_pos)
            UP_OVER: begin
                blue_dir <= HOLD;
            end
            HOLD_OVER: begin
                blue_dir <= DOWN;
            end
            DOWN_OVER: begin
                blue_dir <= STOP;
            end
        endcase
    end

    always_ff @(posedge clk) begin
        case(red_dir)
            UP: begin
                red_pwm <= red_pos;
            end

            HOLD: begin
                red_pwm <= UP_OVER + 2;
            end

            DOWN: begin
                red_pwm <= DOWN_OVER - red_pos;
            end

            STOP: begin
                red_pwm <= 0;
            end
        endcase
    end

    always_ff @(posedge clk) begin
        case(green_dir)
            UP: begin
                green_pwm <= green_pos;
            end

            HOLD: begin
                green_pwm <= UP_OVER + 2;
            end

            DOWN: begin
                green_pwm <= DOWN_OVER - green_pos;
            end

            STOP: begin
                green_pwm <= 0;
            end
        endcase
    end

    always_ff @(posedge clk) begin
        case(blue_dir)
            UP: begin
                blue_pwm <= blue_pos;
            end

            HOLD: begin
                blue_pwm <= UP_OVER + 2;
            end

            DOWN: begin
                blue_pwm <= DOWN_OVER - blue_pos;
            end

            STOP: begin
                blue_pwm <= 0;
            end
        endcase
    end

    always_ff @(posedge clk) begin
        if(pwm_cntr > UP_OVER) begin
            pwm_cntr <= 0;
        end else begin
            pwm_cntr <= pwm_cntr + 1;
        end
    end

    always_ff @(posedge clk) begin
        if(pwm_cntr < red_pwm) begin
            RGB_R <= 1'b0;
        end else begin
            RGB_R <= 1'b1;
        end
    end

    always_ff @(posedge clk) begin
        if(pwm_cntr < green_pwm) begin
            RGB_G <= 1'b0;
        end else begin
            RGB_G <= 1'b1;
        end
    end

    always_ff @(posedge clk) begin
        if(pwm_cntr < blue_pwm) begin
            RGB_B <= 1'b0;
        end else begin
            RGB_B <= 1'b1;
        end
    end
endmodule
