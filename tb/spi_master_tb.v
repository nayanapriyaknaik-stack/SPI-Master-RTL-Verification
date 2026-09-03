`timescale 1ns/1ps

module spi_master_tb;

    reg        clk;
    reg        rst_n;
    reg        start;
    reg  [7:0] tx_data;

    wire       sclk;
    wire       mosi;
    wire       cs_n;
    wire       ready;

    integer errors;
    integer i;

    // DUT
    spi_master uut (
        .clk     (clk),
        .rst_n   (rst_n),
        .start   (start),
        .tx_data (tx_data),
        .sclk    (sclk),
        .mosi    (mosi),
        .cs_n    (cs_n),
        .ready   (ready)
    );

    // 50 MHz system clock
    always #10 clk = ~clk;

    // ------------------------------------------------------------
    // Task: Verify one SPI transaction
    // ------------------------------------------------------------
    task verify_transaction;
        input [7:0] test_data;

        begin
            $display("");
            $display("========================================");
            $display("Starting SPI transaction: 0x%02h", test_data);
            $display("========================================");

            // Wait until controller is ready
            @(posedge clk);

            if (ready !== 1'b1) begin
                $display("ERROR: Controller is not ready");
                errors = errors + 1;
            end

            // Apply transaction data and start pulse
            tx_data = test_data;
            start   = 1'b1;

            @(posedge clk);
            start = 1'b0;

            // Wait for chip select assertion
            @(negedge cs_n);

            if (ready !== 1'b0) begin
                $display("ERROR: ready did not go LOW");
                errors = errors + 1;
            end

            $display("CS asserted successfully.");

            // Check all 8 transmitted bits
            for (i = 7; i >= 0; i = i - 1) begin

                @(posedge sclk);

                if (mosi !== test_data[i]) begin
                    $display(
                        "ERROR: Bit %0d mismatch - Expected %b, Got %b",
                        i,
                        test_data[i],
                        mosi
                    );
                    errors = errors + 1;
                end
                else begin
                    $display(
                        "PASS: Bit %0d = %b",
                        i,
                        mosi
                    );
                end

            end

            // Wait for transaction completion
            @(posedge ready);

            if (cs_n !== 1'b1) begin
                $display("ERROR: CS did not deassert");
                errors = errors + 1;
            end

            $display("Transaction 0x%02h completed.", test_data);

        end
    endtask

    // ------------------------------------------------------------
    // Main test sequence
    // ------------------------------------------------------------
    initial begin

        // Waveform dump
        $dumpfile("sim/spi_simulation.vcd");
        $dumpvars(0, spi_master_tb);

        // Initialize
        clk     = 1'b0;
        rst_n   = 1'b0;
        start   = 1'b0;
        tx_data = 8'h00;
        errors  = 0;

        $display("");
        $display("========================================");
        $display(" SPI MASTER RTL VERIFICATION STARTED");
        $display("========================================");

        // Reset
        #40;
        rst_n = 1'b1;

        // Allow controller to settle
        #40;

        // Check reset/idle state
        if (ready !== 1'b1) begin
            $display("ERROR: ready should be HIGH after reset");
            errors = errors + 1;
        end
        else begin
            $display("PASS: Controller ready after reset.");
        end

        if (cs_n !== 1'b1) begin
            $display("ERROR: CS should be HIGH when idle");
            errors = errors + 1;
        end
        else begin
            $display("PASS: CS inactive after reset.");
        end

        // Test 1
        verify_transaction(8'hA5);

        // Small gap between transactions
        #100;

        // Test 2
        verify_transaction(8'h3C);

        // Final result
        #100;

        $display("");
        $display("========================================");

        if (errors == 0) begin
            $display(" ALL SPI VERIFICATION TESTS PASSED");
        end
        else begin
            $display(" VERIFICATION FAILED: %0d ERROR(S)", errors);
        end

        $display("========================================");
        $display("");

        $finish;
    end

endmodule
