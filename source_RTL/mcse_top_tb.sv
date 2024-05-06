//`timescale 1 ns / 100 ps
`include "mcse_def.svh"
`define         AHB_TRANS_IDLE                      2'b00
`define         AHB_DATA_WIDTH_BITS                 32

module mcse_top_tb;


    localparam pcm_data_width = 32;
    localparam pcm_addr_width = 32;
    localparam puf_sig_length = 256;
    localparam gpio_N = 32;
    localparam gpio_AW = 32;
    localparam gpio_PW = 2*gpio_AW+40;
    localparam ipid_N = `IPID_N;
    localparam ipid_width = 256;
    localparam fw_image_N = 9;
    localparam fw_block_width = 256;

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

    localparam [pAHB_ADDR_WIDTH-1:0]  ipid_address [0:ipid_N-1] = `IPID_ADDR_MAP;


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
    logic  [255:0]        lc_transition_id;
    logic                 lc_transition_request_in;
    logic  [255:0]        lc_authentication_id;
    logic                 lc_authentication_valid;
  
    logic [gpio_N-1:0]   gpio_out;

    logic [15:0] ipid_array [255:0];

    logic                 fw_authentication_trigger;
    logic                 fw_auth_result;

    initial begin :generate_clock
        while (1)
            #5 clk = ~clk;
    end 

    mcse_top #(.pcm_data_width(pcm_data_width), .pcm_addr_width(pcm_addr_width), . puf_sig_length(puf_sig_length),
    .gpio_N(gpio_N), .gpio_AW(gpio_AW), .gpio_PW(gpio_PW), .ipid_N(ipid_N), .ipid_width(ipid_width) )
    mcse ( .* );

    int k = 0;

    
    
    task ipid_send();
        $display("[MCSE] Sending IP ID trigger..."); 
        while (gpio_out[12] != 1) begin // wait for first ip id trigger    
            @(posedge clk); 
        end

        k =0;
        gpio_in = 0; 
        for (logic [4:0] i = 0; i < ipid_N; i++) begin
            gpio_in[13] = 1;
            $displayh("[TB_TOP] IP ID trigger received...Sending IP ID from address ", gpio_out[11:8]); 
            for (int j = 0; j < 18; j++) begin
                if (j == 0) begin 
                    gpio_in[31:16] = 16'h7A7A;
                    $displayh("[TB_TOP] GPIO_IN[31:16] = ", gpio_in[31:16]);
                    @(posedge clk);
                    continue;
                end 
                else if (j == 17) begin
                    gpio_in[31:16] = 16'hB9B9;
                    $displayh("[TB_TOP] GPIO_IN[31:16] = ", gpio_in[31:16]);
                    @(posedge clk);
                    continue;
                end else begin 
                gpio_in[31:16] = ipid_array[k];
                //gpio_in[31:16] = $urandom_range(0,65536);
                k = k+1;
                $displayh("[TB_TOP] GPIO_IN[31:16] = ", gpio_in[31:16]);
                @(posedge clk); 
                end  
            end 

            //$display("[TB_TOP] Waiting for IP ID trigger deassert.."); 
            gpio_in[13] = 0; 
            while (gpio_out[12] != 0) begin
                @(posedge clk); 
            end 
            //$display("[TB_TOP] IP ID trigger deasserted");
      
            $displayh("[MCSE] IP ID ", i[3:0], " = " , mcse.control_unit.secure_boot.ipid_r[i]);
            if (i != ipid_N-1) begin 
                //$display("[TB_TOP] Waiting for IP ID trigger...");
                $display("[MCSE] Sending IP ID trigger...");
                while (gpio_out[12] != 1) begin
                    @(posedge clk); 
                end 
            end 
           
        end
    endtask

    task bus_wakeup_handshake();
        $display("[MCSE] Sending bus wakeup signal...");
        while (gpio_out[6] != 1) begin // bus wakeup
            @(posedge clk); 
        end 

        $display("[TB_TOP] Bus wakeup received...Sending bus wakeup ACK");
        gpio_in[7] = 1; // bus wakeup ack
        @(posedge clk); 
    endtask

    task chipid_generation(); 
        $display("[MCSE] Calculating MCSE ID..."); 
        while (~mcse.control_unit.secure_boot.mcse_id_done_r) begin
            @(posedge clk); 
        end 
        $displayh("[MCSE] MCSE ID generation complete, MCSE ID = ", mcse.control_unit.secure_boot.mcse_id_r); 
        $display("[MCSE] Proceeding with IP ID generation and bus wakeup handshake");
        bus_wakeup_handshake(); 
       
        //ipid_send();   
        ipid_bus_stream();
        $display("[MCSE] IP ID extraction complete...Generating Composite IP ID...");

        while (~mcse.control_unit.secure_boot.hash_done_r) begin
            @(posedge clk); 
        end 
        $displayh("[MCSE] Composite IP ID generation complete, Composite IP ID = ", mcse.control_unit.secure_boot.ipid_hash_r);
        //$display("[MCSE] IP ID extraction complete...Continuing with Chip ID generation");   
        $display("[MCSE] Generating Chip ID...");
        while (~mcse.control_unit.secure_boot.chip_id_generation_done_r) begin
            @(posedge clk); 
        end 
        $display("[MCSE] Chip ID generation complete");
        //$displayh("[MCSE] Generated MCSE ID = ", mcse.control_unit.secure_boot.mcse_id_r);
        //$displayh("[MCSE] Generated Composite IP ID = ", mcse.control_unit.secure_boot.ipid_hash_r);
        //$displayh("[MCSE] Generated Chip ID = " , mcse.control_unit.secure_boot.chip_id_r);
        
        @(posedge clk); 
   

    endtask

    task initialize_array();
        for (int i = 0; i < 256; i++) begin
            ipid_array[i] = $urandom_range(0,65536);
        end 
    endtask 

    task chipid_auth();
        chipid_generation(); 

        while (~mcse.control_unit.secure_boot.chip_id_challenge_done_r) begin
            @(posedge clk); 
        end
        
        $displayh("[MCSE] Golden Chip ID = ", mcse.control_unit.mem.ram[0]);
        $displayh("[MCSE] Generated Chip ID = " , mcse.control_unit.secure_boot.encryption_output_r);
        $displayh("[MCSE] Authentic Chip ID Value = ", mcse.control_unit.secure_boot.authentic_chip_id_r); 
    endtask

    task lifecycle_transition_request(input bit [255:0] id); 
        $display("[TB_TOP] Requesting a lifecycle transition..."); 
        $displayh("[TB_TOP] Lifecycle transition ID = ", id);
        $display("[MCSE] Servicing lifecycle transition request..."); 


        while (mcse.control_unit.secure_boot.lc_transition_request) begin
            $display("Stall until internal lc transition request signal is deasserted...");
            @(posedge clk); 
        end 

        lc_transition_request_in = 1;
        lc_transition_id = id; 

        while (mcse.control_unit.secure_boot.lc_transition_done_r==0) begin
            @(posedge clk);
        end
        lc_transition_request_in = 0;
        lc_transition_id = 0;
        $displayh("[MCSE] LC Transition Success Value = ", mcse.control_unit.secure_boot.lc_transition_success_r);
        if (mcse.control_unit.secure_boot.lc_transition_success_r) begin
            $display("[MCSE] Lifecycle transition successful");
        end 
        else begin
            $display("[MCSE] Lifecycle transition failed");
        end 
        // $displayh("[MCSE] Current Lifecycle State = ", mcse.control_unit.secure_boot.lc_state); 

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

    task lifecycle_auth(input bit [255:0] id);

        $display("[TB_TOP] Requesting LC Authentication...");   
        $displayh("[TB_TOP] LC Key = ", id);       

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

    logic [255:0] lc_transition_id_testing = 256'h33a344a35afd82155e5a6ef2d092085d704dc70561dde45d27962d79ea56a24a;
    logic [255:0] lc_authentication_id_oem = 256'h431909d9da263164ab4d39614e0c50a32774a49b3390a53ffa63e8d74b8e7c0b;
    logic [255:0] lc_transition_id_oem = 256'h988b6a57b75f5696f01b8207b1c99bc888b4a2421a0ab4b29bd302f5b8a93348; 
    logic [255:0] lc_authentication_id_deployment = 256'h8e30701845bea3e44d0aed1ba6d4893a0de91fea6f42571d3714a3c6daa39978;
    logic [255:0] lc_transition_id_deployment = 256'h4893565d146d9fa19dc850e0c409b2a62ec5cb53eea4d4719c93a882f988284e; 
    logic [255:0] lc_authentication_id_recall = 256'hd995f5ddfb1625e3a33b0ee123b6672f35df88d6652eaec51d26f3a50b030ad8;
    logic [255:0] lc_transition_id_recall = 256'hcabc36e4f52fcd1a8b62d82d975e4c8595da7f6df52e2143174c3dc8b3870e03; 
    logic [255:0] lc_authentication_id_endoflife = 256'hdf0f326b1bf6611d944491d7a0618af56ac57e391ba38425f9f33cafdd7439a9;

    task testing_lifecycle_first_boot();
        // $displayh("[MCSE] Current Lifecycle State = ", mcse.control_unit.secure_boot.lc_state); 
        $displayh("[MCSE] First boot flag value = ", mcse.control_unit.secure_boot.first_boot_flag_r);
        if (mcse.control_unit.secure_boot.first_boot_flag_r) begin
            $display("[MCSE] Proceeding with Chip ID generation...");
        end 
        
        chipid_generation(); 

        while ( ~mcse.control_unit.secure_boot.memory_write_done_r) begin
            // $displayh("[MCSE] chip_id_generation_done_r = ", mcse.control_unit.secure_boot.chip_id_generation_done_r);
            // $displayh("[MCSE] memory_read_done_r = ", mcse.control_unit.secure_boot.memory_read_done_r);
            // $displayh("[MCSE] rdData_valid = ", mcse.control_unit.secure_boot.rdData_valid);
            // $displayh("[MCSE] encryption_done_r = ", mcse.control_unit.secure_boot.encryption_done_r);
            @(posedge clk); 
        end 
        gpio_in = 0; 
        @(posedge clk); 
        $display("[MCSE] Encrypting Chip ID and storing into memory..."); 
        $displayh("[MCSE] Chip ID Stored in memory = ", mcse.control_unit.mem.ram[0]); 
        $display("[MCSE] Chip ID generation complete...");
        $displayh("[MCSE] First boot flag value = ", mcse.control_unit.secure_boot.first_boot_flag_r);
        
    endtask 

    task oem_lifecycle_first_boot();
        // $displayh("[MCSE] Current Lifecycle State = ", mcse.control_unit.secure_boot.lc_state); 
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

        //$displayh("Normal operation release pin, gpio_out[4] = ", gpio_out[4]);
        $display("[TB_TOP] Normal operation release trigger received...Sending host normal operation release ACK...");

        gpio_in[5] = 1; // host ack

        // Wait for the completion of the reset routine
        while (~mcse.control_unit.secure_boot.operation_release_done_r) begin
            @(posedge clk);
        end

        $display("[MCSE] Normal operation release ACK recieved...Normal operation release completed");
        //$displayh("Host ack proof, gpio_reg_rdata[5] = ", mcse.control_unit.secure_boot.gpio_reg_rdata[5]);

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
        //wait for reset request
        //$display("Waiting for reset request");
        while (gpio_out[0] != 1) begin // sending reset
            @(posedge clk); 
        end 
    
        //$displayh("Reset sending, gpio_out[0] = ", gpio_out[0]);
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
        // $displayh("[MCSE] Current lifecycle state = ", mcse.control_unit.secure_boot.lc_state); 
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
        // $displayh("[MCSE] Current Lifecycle State = ", mcse.control_unit.secure_boot.lc_state); 
        $displayh("[MCSE] First boot flag value = ", mcse.control_unit.secure_boot.first_boot_flag_r);
        lifecycle_auth(lc_authentication_id_endoflife);
    endtask 

    // task to show first boot at each lifecycle and transition between each 
    task full_bootflow();
        reset_handshake();
        testing_lifecycle_first_boot();
        lifecycle_transition_request(lc_transition_id_testing); 
        reset_handshake(); 
      
        // boot in OEM
        reset_handshake(); 
        oem_lifecycle_first_boot(); 
        operation_release_handshake();
        lifecycle_transition_request(lc_transition_id_oem);
        reset_handshake(); 
        // // boot in deployment
        reset_handshake();
        deployment_lifecycle_first_boot();
        operation_release_handshake();
        lifecycle_transition_request(lc_transition_id_deployment);
        reset_handshake(); 
        
        // // boot in recall
        reset_handshake(); 
        recall_lifecycle_first_boot();
        operation_release_handshake();
        lifecycle_transition_request(lc_transition_id_recall);
        reset_handshake(); 
        // // boot in end of life 
        reset_handshake();
        endoflife_lifecycle_first_boot(); 
    endtask 

    task testing_lifecycle_subsequent_boot(); 
        reset_handshake();
        testing_lifecycle_first_boot();

        // global reset to test subsquent boots
        // $display("[TB_TOP] Power cycling chip...");
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
        // $display("[TB_TOP] Power cycling chip...");
        rst_n = 0; 
        @(posedge clk);
        rst_n = 1; 
        @(posedge clk);
        $display("[MCSE] Initializing MCSE and sending Host SoC reset signal...");
        reset_handshake(); 
        $displayh("[MCSE] First boot flag value = ", mcse.control_unit.secure_boot.first_boot_flag_r);
        operation_release_handshake();

        lifecycle_transition_request(lc_transition_id_oem);
        reset_handshake(); 
    endtask

    task deployment_lifecycle_subsequent_boot();
        $display("[MCSE] Initializing MCSE and sending Host SoC reset signal...");
        reset_handshake();
        deployment_lifecycle_first_boot();

        // global reset to test subsquent boots
        // $display("[TB_TOP] Power cycling chip...");
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
        // $display("[TB_TOP] Power cycling chip...");
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
        // $display("[TB_TOP] Power cycling chip...");
        rst_n = 0; 
        @(posedge clk);
        rst_n = 1; 
        @(posedge clk);
        $display("[MCSE] Initializing MCSE and sending Host SoC reset signal...");
        reset_handshake();
        $displayh("[MCSE] First boot flag value = ", mcse.control_unit.secure_boot.first_boot_flag_r);
 
    endtask 

    logic [32:0] array_bus [(ipid_N * 8)-1:0]; 
    task initialize_array_bus();
        for (int i =0; i < ipid_N * (pPAYLOAD_SIZE_BITS / pAHB_DATA_WIDTH); i++) begin 
            array_bus[i] = $urandom_range(1,2147483647);
        end 
    endtask 

    task individual_ipid_stream(input bit [ipid_N-1:0] ipid_index);
        for (int i = 0; i < 8; i++) begin
           
            I_hrdata = array_bus[(ipid_index*(pPAYLOAD_SIZE_BITS / pAHB_DATA_WIDTH)) + i];
            $displayh("[TB_TOP] O_haddr = ", O_haddr, " and I_hrdata = ", I_hrdata); 
            @(posedge clk); 
        end 
    endtask 


    task ipid_bus_stream();  
        while (~mcse.control_unit.secure_boot.ipid_extraction_done_r) begin 
            //$displayh("pcm_puf_out_valid = ", mcse.control_unit.secure_boot.pcm_puf_out_valid);
            //$displayh("parity_bits = ", mcse.min_sec.pcm.parity_bits);
            for (bit [ipid_N-1:0] k = 0; k < ipid_N; k++) begin
                if (O_haddr == ipid_address[k] && O_htrans == 2'b10) begin
                    $displayh("[TB_TOP] Providing IPID values for address ", O_haddr); 
                    individual_ipid_stream(k); 
                end 
            end  
            @(posedge clk); 
        end 
        for (int i =0 ; i < ipid_N; i++) begin
            $displayh("[MCSE] IPID ",  i[3:0], " = ", mcse.control_unit.secure_boot.ipid_r[i]);
        end 
    endtask 
    

    localparam [pAHB_ADDR_WIDTH-1:0]   fw_address [0:8] = '{
    'h68D00000,
    'h72500001, 
    'hD5200001,
    'h34D00001,
    'h35D00002,
    'h36D00003,
    'h38D00004,
    'h37D00005,
    'h39D00006
     };

    logic [255:0] fw_image [fw_image_N-1:0];
    logic [31:0] fw_array_bus[(fw_image_N * 8)-1:0];
    task initialize_fw_array();
        for (int i=0; i < fw_image_N ; i++) begin
            for (int j = 0 ; j < fw_image_N-1 ; j++) begin
                // fw_array_bus[i*8 + j] = fw_image[i][j*32 +: 32];
                fw_array_bus[i*8 + j] = fw_image[i] >> (256 - (j+1) * 32);
            end
        end
    endtask 

    task fw_block_stream(input bit [fw_image_N-1:0] fw_index);
        for (int i = 0; i < 8; i++) begin
            I_hrdata = fw_array_bus[(fw_index*(pPAYLOAD_SIZE_BITS / pAHB_DATA_WIDTH)) + i];
            $displayh("[TB_TOP] O_haddr = ", O_haddr, " and I_hrdata = ", I_hrdata); 
            @(posedge clk); 
        end 
    endtask 

    task fw_image_stream();  
        // fw_authentication_trigger = 1;
        $display("[TB_TOP] Starting FW image extraction");
        while (~mcse.control_unit.fw_auth.fw_extraction_done_r) begin
            for (bit [fw_image_N-1:0] k = 0; k < fw_image_N; k++) begin
                if (O_haddr == fw_address[k] && O_htrans == 2'b10) begin
                    $displayh("[TB_TOP] Providing FW image values for address ", O_haddr); 
                    fw_block_stream(k); 
                end 
            end  
            @(posedge clk); 
        end 
        for (int i =0 ; i < fw_image_N; i++) begin
            $displayh("[MCSE] FW Block ",  i[3:0], " = ", mcse.control_unit.fw_auth.fw_r[i]);
        end 
    endtask 

    // task memory_check();
    //     while (~mcse.control_unit.fw_auth.memory_read_done_r) begin
    //         @(posedge clk);
    //     end
    // endtask 


    task fw_hash();
        $display("starting fw hash");
        while (~mcse.control_unit.fw_auth.hash_done_r) begin
            @(posedge clk);
        end
        // for (int i =0 ; i < 10; i++) begin
        //     $displayh("fw for hmac ", i[3:0], " = ", mcse.control_unit.fw_auth.fw_for_hmac[i]);
        // end
        // $displayh("sha digest = ", mcse.control_unit.fw_auth.sha_digest);
    endtask 

    task fw_auth();
        // fw_authentication_trigger = 1;
        while (~mcse.control_unit.fw_auth.fw_authentication_done_r) begin 
            @(posedge clk);
        end

        if (mcse.control_unit.fw_auth.fw_authentication_value_next) begin
            $display("[MCSE] FW is authentic");
        end
        else begin
            $display("[MCSE] FW is not authentic");
        end
        // fw_authentication_trigger = 0;
    endtask 

    task fw_signature_authentication_request();
    
        gpio_in[14] = 1;       
        initialize_fw_array();
        
        // for (int i = 0; i < 72; i = i + 1) begin
        //     $display("fw_array_bus[%0d] = 0x%0h", i, fw_array_bus[i]);
        // end

        fw_image_stream();
        
        // $displayh("signature challenge = ", mcse.control_unit.fw_auth.signature_challenge);

        // memory_check();

        // fw_hash();
        fw_auth();
        gpio_in[14] = 0;
        
        
        // while (~gpio_out[15] || ~gpio_out[16]) begin
        //     @(posedge clk);
        // end 

        gpio_in[17] = 1;

        while (mcse.control_unit.secure_boot.fw_update_counter_r != 2) begin
            @(posedge clk);
        end

        if (gpio_out[15]) begin
            // $displayh("gpio_out[15] =", gpio_out[15]);
            $display("[MCSE] FW signature authentication successful...Sending FW upgrade ACK");
            end
        else if (gpio_out[16]) begin
            // $displayh("gpio_out[16] =", gpio_out[16]);
            $display("[MCSE] FW signature authentication failed...Sending failure message");
        end
        $display("[MCSE] Waiting for TA2 acknowledgement");


        while (~mcse.control_unit.secure_boot.gpio_reg_rdata[17]) begin
            @(posedge clk); 
        end 
        $display("[MCSE] Received TA2 acknowledgement");

    endtask

    initial begin : drive_inputs

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

        fw_image = {  256'h3F8D42ABE9A7E09DAB743FA1F3E67839CA1FC4F22BC526CCFF9E2F74B3447561,
                      256'h79050A0F7F87BEBD3D253A83C9F3E205BCBB8A76FA7DF79BB345F859366B2D9E, 
                      256'h6A195890AE4F30F88F7A6730578C209F2C7CE3F12A5EEDBFCE0657BDB8F140D5, 
                      256'h1F20967289AEBDB7F9564B96C3B9D6FED4E328EC10EBB2D20C21CB1776A934D9, 
                      256'h4053D28E9563E5A87498B056D078A9D8B02F4D43CC26D0A8A6740A3842F34571, 
                      256'h2B8FD78103B1C8919AF80FDB2E14A1BC61FD8E4004902F90C6A5F0C4BB6A13D2, 
                      256'h45C575D8C76D92BCF4DC0B8F73AC6D65F78EF13D7BDF23903C8C6A77AB7BCDDA, 
                      256'h7E694B750F0CBFC7842E92F45DE89E5BDC9D105037A5903C4C4F2B4B0C2DD1E7, 
                      256'hb753e040b6807fa87701830ed2dca2235b8269a964a2add39c1e28b39f041820};

        initialize_array();
        initialize_array_bus();
        $display("[TB_TOP] Deasserting global reset and initial MCSE configuration");
        rst_n = 1;
        init_config_n = 1;




        @(posedge clk);
        @(posedge clk); 
        @(posedge clk); 
        $display("[MCSE] Initializing MCSE and sending Host SoC reset signal...");
        //full_bootflow(); 
        testing_lifecycle_subsequent_boot();
        oem_lifecycle_subsequent_boot();
        deployment_lifecycle_first_boot();

        fw_signature_authentication_request();    

        lifecycle_transition_request(lc_transition_id_deployment);
        reset_handshake();
        // recall_lifecycle_first_boot();

        // fw_signature_authentication_request();

        // lifecycle_transition_request(lc_transition_id_recall);
        // reset_handshake();

        // endoflife_lifecycle_first_boot();
       // recall_lifecycle_subsequent_boot();
        //endoflife_lifecycle_subsequent_boot();
        // ipid_bus_stream();  
        // for (int i =0 ; i < ipid_N; i++) begin
        //     $displayh("[MCSE] IPID ",  i[3:0], " = ", mcse.control_unit.secure_boot.ipid_r[i]);
        // end 
        $finish; 
    end 

endmodule 