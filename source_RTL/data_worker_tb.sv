`timescale 1 ns / 100 ps

`define         AHB_TRANS_IDLE                      2'b00
`define         AHB_DATA_WIDTH_BITS                 32

module data_worker_tb;

	parameter    pAHB_ADDR_WIDTH                     = 32;
    parameter    pAHB_DATA_WIDTH                     = `AHB_DATA_WIDTH_BITS;
    parameter    pAHB_BURST_WIDTH                    = 3;
    parameter    pAHB_PROT_WIDTH                     = 4;
    parameter    pAHB_SIZE_WIDTH                     = 3;
    parameter    pAHB_TRANS_WIDTH                    = 2;
    parameter    pAHB_HRESP_WIDTH                    = 2;

    parameter    pAHB_HPROT_VALUE                    = (     1 << 0  // [0] : 1 = data access        ( 0 = op code access            )
                                                        |   1 << 1  // [1] : 1 = privileged access  ( 0 = user access               )
                                                        |   0 << 2  // [2] : 0 = not bufferable     ( 1 = bufferable                )
                                                        |   0 << 3); // [3] : 0 = not cacheable      ( 1 = cacheable                 )
    parameter    pAHB_HSIZE_VALUE                    =       (`AHB_DATA_WIDTH_BITS == 32 ) ? 3'b010  // (010 = 32-bit    )
                                                        :   (`AHB_DATA_WIDTH_BITS == 64 ) ? 3'b011  // (011 = 64-bit    )
                                                        :   (`AHB_DATA_WIDTH_BITS == 128) ? 3'b110  // (110 = 128-bit   )
                                                        :   3'b010; // Default to 32-bit
    parameter    pAHB_HBURST_VALUE                   = 3'b011;       // 011 = 4 beat incrementing    ( 111 = 16 beat incrementing    )
    parameter    pAHB_HMASTLOCK_VALUE                = 1'b1;         // 1 = locked transfer          ( 0 = unlocked transfer         )
    parameter    pAHB_HNONSEC_VALUE                  = 1'b0;         // 0 = Secure transfer          ( 1 = non secure transfer       )

    parameter    pPAYLOAD_SIZE_BITS                  = 128;
    parameter    pMAX_TRANSFER_WAIT_COUNT            = 16;
    parameter    pREVERSE_WORD_ORDER                 = 1;
    parameter    pREVERSE_BYTE_ORDER                 = 0;

	logic   [pAHB_ADDR_WIDTH-1        :0]   O_haddr;
    logic   [pAHB_BURST_WIDTH-1       :0]   O_hburst;
    logic                                   O_hmastlock;
    logic   [pAHB_PROT_WIDTH-1        :0]   O_hprot;
    logic                                   O_hnonsec;
    logic   [pAHB_SIZE_WIDTH-1        :0]   O_hsize;
    logic   [pAHB_TRANS_WIDTH-1       :0]   O_htrans;
    logic   [pAHB_DATA_WIDTH-1        :0]   O_hwdata;
    logic                                   O_hwrite;
    logic    [pAHB_DATA_WIDTH-1        :0]   I_hrdata;
    logic                                    I_hready;
    logic    [pAHB_HRESP_WIDTH-1       :0]   I_hresp;
    logic                                    I_hreadyout;

    // ------------------------------------------------------------------

    // Internal data port
    logic    [pAHB_ADDR_WIDTH-1          :0] I_int_addr;             // Target address for write operations
    logic    [pPAYLOAD_SIZE_BITS-1       :0] I_int_wdata;            // Outbound data for write operations
    logic   [pPAYLOAD_SIZE_BITS-1       :0] O_int_rdata;            // Inbound data for read operations

    logic                                    I_int_write;            // 0 = Read; 1 = Write
    logic                                   O_int_rdata_valid;      // High if rdata is valid; low otherwise
//    output  reg                                     O_int_ready;            // Ready to accept new transaction

    // ------------------------------------------------------------------

    // Job control signals
    logic                                    I_go;                   // Assert high until transfer is done (O_done == 1)
    logic                                   O_done;                 // Pulse high; when transfer is done.

    // System Pins
    logic                                    clk=0;
    logic /* asynchronous; active low */     rst_n=0;
	
	data_worker DUT (.*);
	
    logic [pAHB_ADDR_WIDTH-1          :0] tmp_address;
    logic [pPAYLOAD_SIZE_BITS-1       :0] tmp_data; 

	initial begin :generate_clock
		while (1)
			#5 clk = ~clk;
	end	
	
    task write_transfer(input bit [pAHB_ADDR_WIDTH-1:0] addr, input bit [pPAYLOAD_SIZE_BITS-1:0] wdata);

        $display("[Master] Initiating write request");
        $display("[Master] Internal Start address: %0h", addr);
        $display("[Master] Internal Write data: %0h", wdata);
        // internal signals to initiate a write request 
        I_int_write = 1;
        I_int_addr = addr; 
        I_int_wdata = wdata;
        I_go = 1; 
        
        I_hreadyout = 1; // slave indicating that it is ready to receive data from master (or is also wait signal)
        $display("[Slave] hreadyout = %0h...Ready to receive data", I_hreadyout);
        @(posedge clk); // initiate transfer
        I_go = 0;
        
        //@(posedge clk); // address phase starting here 
        if (O_hwrite) begin
            $display("[Slave] HWRITE = %0h...This is a write request", O_hwrite);
        end 
        else begin 
            $display("[Slave] HWRITE = %0h...This is a read request", O_hwrite);
        end 
        
        $display("[Slave] Address phase...");
        $display("[Slave] Address: %0h", O_haddr);
        $display("[Slave] Data: %0h", O_hwdata);
        @(posedge clk);
        $display("[Slave] Data phase...");
        // 128 bit payload being sent 32 bits at a time
        while (O_done != 1) begin
            $display("[Slave] Address: %0h", O_haddr);
            $display("[Slave] Data: %0h", O_hwdata);
            @(posedge clk); 
        end 
      
        $display("[Slave] Done signal received...Transfer complete");
        
    endtask 

    task read_transfer(input bit [pAHB_ADDR_WIDTH-1:0] addr);
        $display("[Master] Initiating read request");
        $display("[Master] Internal Start address: %0h", addr);

        // internal signals to initiate a read request 
        I_int_write = 0;
        I_int_addr = addr; 
        I_go = 1; 
        
        I_hreadyout = 1; // slave indicating that it is ready to receive data from master 
        $display("[Slave] hreadyout = %0h...Ready to receive data", I_hreadyout);
        @(posedge clk); // initiate transfer
        I_go = 0;
        //@(posedge clk); // address phase starting here  
        if (O_hwrite) begin
            $display("[Slave] HWRITE = %0h...This is a write request", O_hwrite);
        end 
        else begin 
            $display("[Slave] HWRITE = %0h...This is a read request", O_hwrite);
        end 

        $display("[Slave] Address phase...");
        $display("[Slave] Address: %0h", O_haddr);
        @(posedge clk);

        $display("[Slave] Producing data at bus for each address");
        while (O_done != 1) begin
            $display("[Slave] Address: %0h", O_haddr);
            I_hrdata = $urandom();
            $display("[Slave] Data to Master: %0h", I_hrdata);
            @(posedge clk);
        end

        $display("[Slave] Done signal received");

        if (O_int_rdata_valid) begin
            $display("[Master] Internal read data valid signal received...Transfer Complete");
            $display("[Master] Internal read data = %0h", O_int_rdata);
        end  
        
       
    endtask 


	initial begin : drive_inputs
	
	I_hrdata = 0;
	I_hready = 0;
	I_hresp = 0;
	I_hreadyout = 0;
	I_int_addr = 0;
	I_int_wdata = 0;
	I_int_write = 0;
	I_go = 0;
	
	for (integer i = 0; i < 10; i=i+1) begin
		rst_n = 0;
		@(posedge clk);
	end 
	
	rst_n = 1;
	@(posedge clk);

    tmp_address = 'h08;
    tmp_data = 'h31c3001967d4acf1bcb25768708627ae;
    //write_transfer(tmp_address, tmp_data);
    @(posedge clk);
    read_transfer(tmp_address); 

	@(posedge clk);
	
	
	$finish;
	
	end 
	
endmodule 

