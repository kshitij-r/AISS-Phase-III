//`timescale 1 ns / 100 ps
`include "mcse_def.svh"
`define         AHB_TRANS_IDLE                      2'b00
`define         AHB_DATA_WIDTH_BITS                 32

module mcse_top_tb;
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

    int k = 0;

    
    
    task bus_wakeup_handshake();
        while (gpio_out[6] != 1) begin // bus wakeup
            @(posedge clk); 
        end 

        gpio_in[7] = 1; // bus wakeup ack
        @(posedge clk); 
    endtask

    task chipid_generation(); 
        while (~mcse.control_unit.secure_boot.mcse_id_done_r) begin
            @(posedge clk); 
        end  
        bus_wakeup_handshake(); 
        
        $display("[MCSE] Generating Chip ID...");
        while (~mcse.control_unit.secure_boot.chip_id_generation_done_r) begin
            @(posedge clk); 
        end 
        $display("[MCSE] Chip ID generation complete");
        @(posedge clk); 
   

    endtask


    task chipid_auth();
        chipid_generation(); 

        while (~mcse.control_unit.secure_boot.chip_id_challenge_done_r) begin
            @(posedge clk); 
        end
        
        $displayh("[MCSE] Golden Chip ID = ", mcse.control_unit.mem.ram[0][255:0]);
        $displayh("[MCSE] Generated Chip ID = " , mcse.control_unit.secure_boot.encryption_output_r);
        $displayh("[MCSE] Authentic Chip ID Value = ", mcse.control_unit.secure_boot.authentic_chip_id_r); 
    endtask

    task lifecycle_transition_request(input bit [511:0] id); 
        $display("[TB_TOP] Requesting a lifecycle transition..."); 
        $displayh("[TB_TOP] Lifecycle transition ID = ", id);
        $display("[MCSE] Servicing lifecycle transition request..."); 


        while (mcse.control_unit.secure_boot.lc_transition_request) begin
            $display("Stall until internal lifecycle transition request signal is deasserted...");
            @(posedge clk); 
        end 

        lc_transition_request_in = 1;
        lc_transition_id = id; 

        while (mcse.control_unit.secure_boot.lc_transition_done_r==0) begin
            @(posedge clk);
        end
        lc_transition_request_in = 0;
        lc_transition_id = 0;
        $displayh("[MCSE] Lifecycle Transition Success Value = ", mcse.control_unit.secure_boot.lc_transition_success_r);
        if (mcse.control_unit.secure_boot.lc_transition_success_r) begin
            $display("[MCSE] Lifecycle transition successful");
        end 
        else begin
            $display("[MCSE] Lifecycle transition failed");
        end  

        if (mcse.control_unit.secure_boot.lc_state == 3'b001) begin
            $display("[MCSE] Booting into Manufacture and Test lifecycle");
        end 
        else if (mcse.control_unit.secure_boot.lc_state == 3'b010) begin
            $display("[MCSE] Booting into Packaging/OEM lifecycle");
        end 
        else if (mcse.control_unit.secure_boot.lc_state == 3'b011) begin
            $display("[MCSE] Booting into Deployment lifecycle");
        end 
        else if (mcse.control_unit.secure_boot.lc_state == 3'b100) begin
            $display("[MCSE] Booting into Recall lifecycle");
        end 
        else if (mcse.control_unit.secure_boot.lc_state == 3'b101) begin
            $display("[MCSE] Booting into End of Life lifecycle");
        end

    endtask   

    task lifecycle_auth(input bit [511:0] id);

        $display("[TB_TOP] Requesting Lifecycle Authentication...");   
        $displayh("[TB_TOP] Lifecycle Key = ", id);       

        lc_authentication_valid = 1; 
        lc_authentication_id = id;

        while (~mcse.control_unit.secure_boot.lifecycle_authentication_done_r) begin
            @(posedge clk);
        end
        
        $display("[MCSE] Lifecycle Authentication Complete"); 
        $displayh("[MCSE] Lifecycle Authentication Value = ", mcse.control_unit.secure_boot.lifecycle_authentication_value_r);
        if (mcse.control_unit.secure_boot.lifecycle_authentication_value_r) begin
            $display("[MCSE] Lifecycle authentication successful");
        end
        else begin
            $display("[MCSE] Lifecycle authentication failed");
        end 

        while (mcse.control_unit.secure_boot.lifecycle_authentication_done_r) begin
            @(posedge clk); 
        end 
        
        lc_authentication_valid = 0; 
        lc_authentication_id = 0; 

    endtask 

    logic [511:0] lc_transition_id_testing = 512'h33a344a35afd82155e5a6ef2d092085d704dc70561dde45d27962d79ea56a24a33a344a35afd82155e5a6ef2d092085d704dc70561dde45d27962d79ea56a24a;
    logic [511:0] lc_authentication_id_oem = 512'h431909d9da263164ab4d39614e0c50a32774a49b3390a53ffa63e8d74b8e7c0b431909d9da263164ab4d39614e0c50a32774a49b3390a53ffa63e8d74b8e7c0b;
    logic [511:0] lc_transition_id_oem = 512'h988b6a57b75f5696f01b8207b1c99bc888b4a2421a0ab4b29bd302f5b8a93348988b6a57b75f5696f01b8207b1c99bc888b4a2421a0ab4b29bd302f5b8a93348; 
    logic [511:0] lc_authentication_id_deployment = 512'h8e30701845bea3e44d0aed1ba6d4893a0de91fea6f42571d3714a3c6daa399788e30701845bea3e44d0aed1ba6d4893a0de91fea6f42571d3714a3c6daa39978;
    logic [511:0] lc_transition_id_deployment = 512'h4893565d146d9fa19dc850e0c409b2a62ec5cb53eea4d4719c93a882f988284e4893565d146d9fa19dc850e0c409b2a62ec5cb53eea4d4719c93a882f988284e;
    logic [511:0] lc_authentication_id_recall = 512'hd995f5ddfb1625e3a33b0ee123b6672f35df88d6652eaec51d26f3a50b030ad8d995f5ddfb1625e3a33b0ee123b6672f35df88d6652eaec51d26f3a50b030ad8;
    logic [511:0] lc_transition_id_recall = 512'hcabc36e4f52fcd1a8b62d82d975e4c8595da7f6df52e2143174c3dc8b3870e03cabc36e4f52fcd1a8b62d82d975e4c8595da7f6df52e2143174c3dc8b3870e03; 
    logic [511:0] lc_authentication_id_endoflife = 512'hdf0f326b1bf6611d944491d7a0618af56ac57e391ba38425f9f33cafdd7439a9df0f326b1bf6611d944491d7a0618af56ac57e391ba38425f9f33cafdd7439a9; 
    

    task testing_lifecycle_first_boot();
        $display("[MCSE] Booting into Manufacture & Test lifecycle");
        $displayh("[MCSE] First boot flag value = ", mcse.control_unit.secure_boot.first_boot_flag_r);
        if (mcse.control_unit.secure_boot.first_boot_flag_r) begin
            $display("[MCSE] Proceeding with Chip ID generation...");
        end 
        
        chipid_generation(); 

        while ( ~mcse.control_unit.secure_boot.memory_write_done_r) begin
            @(posedge clk); 
        end 
        gpio_in = 0; 
        @(posedge clk); 
        $display("[MCSE] Encrypting Chip ID and storing into memory..."); 
        $displayh("[MCSE] Chip ID stored in memory = ", mcse.control_unit.mem.ram[0][255:0]); 
        $display("[MCSE] Chip ID generation complete...");
        $displayh("[MCSE] First boot flag value = ", mcse.control_unit.secure_boot.first_boot_flag_r);
    endtask 

    task oem_lifecycle_first_boot();
        $displayh("[MCSE] First boot flag value = ", mcse.control_unit.secure_boot.first_boot_flag_r);
        lifecycle_auth(lc_authentication_id_oem); 
        chipid_auth(); 
        if (mcse.control_unit.secure_boot.lifecycle_authentication_value_r && mcse.control_unit.secure_boot.authentic_chip_id_r) begin
            $display("[MCSE] Succesfully completed Lifecycle and Chip ID authentication...");
        end
        gpio_in = 0; 
        @(posedge clk); 
        $displayh("[MCSE] First boot flag value = ", mcse.control_unit.secure_boot.first_boot_flag_r);
        operation_release_handshake();
    endtask 

    task operation_release_handshake();
        //$display("Waiting for operation release trigger");
        while (gpio_out[4] != 1) begin // sending reset
            @(posedge clk); 
        end 

        $display("[TB_TOP] Normal operation release trigger received...Sending host normal operation release ACK...");

        gpio_in[5] = 1; // host ack

        // Wait for the completion of the reset routine
        while (~mcse.control_unit.secure_boot.operation_release_done_r) begin
            @(posedge clk);
        end

        $display("[MCSE] Normal operation release ACK recieved...Normal operation release completed");
    endtask

    task deployment_lifecycle_first_boot();
        // $displayh("[MCSE] Current Lifecycle State = ", mcse.control_unit.secure_boot.lc_state); 
        $displayh("[MCSE] First boot flag value = ", mcse.control_unit.secure_boot.first_boot_flag_r);
        lifecycle_auth(lc_authentication_id_deployment); 
        chipid_auth(); 
        if (mcse.control_unit.secure_boot.lifecycle_authentication_value_r && mcse.control_unit.secure_boot.authentic_chip_id_r) begin
            $display("[MCSE] Succesfully completed Lifecycle and Chip ID authentication...");
        end
        @(posedge clk); 
        $displayh("[MCSE] First boot flag value = ", mcse.control_unit.secure_boot.first_boot_flag_r);

        operation_release_handshake(); 

    endtask 
    
    task reset_handshake();
        while (gpio_out[0] != 1) begin // sending reset
            @(posedge clk); 
        end 
    
        $display("[TB_TOP] Reset request received...Sending host ACK");

        gpio_in[1] = 1; // host ack
        @(posedge clk); 
        
        // Wait for the completion of the reset routine
        while (~mcse.control_unit.secure_boot.reset_routine_done_r) begin
            @(posedge clk);
        end

        gpio_in[1] = 0;
        if (mcse.control_unit.secure_boot.gpio_reg_rdata[1]) begin
            $display("[MCSE] Host SoC reset ACK received...Host SoC reset routine completed");
        end 
        else begin
            $display("[MCSE] Host SoC reset ACK not received");
        end 
    endtask

     task recall_lifecycle_first_boot();
        $displayh("[MCSE] First boot flag value = ", mcse.control_unit.secure_boot.first_boot_flag_r);
        lifecycle_auth(lc_authentication_id_recall); 
        chipid_auth(); 
        if (mcse.control_unit.secure_boot.lifecycle_authentication_value_r && mcse.control_unit.secure_boot.authentic_chip_id_r) begin
            $display("[MCSE] Succesfully completed Lifecycle and Chip ID authentication...");
        end
        @(posedge clk); 
        $displayh("[MCSE] First boot flag value = ", mcse.control_unit.secure_boot.first_boot_flag_r);
        operation_release_handshake();
    endtask 

    task endoflife_lifecycle_first_boot();
        $displayh("[MCSE] First boot flag value = ", mcse.control_unit.secure_boot.first_boot_flag_r);
        lifecycle_auth(lc_authentication_id_endoflife);
    endtask 

    

    task testing_lifecycle_subsequent_boot(); 
        reset_handshake();
        testing_lifecycle_first_boot();

        // global reset to test subsquent boots
        rst_n = 0; 
        @(posedge clk);
        rst_n = 1; 
        @(posedge clk);
        reset_handshake(); 
        $displayh("[MCSE] First boot flag value = ", mcse.control_unit.secure_boot.first_boot_flag_r);
        lifecycle_transition_request(lc_transition_id_testing); 
        reset_handshake(); 
    endtask 

    task oem_lifecycle_subsequent_boot();
        $display("[MCSE] Initializing MCSE and sending Host SoC reset signal...");
        reset_handshake();

        oem_lifecycle_first_boot();

        // global reset to test subsquent boots
        rst_n = 0; 
        @(posedge clk);
        rst_n = 1; 
        @(posedge clk);
        $display("[MCSE] Initializing MCSE and sending Host SoC reset signal...");
        reset_handshake(); 
        $displayh("[MCSE] First boot flag value = ", mcse.control_unit.secure_boot.first_boot_flag_r);
        operation_release_handshake();
        scan_control();
        lifecycle_transition_request(lc_transition_id_oem);
        reset_handshake(); 
    endtask

    task deployment_lifecycle_subsequent_boot();
        $display("[MCSE] Initializing MCSE and sending Host SoC reset signal...");
        reset_handshake();
        deployment_lifecycle_first_boot();

        // global reset to test subsquent boots
        rst_n = 0; 
        @(posedge clk);
        rst_n = 1; 
        @(posedge clk);
        $display("[MCSE] Initializing MCSE and sending Host SoC reset signal...");
        reset_handshake();
        $displayh("[MCSE] First boot flag value = ", mcse.control_unit.secure_boot.first_boot_flag_r);
        operation_release_handshake();

       // lifecycle_transition_request(lc_transition_id_deployment);
        //reset_handshake(); 

    endtask 

     task recall_lifecycle_subsequent_boot();
        $display("[MCSE] Initializing MCSE and sending Host SoC reset signal...");
        reset_handshake();
        recall_lifecycle_first_boot();

        // global reset to test subsquent boots
        rst_n = 0; 
        @(posedge clk);
        rst_n = 1; 
        @(posedge clk);
        $display("[MCSE] Initializing MCSE and sending Host SoC reset signal...");
        reset_handshake();
        $displayh("[MCSE] First boot flag value = ", mcse.control_unit.secure_boot.first_boot_flag_r);
        operation_release_handshake();

        lifecycle_transition_request(lc_transition_id_recall);
        reset_handshake();
    endtask 

    task endoflife_lifecycle_subsequent_boot();
        $display("[MCSE] Initializing MCSE and sending Host SoC reset signal...");
        reset_handshake();
        endoflife_lifecycle_first_boot();


        // global reset to test subsquent boots
        rst_n = 0; 
        @(posedge clk);
        rst_n = 1; 
        @(posedge clk);
        $display("[MCSE] Initializing MCSE and sending Host SoC reset signal...");
        reset_handshake();
        $displayh("[MCSE] First boot flag value = ", mcse.control_unit.secure_boot.first_boot_flag_r);
 
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
         $display("[MCSE] Scan unlock status: %x",scan_unlock);

        
        // Enable scan for few clock cycles and stream scan_out
        $display("[TB_TOP] Enabling scan chain for few clock cycles to stream scan out");
        for (int i = 0; i < 5; i++) begin
            scan_enable = 1;
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

        $dumpfile("mcse.vcd");
        $dumpvars(0, mcse_top_tb);
       
        $display("[TB_TOP] Asserting global reset and initializing MCSE configuration");
        for (integer i = 0; i < 10; i=i+1) begin
            rst_n = 0;
            init_config_n =0; 
            gpio_in = 0; 
            I_hrdata = 0;
            I_hready = 1;
            I_hresp = 0;
            I_hreadyout = 1;
            @(posedge clk);
        end 
 

        key_temp = 512'h87A5E932FA1BC49DFF8A0B2C3D4E5F607891ABCDEF0123456789ABCDEF012345; // input challenge key for vimscan

        
        $display("[TB_TOP] Deasserting global reset and initial MCSE configuration");
        rst_n = 1;
        init_config_n = 1;


        @(posedge clk);
        @(posedge clk); 
        @(posedge clk); 
        $display("[MCSE] Initializing MCSE and sending Host SoC reset signal...");

        
        
        // Full Boot Flow

        reset_handshake();

        testing_lifecycle_first_boot(); 
        lifecycle_transition_request(lc_transition_id_testing);
        reset_handshake();

        
        oem_lifecycle_first_boot();
        scan_control();
        lifecycle_transition_request(lc_transition_id_oem);
        reset_handshake();

        deployment_lifecycle_first_boot();   
        lifecycle_transition_request(lc_transition_id_deployment);
        reset_handshake();

        recall_lifecycle_first_boot();
        lifecycle_transition_request(lc_transition_id_recall);
        reset_handshake();

        endoflife_lifecycle_first_boot();


    
        $finish; 
    end 

endmodule 