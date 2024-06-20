
`define         AHB_TRANS_IDLE                      2'b00
`define         AHB_DATA_WIDTH_BITS                 32
`include "mcse_def.svh"
module mcse_top_netlist_tb;

    localparam gpio_N = 32;
    localparam gpio_AW = 32;
    localparam gpio_PW = 2*gpio_AW+40;
    localparam scan_key_width = `SCAN_KEY_WIDTH;
    localparam scan_key_number = `SCAN_KEY_NUMBER;

	localparam    pAHB_ADDR_WIDTH                     = 32;
    localparam    pAHB_DATA_WIDTH                     = `AHB_DATA_WIDTH_BITS;
    localparam    pAHB_BURST_WIDTH                    = 3;
    localparam    pAHB_PROT_WIDTH                     = 4;
    localparam    pAHB_SIZE_WIDTH                     = 3;
    localparam    pAHB_TRANS_WIDTH                    = 2;
    localparam    pAHB_HRESP_WIDTH                    = 2;

    localparam    pAHB_HPROT_VALUE                    = (     1 << 0  // [0] : 1 = data access        ( 0 = op code access            )
                                                        |   1 << 1  // [1] : 1 = privileged access  ( 0 = user access               )
                                                        |   0 << 2  // [2] : 0 = not bufferable     ( 1 = bufferable                )
                                                        |   0 << 3); // [3] : 0 = not cacheable      ( 1 = cacheable                 )
    localparam    pAHB_HSIZE_VALUE                    =       (`AHB_DATA_WIDTH_BITS == 32 ) ? 3'b010  // (010 = 32-bit    )
                                                        :   (`AHB_DATA_WIDTH_BITS == 64 ) ? 3'b011  // (011 = 64-bit    )
                                                        :   (`AHB_DATA_WIDTH_BITS == 128) ? 3'b110  // (110 = 128-bit   )
                                                        :   3'b010; // Default to 32-bit
    localparam    pAHB_HBURST_VALUE                   = 3'b011;       // 011 = 4 beat incrementing    ( 111 = 16 beat incrementing    )
    localparam    pAHB_HMASTLOCK_VALUE                = 1'b1;         // 1 = locked transfer          ( 0 = unlocked transfer         )
    localparam    pAHB_HNONSEC_VALUE                  = 1'b0;         // 0 = Secure transfer          ( 1 = non secure transfer       )

    localparam   pPAYLOAD_SIZE_BITS                  = 256;
    localparam    pMAX_TRANSFER_WAIT_COUNT            = 16;
    localparam    pREVERSE_WORD_ORDER                 = 1;
    localparam   pREVERSE_BYTE_ORDER                 = 0;

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


    logic                 clk=0;
    logic                 rst_n;
    logic                 init_config_n; 
	logic  [gpio_N-1:0]   gpio_in;
    logic  [511:0]        lc_transition_id;
    logic                 lc_transition_request_in;
    logic  [511:0]        lc_authentication_id;
    logic                 lc_authentication_valid;
  
	logic [gpio_N-1:0]   gpio_out;

    logic [scan_key_width-1:0]           scan_key;
    logic                                scan_enable;
    logic                                scan_unlock;
    logic                                scan_out;


	initial begin :generate_clock
		while (1)
			#5 clk = ~clk;
	end	

    mcse_top #(
    .gpio_N(gpio_N), .gpio_AW(gpio_AW), .gpio_PW(gpio_PW), .gpio_PW(gpio_PW),
    .scan_key_width(scan_key_width), .scan_key_number(scan_key_number) )
    mcse ( .* );

    logic [511:0] lc_transition_id_testing = 512'h33a344a35afd82155e5a6ef2d092085d704dc70561dde45d27962d79ea56a24a33a344a35afd82155e5a6ef2d092085d704dc70561dde45d27962d79ea56a24a;
    logic [511:0] lc_authentication_id_oem = 512'h431909d9da263164ab4d39614e0c50a32774a49b3390a53ffa63e8d74b8e7c0b431909d9da263164ab4d39614e0c50a32774a49b3390a53ffa63e8d74b8e7c0b;
    logic [511:0] lc_transition_id_oem = 512'h988b6a57b75f5696f01b8207b1c99bc888b4a2421a0ab4b29bd302f5b8a93348988b6a57b75f5696f01b8207b1c99bc888b4a2421a0ab4b29bd302f5b8a93348; 
    logic [511:0] lc_authentication_id_deployment = 512'h8e30701845bea3e44d0aed1ba6d4893a0de91fea6f42571d3714a3c6daa399788e30701845bea3e44d0aed1ba6d4893a0de91fea6f42571d3714a3c6daa39978;
    logic [511:0] lc_transition_id_deployment = 512'h4893565d146d9fa19dc850e0c409b2a62ec5cb53eea4d4719c93a882f988284e4893565d146d9fa19dc850e0c409b2a62ec5cb53eea4d4719c93a882f988284e;
    logic [511:0] lc_authentication_id_recall = 512'hd995f5ddfb1625e3a33b0ee123b6672f35df88d6652eaec51d26f3a50b030ad8d995f5ddfb1625e3a33b0ee123b6672f35df88d6652eaec51d26f3a50b030ad8;
    logic [511:0] lc_transition_id_recall = 512'hcabc36e4f52fcd1a8b62d82d975e4c8595da7f6df52e2143174c3dc8b3870e03cabc36e4f52fcd1a8b62d82d975e4c8595da7f6df52e2143174c3dc8b3870e03; 
    logic [511:0] lc_authentication_id_endoflife = 512'hdf0f326b1bf6611d944491d7a0618af56ac57e391ba38425f9f33cafdd7439a9df0f326b1bf6611d944491d7a0618af56ac57e391ba38425f9f33cafdd7439a9; 

    
    
    task lifecycle_transition_request(input bit [511:0] id); 
        $display("[TB_TOP] Requesting a lifecycle transition..."); 
        $displayh("[TB_TOP] Lifecycle transition ID = ", id);

        lc_transition_request_in = 1;
        lc_transition_id = id; 
        @(posedge clk); 
        reset_handshake(); 
        lc_transition_request_in = 0;
        lc_transition_id = 0; 

    endtask   

    task lifecycle_auth(input bit [511:0] id);

        $display("[TB_TOP] Requesting LC Authentication...");   
        $displayh("[TB_TOP] LC Key = ", id);       

        lc_authentication_valid = 1; 
        lc_authentication_id = id;

        @(posedge clk); 

    endtask 

    task operation_release_handshake();
        
        $display("[TB_TOP] Waiting for operation release trigger");
        while (gpio_out[4] != 1) begin // sending reset
            
            @(posedge clk); 
        end 
        $display("[TB_TOP] Normal operation release received");
        gpio_in[5] = 1; // host ack
        $display("[TB_TOP] Sending host normal operation release ACK...");
        @(posedge clk);


    endtask

    task reset_handshake(); 
        
        $display("[TB_TOP] Waiting for Host Soc reset request...");
        while (gpio_out[0] != 1) begin
            
            @(posedge clk);
        end 
        
        $displayh("[TB_TOP] Host Soc reset request received");
        gpio_in[1] = 1;
        $display("[TB_TOP] Sending host SoC reset ACK...");
        @(posedge clk);
        @(posedge clk); 
        @(posedge clk); 
        gpio_in[1] = 0; 
    endtask 

    task bus_wakeup_handshake();
        
        while(gpio_out[6] != 1) begin
            @(posedge clk); 
            
        end 
        
        $display("[TB_TOP] Bus wakeup received");
        gpio_in[7] = 1; 
        $display("[TB_TOP] Sending bus wakeup ACK...");
        @(posedge clk); 
        gpio_in[7] = 0;
    
    endtask 

    task testing_lifecycle_first_boot();
        reset_handshake(); 
         
        bus_wakeup_handshake(); 
        
        $displayh("[MCSE] Generating Chip ID...");
        $displayh("[MCSE] Chip ID generation complete");
        $displayh("[MCSE] Encrypting Chip ID and storing into memory...");
        $displayh("[MCSE] Chip ID generation complete...");

    

        $display("[MCSE] Secure boot complete in Manufacture and Test lifecycle complete");
        $display("[MCSE] Polling for lifecycle transition request"); 
        lifecycle_transition_request(lc_transition_id_testing);     
        $display("[TB_TOP] Transitioning lifecycle to OEM/Packaging...");
    endtask 

    task oem_lifecycle_first_boot();
        reset_handshake();
        lifecycle_auth(lc_authentication_id_oem);
        bus_wakeup_handshake();
        
        $displayh("[MCSE] Generating Chip ID...");
        $displayh("[MCSE] Chip ID generation complete");
        $displayh("[MCSE] Succesfully completed Lifecycle and Chip ID authentication...");
        operation_release_handshake();
        
        lifecycle_transition_request(lc_transition_id_oem); 
        $display("[TB_TOP] Transitioning lifecycle to Deployment...");

    endtask 

    task deployment_lifecycle_first_boot();
        reset_handshake();
        lifecycle_auth(lc_authentication_id_deployment);
        bus_wakeup_handshake();
        
        operation_release_handshake();
        
        lifecycle_transition_request(lc_transition_id_deployment);
        $display("[TB_TOP] Tranistioning lifecycle to Recall...");
    endtask 

    task recall_lifecycle_first_boot();
        reset_handshake();
        lifecycle_auth(lc_authentication_id_recall);
        bus_wakeup_handshake();
        
        operation_release_handshake();
        
        lifecycle_transition_request(lc_transition_id_recall);
        $display("[TB_TOP] Transitioning lifecycle to End of Life...");
    endtask 

    task endoflife_lifecycle_first_boot();
        lifecycle_auth(lc_authentication_id_endoflife);
    endtask 

    logic [511:0] key_temp;
    

    task scan_control();
        integer i= 0;

        $display("[TB_TOP] Testing scan unlock status before key-loading process.");
        $display("[MCSE] Scan unlock status: %x",scan_unlock);
        $display("[TB_TOP] Starting scan input Key Loading process.");

        for (i = 0; i < scan_key_number; i = i + 1) begin
            scan_key = key_temp[(i*32) +: 32];  // Extract 32 bits at a time
            $display("[MCSE] Checking scan key sequence: %d", i+1);
            @(posedge clk);
        end

        @(posedge clk);
        @(posedge clk);
        
        // Enable scan for few clock cycles and stream scan_out
        for (int i = 0; i < 5; i++) begin
            scan_enable = 1;
            $display("[TB_TOP] Enabling scan chain for few clock cycles to stream scan out");
            if (scan_unlock == 1) begin
                @(posedge clk);
                @(posedge clk);
                $display("[MCSE] Scan unlock successful");
                $display("[MCSE] Scan unlock status: %x",scan_unlock);
                $displayh("[TB_TOP] Extracting Scan Out = ", scan_out);
            end
            else begin
                $display("[MCSE] Scan unlock failed");
                $display("[MCSE] Scan unlock status: %x",scan_unlock);
                $displayh("[TB_TOP] Extracting Scan Out = ", scan_out);
            end
            @(posedge clk);
        end
    
        scan_enable = 0;

        $display("[MCSE] Terminating vimscan simulation.");
    endtask 

    
    
    initial begin : drive_inputs

		$display("--------------------------------------------------------------------------------------");
		$display("----------University of Florida Minimally Configured Security Engine (MCSE)-----------");
		$display("-----------------------------------AISS Phase III-------------------------------------");
		$display("--------------------------------------------------------------------------------------");
		$display("--------------------------------------------------------------------------------------");

        $display("[TB_TOP] Asserting global reset and initializing MCSE configuration");
        for (integer i = 0; i < 10; i=i+1) begin
            rst_n = 0;
            init_config_n =0; 
            gpio_in = 0; 
            I_hrdata = 0;
            I_hready = 1;
            I_hresp = 0;
            I_hreadyout = 1;
            scan_key = 0;
            @(posedge clk);
        end 

        key_temp = 512'h87A5E932FA1BC49DFF8A0B2C3D4E5F607891ABCDEF0123456789ABCDEF012345; // input challenge key for vimscan

        rst_n = 1;
        init_config_n = 1;
        @(posedge clk); 
        @(posedge clk); 
        @(posedge clk); 
        
        $dumpfile("netlist.vcd");
        $dumpvars(0, mcse_top_netlist_tb);

        $display("[TB_TOP] Deasserting global reset and initializing MCSE");


        $displayh("[MCSE] Starting Secure Boot in Manufacture & Test Lifecycle");
        testing_lifecycle_first_boot(); 
        reset_handshake();


        $displayh("[MCSE] Starting Secure Boot in Packaging/OEM");
        oem_lifecycle_first_boot(); 
        scan_control();
        reset_handshake();

        
        $displayh("[MCSE] Starting Secure Boot in Deployment");
        deployment_lifecycle_first_boot();
        reset_handshake();

       
        $displayh("[MCSE] Starting Secure Boot in Recall");
        recall_lifecycle_first_boot(); 
        reset_handshake();
        
        $displayh("[MCSE] Starting Secure Boot in End-of-Life");
        endoflife_lifecycle_first_boot();
        reset_handshake();
        
       
        $finish; 
    end 
    

endmodule 