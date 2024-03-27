module mcse_top_netlist_tb;

    localparam pcm_data_width = 32;
    localparam pcm_addr_width = 32;
    localparam puf_sig_length = 256;
    localparam gpio_N = 32;
    localparam gpio_AW = 32;
    localparam gpio_PW = 2*gpio_AW+40;
    localparam ipid_N = 3;
    localparam ipid_width = 256;

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
        $display("[TB_TOP] Waiting for operation release trigger on gpio_out[4]");
        while (gpio_out[4] != 1) begin // sending reset
            @(posedge clk); 
        end 
        $display("[TB_TOP] Normal operation release received...gpio_out[4] = ", gpio_out[4]);
        gpio_in[5] = 1; // host ack
        $display("[TB_TOP] Sending host normal operation release ACK...");
        @(posedge clk);


    endtask

    task reset_handshake(); 
        $display("[TB_TOP] Waiting for Host Soc reset request on gpio_out[0]...");
        while (gpio_out[0] != 1) begin
            @(posedge clk);
        end 
        
        $displayh("[TB_TOP] Host Soc reset request received...gpio_out[0] = ", gpio_out[0]);
        gpio_in[1] = 1;
        $display("[TB_TOP] Sending host SoC reset ACK...gpio_out[1] = ", gpio_in[1]);
        @(posedge clk);
        gpio_in[0] = 0; 
    endtask 

    task bus_wakeup_handshake();
        $display("[TB_TOP] Waiting for bus wakeup signal on gpio_out[6]...");
        while(gpio_out[6] != 1) begin
            @(posedge clk); 
        end 
        $display("[TB_TOP] Bus wakeup received...gpio_out[6] = ", gpio_out[6]);
        gpio_in[7] = 1; 
        $display("[TB_TOP] Sending bus wakeup ACK...gpio_in[7] = ", gpio_in[7]);
        @(posedge clk); 
        gpio_in[7] = 0;
    
    endtask 

    task testing_lifecycle_first_boot();
        reset_handshake(); 
        bus_wakeup_handshake(); 
        ipid_send(); 
        $display("[TB_TOP] Transitioning lifecycle to OEM/Packaging...");
        lifecycle_transition_request(lc_transition_id_testing);     
    endtask 

    task oem_lifecycle_first_boot();
        reset_handshake();
        lifecycle_auth(lc_authentication_id_oem);
        bus_wakeup_handshake();
        ipid_send();
        operation_release_handshake();
        $display("[TB_TOP] Transitioning lifecycle to Deployment...");
        lifecycle_transition_request(lc_transition_id_oem); 

    endtask 

    task deployment_lifecycle_first_boot();
        reset_handshake();
        lifecycle_auth(lc_authentication_id_deployment);
        bus_wakeup_handshake();
        ipid_send();
        operation_release_handshake();
        $display("[TB_TOP] Tranistioning lifecycle to Recall...");
        lifecycle_transition_request(lc_transition_id_deployment);
    endtask 

    task recall_lifecycle_first_boot();
        reset_handshake();
        lifecycle_auth(lc_authentication_id_recall);
        bus_wakeup_handshake();
        ipid_send();
        operation_release_handshake();
        $display("[TB_TOP] Transitioning lifecycle to End of Life...");
        lifecycle_transition_request(lc_transition_id_recall);
    endtask 

    initial begin : drive_inputs
        initialize_array(); // initializes ip id array such that its constant for every lifecycle 

        $display("[TB_TOP] Asserting global reset and initializing MCSE configuration");
        for (integer i = 0; i < 10; i=i+1) begin
            rst_n = 0;
            init_config_n =0; 
            gpio_in = 0; 
            @(posedge clk);
        end 

        rst_n = 1;
        init_config_n = 1;
        @(posedge clk); @(posedge clk); @(posedge clk); 
        $display("[TB_TOP] Deasserting global reset and initial MCSE configuration");

        testing_lifecycle_first_boot(); 
        oem_lifecycle_first_boot(); 
        deployment_lifecycle_first_boot();
        recall_lifecycle_first_boot(); 

        $finish; 
    end 
    

endmodule 