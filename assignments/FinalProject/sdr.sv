// Software Defined Radio

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
    output logic    _48b
);

    parameter STEPS = 64;

    parameter ADDRESS_TIME = 1;
    parameter RW_START_TIME = 2;
    parameter RW_STOP_TIME = 3;

    parameter STEP_HOLD_TIME = 2;

    parameter HIGH = 1;
    parameter LOW = 0;

    logic [22:0] count = 0;
    logic [22:0] update_count = 0;
    logic [0:0] state = 0;
    logic [7:0] voltage = 0;

    logic [7:0] sine_pos = 0;

    logic [7:0] sine_lut [STEPS-1:0];

    logic [7:0] step_hold = 0;

    initial begin
        _20a = LOW;
        _18a = LOW;
        _13b = LOW;
        _8a  = LOW;
        _9b  = LOW;
        _6a  = LOW;
        _4a  = LOW;
        _2a  = LOW;
        _3b  = LOW;
        _45a = LOW;
        _48b = LOW;

        $readmemh("sine_64.txt", sine_lut);
    end

    always_ff @(posedge clk) begin
        // if(step_hold == STEP_HOLD_TIME) begin 
            voltage <= sine_lut[sine_pos];

            sine_pos <= sine_pos + 1;

            if(sine_pos == STEPS-1) begin
                sine_pos <= 0;
            end
            else begin
                sine_pos <= sine_pos + 1;
            end

            step_hold <= 0;
        // end
        // else begin
        //    step_hold <= step_hold + 1;
        //end

    end
    
    always_comb begin
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

    always_ff @(posedge clk) begin
        _48 = ~_48;
    end

endmodule
