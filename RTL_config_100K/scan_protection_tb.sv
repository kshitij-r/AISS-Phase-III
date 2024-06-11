module vim_control_tb() ;

    localparam scan_key_width = 64;
    localparam scan_key_number = 8;

    logic clk, rst_n; 
    wire scan_unlock;
    logic [scan_key_width-1:0] scan_key;
    logic [(scan_key_width*scan_key_number - 1):0] key_temp;

    integer i= 0;

    //Module declaration
    vim_scan_control DUT(
        .clk(clk), 
        .rst_n(rst_n),
        .scan_key(scan_key), 
        .scan_unlock(scan_unlock)
    );


    initial begin
        clk = 0;
        forever #1 clk = !clk;
    end

    initial begin

        $display("Resetting the entire system.\n");
        rst_n = 0 ;
        
        
        // Hold the reset high for 10 clock cycles        
        $display("Holding the reset for 10 clock cycles.\n");
        repeat(10) @(posedge clk);
        rst_n = 1 ;

        $display("Testing the unlock status before key-loading process.\n");
        $display("The Unlock status: %x.\n",scan_unlock);
        $display("Starting the Key Loading process.\n");
        //  Start the key loading process
        key_temp = 512'h87A5E932FA1BC49DFF8A0B2C3D4E5F607891ABCDEF0123456789ABCDEF012345;

        for (i = 0; i < scan_key_number; i = i + 1) begin
            scan_key = key_temp[(i*32) +: 32];  // Extract 32 bits at a time
            $display("Loading key number: %d.\n", i+1);
            $displayh("scan_key = ", scan_key);
            @(posedge clk);
        end

        repeat(10) @(posedge clk);

        if (scan_unlock == 1) begin
            $display("Scan unlock successful");
            $display("The Unlock status: %x.\n",scan_unlock);
        end
        else begin
            $display("Scan unlock failed");
            $display("The Unlock status: %x.\n",scan_unlock);
        end

        $display("Terminating simulation.\n");

        $finish();


    end

endmodule