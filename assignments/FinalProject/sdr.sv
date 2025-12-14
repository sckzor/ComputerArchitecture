// Software Defined Radio

module midi_player #(
    parameter INIT_FILE = ""
)(
    input logic     clk, 
    input logic     [31:0] point_num,

    output logic    [7:0] point_out
);

    parameter SINE_STEPS = 256;

    parameter MAX_SPEED = 60000 / SINE_STEPS;

    logic [7:0] midi_freqs [0:1023];
    logic [7:0] sine_pos = 0;
    logic [7:0] sine_lut [SINE_STEPS-1:0];

    logic [31:0] delay = 0;
    logic [31:0] delay_counter = 0;

    int i;

    // Initialize memory array
    initial begin
        if (INIT_FILE) begin
            $readmemh(INIT_FILE, midi_freqs);
        end
        else begin
            for (i = 0; i < 1024; i++) begin
                memory[i] <= 8'd0;
            end
        end

        $readmemh("sine_256.txt", sine_lut);
    end

    always_ff @(posedge clk) begin
        if(midi_freqs[point_num] > 0) begin
            delay <= midi_freqs[point_num] + 30;
        end
        else begin
            delay <= 0;
        end
    end

    always_comb begin
        point_out = sine_lut[sine_pos];
    end

    always_ff @(posedge clk) begin
        if(delay_counter >= delay) begin
            delay_counter <= 0;
            if(delay != 0) begin
                if(sine_pos == SINE_STEPS - 1) begin
                    sine_pos <= 0;
                end
                else begin
                    sine_pos <= sine_pos + 1;
                end
            end
        end
        else begin
            delay_counter <= delay_counter + 1;
        end

    end

endmodule


module top(
    input logic     clk, 

    output logic    _20a,
    output logic    _18a,
    output logic    _13b,
    output logic    _8a,
    output logic    _9b,
    output logic    _6a,
    output logic    _4a,
    output logic    _2a,
    output logic    _3b,
    output logic    _45a,
    output logic    _48b,
    output logic    _0a,
    output logic    _5a
);

    // General Constants
    parameter HIGH = 1;
    parameter LOW = 0;

    parameter TRUE = 1;
    parameter FALSE = 0;


    // DAC Control
    parameter AUDIO_LEN = 1024;

    parameter STEP_HOLD_TIME = 500000;

    logic [31:0] count = 0;
    logic [31:0] update_count = 0;
    logic [7:0] voltage;

    logic [31:0] step_hold = 0;
    logic [31:0] step_hold_cycle = 0;

    logic [31:0] music_pos = 0;

    logic [7:0] component1; 
    logic [7:0] component2; 


    initial begin
        _20a = LOW;
        _18a = LOW;
        _13b = LOW;
        _8a  = LOW;
        _9b  = LOW;
        _6a  = LOW;
        _4a  = LOW;
        _2a  = LOW;
        _45a = LOW;
        _48b = LOW;

        _3b  = LOW;
    end

    midi_player #(
        .INIT_FILE      ("mcmidi1.txt")
    ) voice1 (
        .clk            (clk), 
        .point_num      (music_pos), 
        .point_out      (component1)
    );

    midi_player #(
        .INIT_FILE      ("mcmidi2.txt")
    ) voice2 (
        .clk            (clk), 
        .point_num      (music_pos), 
        .point_out      (component2)
    );

    always_ff @(posedge clk) begin
        if(step_hold == STEP_HOLD_TIME) begin 
            music_pos <= music_pos + 1;

            if(music_pos == AUDIO_LEN-1) begin
                music_pos <= 0;
            end
            else begin
                music_pos <= music_pos + 1;
            end

            step_hold <= 0;
        end
        else begin
            step_hold <= step_hold + 1;
        end
    end

    always_comb begin
        voltage = (component1 >> 1) + (component2 >> 1);

        _20a = voltage[7];
        _18a = voltage[6];
        _13b = voltage[5];
        _8a  = voltage[4];
        _9b  = voltage[3];
        _6a  = voltage[2];
        _4a  = voltage[1];
        _2a  = voltage[0];

        _3b = LOW;  // Address line
    end


