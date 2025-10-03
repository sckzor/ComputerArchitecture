// RGBSweep

module top(
    input logic     clk, 
    output logic    RGB_R,
    output logic    RGB_G,
    output logic    RGB_B
);

    // CLK frequency is 12MHz
    parameter RED_START = 666;
    parameter GREEN_START = 0;
    parameter BLUE_START = 333;

    parameter STOP = 0;
    parameter UP = 1;
    parameter HOLD = 2;
    parameter DOWN = 3;


    parameter START_TIME = 167;
    parameter HOLD_TIME = 500;
    parameter RESTART = 1000;
    parameter LOOP_TIME = 12000000;

    logic [14:0] pwm_tick = 0;
    logic [10:0] sum_tick = 0;

    logic [2:0] red_dir = HOLD;
    logic [2:0] green_dir = 0;
    logic [2:0] blue_dir = 0;

    logic [9:0] red_pos = 333;
    logic [9:0] green_pos = 1001;
    logic [9:0] blue_pos = 1001;

    logic [9:0] red_pwm = 0;
    logic [9:0] green_pwm = 0;
    logic [9:0] blue_pwm = 0;

    initial begin
        RGB_R = 1'b1;
        RGB_G = 1'b1;
        RGB_B = 1'b1;
    end

    always_ff @(posedge clk) begin
        case(sum_tick)
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
        endcase

	if(pwm_tick == 12000) begin
            case(red_dir)
                UP: begin
                    red_pos <= red_pos + 1;
                    if(red_pos == START_TIME) begin
                        red_dir <= HOLD;
                    end
                end
                HOLD: begin
                    red_pos <= red_pos + 1;
                    if(red_pos == HOLD_TIME) begin
                        red_dir <= DOWN;
                        red_pos <= START_TIME;
                    end
                end
                DOWN: begin
                    red_pos <= red_pos - 1;
		    if(red_pos == 0) begin
                        red_dir <= STOP;
                    end
                end
            endcase

            case(green_dir)
                UP: begin
                    green_pos <= green_pos + 1;
                    if(green_pos == START_TIME ) begin
                        green_dir <= HOLD;
                    end
                end
                HOLD: begin
                    green_pos <= green_pos + 1;
                    if(green_pos == HOLD_TIME) begin
                        green_dir <= DOWN;
                        green_pos <= START_TIME;
                    end
                end
                DOWN: begin
                    green_pos <= green_pos - 1;
		    if(green_pos == 0) begin
                        green_dir <= STOP;
                    end
                end
            endcase

            case(blue_dir)
                UP: begin
                    blue_pos <= blue_pos + 1;
                    if(blue_pos == START_TIME ) begin
                        blue_dir <= HOLD;
                    end
                end
                HOLD: begin
                    blue_pos <= blue_pos + 1;
                    if(blue_pos == HOLD_TIME) begin
                        blue_dir <= DOWN;
                        blue_pos <= START_TIME;
                    end
                end
                DOWN: begin
                    blue_pos <= blue_pos - 1;
		    if(blue_pos == 0) begin
                        blue_dir <= STOP;
                    end
                end
            endcase

            pwm_tick <= 0;
            sum_tick <= sum_tick + 1;
        end
        else begin
            pwm_tick <= pwm_tick + 1;
        end

        if(sum_tick > RESTART) begin
            sum_tick <= 0;
        end
    end

    always_ff @(posedge clk) begin
        case(red_dir)
            UP, DOWN: begin
                case(red_pwm)
                    red_pos: begin
                        RGB_R = 1'b1;
                    end
                    START_TIME: begin
                        red_pwm = 0;
                        RGB_R = 1'b0;
                    end
                endcase
                red_pwm = red_pwm + 1;
            end
            HOLD: begin
                RGB_R = 1'b0;
            end
            STOP: begin
                RGB_R = 1'b1;
            end
        endcase
    end

    always_ff @(posedge clk) begin
        case(green_dir)
            UP, DOWN: begin
                case(green_pwm)
                    green_pos: begin
                        RGB_G = 1'b1;
                    end
                    START_TIME: begin
                        green_pwm = 0;
                        RGB_G = 1'b0;
                    end
                endcase
                green_pwm = green_pwm + 1;
            end
            HOLD: begin
                RGB_G = 1'b0;
            end
            STOP: begin
                RGB_G = 1'b1;
            end
        endcase
    end

    always_ff @(posedge clk) begin
        case(blue_dir)
            UP, DOWN: begin
                case(blue_pwm)
                    blue_pos: begin
                        RGB_B = 1'b1;
                    end
                    START_TIME: begin
                        blue_pwm = 0;
                        RGB_B = 1'b0;
                    end
                endcase
                blue_pwm = blue_pwm + 1;
            end
            HOLD: begin
                RGB_B = 1'b0;
            end
            STOP: begin
                RGB_B = 1'b1;
            end
        endcase
    end
endmodule
