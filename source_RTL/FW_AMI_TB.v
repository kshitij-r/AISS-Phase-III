module top_module_tb;
    reg clk;
    reg rst;
    reg [127:0] encrypted_input;
    wire [255:0] hash_output;
    reg [255:0] expected_hash; // Expected hash value
    reg trigger; // Trigger signal
    wire [255:0] ChipID; // ChipID

    // Instantiate the top-level module
    top_module top_module_inst (
        .clk(clk),
        .rst(rst),
        .trigger(trigger),
        .encrypted_input(encrypted_input),
        .expected_hash(expected_hash),
        .hash_output(hash_output),
        .ChipID(ChipID)
    );

    // Clock generation block
    always begin
        #5 clk = ~clk;
    end

    // Testbench stimulus
    initial begin
        // Initialize signals
        clk = 0;
        rst = 1;
        trigger = 0;

        // Apply reset
        #10 rst = 0;
        #10 rst = 1;

        // Trigger signal generation
        for (integer i = 0; i < 10; i = i + 1) begin
            #10;
            trigger = $random % 2; //random integer varying between 0 and 1
            if (trigger) begin
                encrypted_input = $random;
                // Generate expected_hash based on ChipID
                case (ChipID)
                    256'h0123456789abcdef: expected_hash = $random;
                    256'hfedcba987654321: expected_hash = $random;
                    // Add more cases as needed...
                    default: expected_hash = $random;
                endcase
            end
        end

        // Finish the simulation
        $finish;
    end
endmodule