// Synthesizer Control
    parameter I2C_FREQ_TIME = 256;
    parameter I2C_TRANS_POINT = 127;

    parameter I2C_INIT = 0;
    parameter I2C_BEGIN = 1;
    parameter I2C_SEND_ADDRESS = 2;
    parameter I2C_WAIT_ACK_ADDR = 3;
    parameter I2C_SEND_REG = 4;
    parameter I2C_WAIT_ACK_REG = 5;
    parameter I2C_SEND_BYTE = 6;
    parameter I2C_WAIT_ACK_BYTE = 7;
    parameter I2C_END = 8;

    parameter I2C_INST_CNT = 43;

    parameter SYNTH_I2C_ADDR = 8'b11000000;

    logic [31:0] scl_state = 0;
    logic [31:0] sda_loc = 0;

    logic [7:0] i2c_byte = 8'b11110000;
    logic [7:0] i2c_reg = 8'b10101010;
    logic [7:0] i2c_data = 8'b00000000;
    logic [7:0] i2c_mask = 8'b10000000;
    logic [7:0] masked_val = 8'b00000000;

    logic [0:0] send_data = FALSE;

    logic [31:0] i2c_start_timer = 0;

    logic [7:0] i2c_bus_state = I2C_INIT;

    logic [7:0] i2c_reg_list [I2C_INST_CNT-1:0];
    logic [7:0] i2c_byte_list [I2C_INST_CNT-1:0];

    logic [7:0] byte_num = 0;


    initial begin
        _5a  = 1'bZ;
        _0a  = 1'bZ;

        $readmemh("i2c_regs.txt", i2c_reg_list);
        $readmemh("i2c_bytes.txt", i2c_byte_list);
    end

    always_comb begin
        i2c_mask = 8'b10000000 >> sda_loc;
        masked_val = i2c_mask & i2c_data;
    end

    always_ff @(posedge clk) begin
        if(byte_num <= I2C_INST_CNT-1) begin
        if(i2c_start_timer == 8192) begin
            i2c_reg <= i2c_reg_list[byte_num];
            i2c_byte <= i2c_byte_list[byte_num];
            byte_num <= byte_num + 1;

            send_data <= TRUE;
            i2c_start_timer <= i2c_start_timer + 1;
        end
        else if (i2c_start_timer > 16384) begin 
            i2c_start_timer <= 0;  
        end
        else begin
            i2c_start_timer <= i2c_start_timer + 1;
        end
        end

        if(send_data == TRUE) begin
            if(scl_state == I2C_FREQ_TIME) begin
                scl_state <= 0;
                _0a <= !_0a;
            end
            else begin
                scl_state <= scl_state + 1;
            end

            case(i2c_bus_state)
                I2C_INIT: begin
                    _5a <= HIGH;
                    _0a <= HIGH;
                    i2c_bus_state <= I2C_BEGIN;
                end
                I2C_BEGIN: begin
                    if(_0a == HIGH && scl_state == I2C_TRANS_POINT) begin
                        _5a <= LOW;
                        i2c_bus_state <= I2C_SEND_ADDRESS;
                    end
                end

                I2C_SEND_ADDRESS: begin
                    i2c_data <= SYNTH_I2C_ADDR;

                    if(_0a == LOW && sda_loc <= 8 && scl_state == I2C_TRANS_POINT) begin
                        _5a <= masked_val != 0;
                        sda_loc <= sda_loc + 1;
                    end
                    else if (sda_loc > 8) begin
                        sda_loc <= 0;
                        i2c_bus_state <= I2C_WAIT_ACK_ADDR;
                    end
                end

                I2C_WAIT_ACK_ADDR: begin
                    _5a <= 1'bZ;
                    if(_0a == HIGH) begin
                        i2c_bus_state <= I2C_SEND_REG;
                    end
                end

                I2C_SEND_REG: begin
                    i2c_data <= i2c_reg;

                    if(_0a == LOW && sda_loc <= 8 && scl_state == I2C_TRANS_POINT) begin
                        _5a <= masked_val != 0;
                        sda_loc <= sda_loc + 1;
                    end
                    else if (sda_loc > 8) begin
                        sda_loc <= 0;
                        i2c_bus_state <= I2C_WAIT_ACK_REG;
                    end
                end

                I2C_WAIT_ACK_REG: begin
                    _5a <= 1'bZ;
                    if(_0a == HIGH) begin
                        i2c_bus_state <= I2C_SEND_BYTE;
                    end
                end

                I2C_SEND_BYTE: begin
                    i2c_data <= i2c_byte;

                    if(_0a == LOW && sda_loc <= 8 && scl_state == I2C_TRANS_POINT) begin
                        _5a <= masked_val != 0;
                        sda_loc <= sda_loc + 1;
                    end
                    else if (sda_loc > 8) begin
                        sda_loc <= 0;
                        i2c_bus_state <= I2C_WAIT_ACK_BYTE;
                    end
                end

                I2C_WAIT_ACK_BYTE: begin
                    _5a <= 1'bZ;
                    if(_0a == LOW && scl_state == I2C_TRANS_POINT) begin
                        i2c_bus_state <= I2C_END;
                    end
                end


                I2C_END: begin
                    if(_0a == HIGH && scl_state == I2C_TRANS_POINT) begin
                        send_data <= FALSE;
                        i2c_bus_state <= I2C_INIT;
                    end
                    else begin
                        _5a <= HIGH;
                    end
                end
            endcase
        end

        else begin
            _0a <= 1'bZ;
            _5a <= 1'bZ;
        end
    end
endmodule
