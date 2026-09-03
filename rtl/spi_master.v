module spi_master (
    input  wire       clk,       // System Clock
    input  wire       rst_n,     // Asynchronous Active-Low Reset
    input  wire       start,     // Trigger transaction
    input  wire [7:0] tx_data,   // 8-bit Data byte to transmit
    output reg        sclk,      // SPI Serial Clock output
    output reg        mosi,      // Master Out Slave In data line
    output reg        cs_n,      // Active-Low Chip Select
    output reg        ready      // High when controller is idle
);

    // FSM State Encoding using Local Parameters
    localparam STATE_IDLE     = 2'b00;
    localparam STATE_START    = 2'b01;
    localparam STATE_TRANSFER = 2'b10;
    localparam STATE_DONE     = 2'b11;

    reg [1:0] current_state, next_state;
    reg [7:0] shift_reg;
    reg [2:0] bit_cnt;
    reg       clk_div; // Simplistic divide-by-2 clock tracking

    // State Transition Logic (Sequential Block)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            current_state <= STATE_IDLE;
        else
            current_state <= next_state;
    end

    // Next State Logic (Combinational Block)
    always @(*) begin
        case (current_state)
            STATE_IDLE:     next_state = start ? STATE_START : STATE_IDLE;
            STATE_START:    next_state = STATE_TRANSFER;
            STATE_TRANSFER: next_state = (bit_cnt == 3'b000 && clk_div == 1'b1) ? STATE_DONE : STATE_TRANSFER;
            STATE_DONE:     next_state = STATE_IDLE;
            default:        next_state = STATE_IDLE;
        endcase
    end

    // Output & Internal Shift Register Control Logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sclk        <= 1'b0;
            mosi        <= 1'b0;
            cs_n        <= 1'b1;
            ready       <= 1'b1;
            bit_cnt     <= 3'b111;
            shift_reg   <= 8'h00;
            clk_div     <= 1'b0;
        end else begin
            case (current_state)
                STATE_IDLE: begin
                    sclk    <= 1'b0;
                    cs_n    <= 1'b1;
                    ready   <= 1'b1;
                    bit_cnt <= 3'b111;
                    clk_div <= 1'b0;
                    mosi    <= 1'b0;
                end

                STATE_START: begin
                    cs_n      <= 1'b0;
                    ready     <= 1'b0;
                    shift_reg <= tx_data; // Capture parallel input data
                end

                STATE_TRANSFER: begin
                    clk_div <= !clk_div;
                    if (clk_div == 1'b0) begin
                        sclk <= 1'b1; // Rising Edge: Slave samples data
                        mosi <= shift_reg[bit_cnt]; // Drive data bit out
                    end else begin
                        sclk <= 1'b0; // Falling Edge
                        if (bit_cnt > 0)
                            bit_cnt <= bit_cnt - 1'b1;
                    end
                end

                STATE_DONE: begin
                    cs_n  <= 1'b1;
                    ready <= 1'b1;
                    mosi  <= 1'b0;
                end
            endcase
        end
    end
endmodule
