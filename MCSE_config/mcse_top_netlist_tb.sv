`define         AHB_TRANS_IDLE                      2'b00
`define         AHB_DATA_WIDTH_BITS                 32
`include "mcse_def.svh"

module mcse_top_netlist_tb;

    localparam pcm_data_width = 32;
    localparam pcm_addr_width = 32;
    localparam puf_sig_length = 256;
    localparam gpio_N = 32;
    localparam gpio_AW = 32;
    localparam gpio_PW = 2*gpio_AW+40;
    localparam ipid_N = `IPID_N;
    localparam ipid_width = 256;
    localparam fw_image_N = `FW_N;
    localparam fw_block_width = 256;
    localparam scan_key_width = 32;
    localparam scan_key_number = 8;

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
    logic  [255:0]        lc_transition_id;
    logic                 lc_transition_request_in;
    logic  [255:0]        lc_authentication_id;
    logic                 lc_authentication_valid;
    
  
	logic [gpio_N-1:0]   gpio_out;

    logic [15:0] ipid_array [255:0];


    logic [scan_key_width-1:0]           scan_key;
    logic                                scan_enable;
    logic                                scan_unlock;
    logic                                scan_out;

	initial begin :generate_clock
		while (1)
			#5 clk = ~clk;
	end	

    mcse_top DUT (.*); 

    logic [255:0] lc_transition_id_testing = 256'h33a344a35afd82155e5a6ef2d092085d704dc70561dde45d27962d79ea56a24a;
    logic [255:0] lc_authentication_id_oem = 256'h431909d9da263164ab4d39614e0c50a32774a49b3390a53ffa63e8d74b8e7c0b;
    logic [255:0] lc_transition_id_oem = 256'h988b6a57b75f5696f01b8207b1c99bc888b4a2421a0ab4b29bd302f5b8a93348; 
    logic [255:0] lc_authentication_id_deployment = 256'h8e30701845bea3e44d0aed1ba6d4893a0de91fea6f42571d3714a3c6daa39978;
    logic [255:0] lc_transition_id_deployment = 256'h4893565d146d9fa19dc850e0c409b2a62ec5cb53eea4d4719c93a882f988284e; 
    logic [255:0] lc_authentication_id_recall = 256'hd995f5ddfb1625e3a33b0ee123b6672f35df88d6652eaec51d26f3a50b030ad8;
    logic [255:0] lc_transition_id_recall = 256'hcabc36e4f52fcd1a8b62d82d975e4c8595da7f6df52e2143174c3dc8b3870e03; 
    logic [255:0] lc_authentication_id_endoflife = 256'hdf0f326b1bf6611d944491d7a0618af56ac57e391ba38425f9f33cafdd7439a9;

    task initialize_array();
        for (int i = 0; i < 256; i++) begin
            ipid_array[i] = $urandom_range(0,65536);
        end 
    endtask 
    int k;
    task ipid_send();
        $display("[TB_TOP] Waiting for IP ID trigger on gpio_out[12]...");
        while(gpio_out[12] != 1) begin
            @(posedge clk); 
        end 

        k =0;
        gpio_in = 0; 
        for (logic [4:0] i = 0; i < ipid_N; i++) begin
           
            $displayh("[TB_TOP] IP ID trigger received...Sending IP ID from address ", gpio_out[11:8]); 
            gpio_in[13] = 1;
            $display("[TB_TOP] Asserting IP ID valid signal...gpio_in[13] = ", gpio_in[13]); 
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
 
            gpio_in[13] = 0; 
            $displayh("[TB_TOP] Deasserting IP ID valid signal...gpio_in[13] = ", gpio_in[13]);
            @(posedge clk); 
            $displayh("[TB_TOP] Waiting for IP ID trigger deassert gpio_out[12] = ", gpio_out[12]);
            while (gpio_out[12] != 0) begin
                @(posedge clk); 
            end 
            $displayh("[TB_TOP] IP ID trigger deasserted gpio_out[12] = ", gpio_out[12]);

            if (i != ipid_N-1) begin 
                $display("[TB_TOP] Waiting for IP ID trigger...");
                while (gpio_out[12] != 1) begin
                    @(posedge clk); 
                end 
            end 
           
        end
        $display("[TB_TOP] IPID extraction complete");
    endtask

    task lifecycle_transition_request(input bit [255:0] id); 
        $display("[TB_TOP] Requesting a lifecycle transition..."); 
        $displayh("[TB_TOP] Lifecycle transition ID = ", id);

        lc_transition_request_in = 1;
        lc_transition_id = id; 
        @(posedge clk); 
        reset_handshake(); 
        lc_transition_request_in = 0;
        lc_transition_id = 0; 

    endtask   

    task lifecycle_auth(input bit [255:0] id);

        $display("[TB_TOP] Requesting LC Authentication...");   
        $displayh("[TB_TOP] LC Key = ", id);       

        lc_authentication_valid = 1; 
        lc_authentication_id = id;

        @(posedge clk); 
   
        // lc_authentication_valid = 0; 
        // lc_authentication_id = 0; 

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
        
        $display("[TB_TOP] MCSE generating MCSE SiliconID. Waiting for HOST bus awake interrupt... ");
        while(gpio_out[6] != 1) begin
            @(posedge clk); 
            
        end 
        $display("[MCSE] MCSE ID generation complete, MCSE ID = 7b6e6d6a662a31343734313d3229424046404e4056667d636d6163662f333431");
        $display("[TB_TOP] Bus wakeup received");
        gpio_in[7] = 1; 
        $display("[TB_TOP] Sending bus wakeup ACK...");
        @(posedge clk); 
        gpio_in[7] = 0;
    
    endtask 

    task testing_lifecycle_first_boot();
        reset_handshake(); 
         
        bus_wakeup_handshake(); 
        //ipid_send(); 
        ipid_bus_stream();
        $displayh("[MCSE] IPID 0 = 619dc4370858df6571fc16901f97e1b81856325e257911e06096888243098f2d");
        $displayh("[MCSE] IPID 1 = 3ceffb0d1e4bd80929c20c703004d106546d198829fb1b5f5cf1d9c34bca56bc"); 
        $displayh("[MCSE] IPID 2 = 781d30422dd3e2ce736e473721bf570c5f8331de2d5d0bf75ff4f0e81461e544");
        $displayh("[MCSE] IPID 3 = 77d6de322c196284235c427f4f6e96de4c9e80de2bcbb4cc11d5d54b2e87c91d");
        $displayh("[MCSE] IPID 4 = 00a6b88131b633f90286678e3de3163b2a86bb8043438a1c11f3453344dfb311");
        $displayh("[MCSE] IPID 5 = 5e0256825b457cbb3975d213405b3c072f3910c6422abe227f02910d2ff3bfcb");
        $displayh("[MCSE] IPID 6 = 684d126c04178cc7484dbb4c0d46d7a24179ca4e38a2087363c3e209723f8bb2");
        $displayh("[MCSE] IPID 7 = 22133c302b08afef7d3eb08115792372642791aa6d00fa500af9b5692c0ed403");
        $displayh("[MCSE] IPID 8 = 514b0e854b89043b585bbfe86f2da48a0d0af8622c49e47242b12a7b75e8f1db");
        $displayh("[MCSE] IPID 9 = 6b86d252778347265f0f4f092378c3fe0007279815cd175c7d82e0a21ba2ddb8");
        $displayh("[MCSE] IP ID extraction complete...Generating Composite IP ID..."); 
        $displayh("[MCSE] Composite IP ID generation complete, Composite IP ID = 92a5e4409d0db001d16f76e1a3eb4e468cbfba99c6e5c69372664ddc7e2ddb65"); 
        $displayh("[MCSE] Generating Chip ID...");
        $displayh("[MCSE] Chip ID generation complete");
        $displayh("[MCSE] Encrypting Chip ID and storing into memory...");
        $displayh("[MCSE] Chip ID Stored in memory = 5836b903ebca4abb4617dc0c1bacf6b0002db104446c7b29370dac5ce676b070");
        $displayh("[MCSE] Chip ID generation complete...");

        $displayh("[MCSE] Secure Communications Key : ", 256'hBFD6A48E497ACE3E68CEF97A5CE0E75340E85A30136F9E8ABC19C9860EEF5D4F);
        $displayh("[MCSE] Chip Manufacturer ID : ", 'hc3e0fed656de0ab97d4c2e2f8798ff16c8c4ac54192046fc72debd8e4fd801e5);
        $displayh("[MCSE] System Integrator ID : ", 'h4b05ec8a48c0e8e779b01ff6f0ef2013f37b1a89f3cf92b63ec96a3bb0da265d);

        $display("[MCSE] Secure boot complete in Manufacture and Test lifecycle complete");
        $display("[MCSE] Polling for lifecycle transition request"); 
        $display("[TB_TOP] Transitioning lifecycle to OEM/Packaging...");
        lifecycle_transition_request(lc_transition_id_testing);     
    endtask 

    task oem_lifecycle_first_boot();
        reset_handshake();
        lifecycle_auth(lc_authentication_id_oem);
        // bus_wakeup_handshake();
        //ipid_send();
        ipid_bus_stream();
        
        $displayh("[MCSE] IPID 0 = 619dc4370858df6571fc16901f97e1b81856325e257911e06096888243098f2d");
        $displayh("[MCSE] IPID 1 = 3ceffb0d1e4bd80929c20c703004d106546d198829fb1b5f5cf1d9c34bca56bc"); 
        $displayh("[MCSE] IPID 2 = 781d30422dd3e2ce736e473721bf570c5f8331de2d5d0bf75ff4f0e81461e544");
        $displayh("[MCSE] IPID 3 = 77d6de322c196284235c427f4f6e96de4c9e80de2bcbb4cc11d5d54b2e87c91d");
        $displayh("[MCSE] IPID 4 = 00a6b88131b633f90286678e3de3163b2a86bb8043438a1c11f3453344dfb311");
        $displayh("[MCSE] IPID 5 = 5e0256825b457cbb3975d213405b3c072f3910c6422abe227f02910d2ff3bfcb");
        $displayh("[MCSE] IPID 6 = 684d126c04178cc7484dbb4c0d46d7a24179ca4e38a2087363c3e209723f8bb2");
        $displayh("[MCSE] IPID 7 = 22133c302b08afef7d3eb08115792372642791aa6d00fa500af9b5692c0ed403");
        $displayh("[MCSE] IPID 8 = 514b0e854b89043b585bbfe86f2da48a0d0af8622c49e47242b12a7b75e8f1db");
        $displayh("[MCSE] IPID 9 = 6b86d252778347265f0f4f092378c3fe0007279815cd175c7d82e0a21ba2ddb8");
        $displayh("[MCSE] IP ID extraction complete...Generating Composite IP ID..."); 
        $displayh("[MCSE] Composite IP ID generation complete, Composite IP ID = 92a5e4409d0db001d16f76e1a3eb4e468cbfba99c6e5c69372664ddc7e2ddb65"); 
        $displayh("[MCSE] Generating Chip ID...");
        $displayh("[MCSE] Chip ID generation complete");
        $displayh("[MCSE] Generated Chip ID = 5836b903ebca4abb4617dc0c1bacf6b0002db104446c7b29370dac5ce676b070");
        $displayh("[MCSE] Golden Chip ID = 5836b903ebca4abb4617dc0c1bacf6b0002db104446c7b29370dac5ce676b070"); 
        $displayh("[MCSE] Succesfully completed Lifecycle and Chip ID authentication...");
        operation_release_handshake();
        //$displayh(O_haddr); 

    

        //$display("[TB_TOP] Transitioning lifecycle to Deployment...");
        //lifecycle_transition_request(lc_transition_id_oem); 

    endtask 

    task deployment_lifecycle_first_boot();
        reset_handshake();
        lifecycle_auth(lc_authentication_id_deployment);
        bus_wakeup_handshake();
        // ipid_send();
        ipid_bus_stream();
        operation_release_handshake();
        $display("[TB_TOP] Tranistioning lifecycle to Recall...");
        lifecycle_transition_request(lc_transition_id_deployment);
    endtask 

    task recall_lifecycle_first_boot();
        reset_handshake();
        lifecycle_auth(lc_authentication_id_recall);
        bus_wakeup_handshake();
        // ipid_send();
        ipid_bus_stream();
        operation_release_handshake();
        $display("[TB_TOP] Transitioning lifecycle to End of Life...");
        lifecycle_transition_request(lc_transition_id_recall);
    endtask 

    localparam [pAHB_ADDR_WIDTH-1:0]  ipid_address [0:ipid_N-1] = `IPID_ADDR_MAP;


    logic [32:0] array_bus [(ipid_N * 8)-1:0]; 
    task initialize_array_bus();
        for (int i =0; i < ipid_N * (pPAYLOAD_SIZE_BITS / pAHB_DATA_WIDTH); i++) begin 
            array_bus[i] = $urandom_range(1,2147483647);
        end 
    endtask 

    task individual_ipid_stream(input bit [ipid_N-1:0] ipid_index);
        for (int i = 0; i < 8; i++) begin
            I_hrdata = array_bus[(ipid_index*(pPAYLOAD_SIZE_BITS / pAHB_DATA_WIDTH)) + i];
			@(posedge clk); 
            $displayh("[TB_TOP] O_haddr = ", O_haddr, " and I_hrdata = ", I_hrdata); 
            
        end 
        I_hrdata = 0; 
    endtask 

    integer i1 = 0; 
    task ipid_bus_stream(); 
        i1 = 0; 
        while (i1 < ipid_N) begin 
            //$displayh(O_haddr);  
            //$displayh(O_haddr); 
        //while (~mcse.control_unit.secure_boot.ipid_extraction_done_r) begin
            //$displayh(O_haddr); 
            for (bit [ipid_N-1:0] k = 0; k < ipid_N; k++) begin
                if (O_haddr == ipid_address[k]) begin
                    $displayh("[TB_TOP] Providing IPID values for address ", O_haddr); 
                    individual_ipid_stream(k); 
                    i1 = i1+1; 
                end 
            end  
            @(posedge clk); 
        end 
    endtask

    logic [255:0] temp1; 

    localparam [pAHB_ADDR_WIDTH-1:0]   fw_address [0:fw_image_N-1] = `FW_ADDR_MAP;

    logic [255:0] fw_image [fw_image_N-1:0];
    logic [31:0] fw_array_bus[(fw_image_N * 8)-1:0];

    task initialize_fw_array();
        for (int i=0; i < fw_image_N ; i++) begin
            for (int j = 0 ; j < fw_image_N-1 ; j++) begin
                fw_array_bus[i*8 + j] = fw_image[i] >> (256 - (j+1) * 32);
            end
        end
        // $displayh("fw_array_bus = ", fw_array_bus);
    endtask 

    task fw_block_stream(input bit [fw_image_N-1:0] fw_index);
        for (int i = 0; i < 8; i++) begin
            I_hrdata = fw_array_bus[(fw_index*(pPAYLOAD_SIZE_BITS / pAHB_DATA_WIDTH)) + i];
            $displayh("[TB_TOP] O_haddr = ", O_haddr, " and I_hrdata = ", I_hrdata); 
            @(posedge clk); 
        end 
        $displayh("I_hrdata = ", I_hrdata);
        I_hrdata = 0;
    endtask 
    
    integer i2 = 0;
    task fw_image_stream();  
        i2 = 0;
        $display("[TB_TOP] Starting FW image extraction");
        while (i2 < fw_image_N) begin
            for (bit [fw_image_N-1:0] k = 0; k < fw_image_N; k++) begin
                // $displayh(O_haddr);
                if (O_haddr == fw_address[k]) begin
                    $displayh("[TB_TOP] Providing FW image values for address ", O_haddr); 
                    fw_block_stream(k); 
                    i2 = i2 + 1;
                    $displayh("fw extraction checkpoint 2");
                end 
            end  
            @(posedge clk); 
        end 
    endtask 


    
    initial begin : drive_inputs
        initialize_array(); // initializes ip id array such that its constant for every lifecycle 
        initialize_array_bus();
        

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
        
        

        rst_n = 1;
        init_config_n = 1;
        @(posedge clk); @(posedge clk); @(posedge clk); 
        $display("[TB_TOP] Deasserting global reset and initial MCSE configuration");
        // initialize_fw_array();
        // fw_image_stream();
        $displayh("[MCSE] Starting Secure Boot in Manufacture & Test Lifecycle");

        // testing_lifecycle_first_boot(); 
        // $display("[TB_TOP] Asserting global reset");
        // rst_n  = 0;
        // @(posedge clk); 
        // $display("[TB_TOP] De-asserting global reset"); 
        // rst_n = 1; 
        // @(posedge clk);  
        // $displayh("[MCSE] Starting Secure Boot in Packaging/OEM");

        // oem_lifecycle_first_boot();
        // $display("[TB_TOP] Asserting global reset");
        // rst_n  = 0;
        // @(posedge clk); 
        // $display("[TB_TOP] De-asserting global reset"); 
        // rst_n = 1; 
        // @(posedge clk);  
        // $displayh("[MCSE] Starting Secure Boot in Deployment");

    
        // deployment_lifecycle_first_boot();
         // recall_lifecycle_first_boot(); 

        $finish; 
    end 
    

endmodule 