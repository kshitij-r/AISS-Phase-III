//`timescale 1 ns / 100 ps
module mcse_top_tb;


    localparam pcm_data_width = 32;
    localparam pcm_addr_width = 32;
    localparam puf_sig_length = 256;
    localparam gpio_N = 32;
    localparam gpio_AW = 32;
    localparam gpio_PW = 2*gpio_AW+40;

    logic                 clk=0;
    logic                 rst;
    logic                 fuse; 
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

    mcse_top #(.pcm_data_width(pcm_data_width), .pcm_addr_width(pcm_addr_width), . puf_sig_length(puf_sig_length),
    .gpio_N(gpio_N), .gpio_AW(gpio_AW), .gpio_PW(gpio_PW) )mcse ( .* );

    int k = 0;
    
    task ipid_send();
        k =0;
        for (logic [4:0] i = 0; i < 16; i++) begin
            gpio_in[13] = 1;
            $displayh("[TB_TOP] IP ID Trigger received...Sending IP ID from address ", gpio_out[11:8]); 
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

            $display("[TB_TOP] Waiting for IP ID trigger deassert.."); 
            gpio_in[13] = 0; 
            while (gpio_out[12] != 0) begin
                @(posedge clk); 
            end 
            $display("[TB_TOP] IP ID trigger deasserted");
      
            //$displayh("[MCSE] Internal IP ID = " , mcse.control_unit.secure_boot.ipid_r[i]);
            $displayh("[MCSE] Internal IP ID ", i[3:0], " = " , mcse.control_unit.secure_boot.ipid_r[i]);
            if (i != 15) begin 
                $display("[TB_TOP] Waiting for IP ID trigger...");
                while (gpio_out[12] != 1) begin
                    @(posedge clk); 
                end 
            end 

        end
    endtask

    task bus_wakeup_handshake();
        $display("[TB_TOP] Waiting for bus wakeup");
        while (gpio_out[6] != 1) begin // bus wakeup
            @(posedge clk); 
        end 

        $display("[TB_TOP] Bus wakeup received...Sending bus wakeup ACK");
        gpio_in[7] = 1; // bus wakeup ack
        @(posedge clk); 
    endtask

    task chipid_generation(); 
        bus_wakeup_handshake(); 
        $display("[TB_TOP] Waiting for IP ID Trigger");
        while (gpio_out[12] != 1) begin // wait for first ip id trigger    
            @(posedge clk); 
        end
       
        ipid_send();   
        $display("[MCSE] IP ID extraction complete...Continuing with Chip ID generation");   

        while (~mcse.control_unit.secure_boot.chip_id_generation_done_r) begin
            @(posedge clk); 
        end 
        $displayh("[MCSE] Internal generated Chip ID = " , mcse.control_unit.secure_boot.chip_id_r);
        $displayh("[MCSE] Encrypting generated Chip ID and storing in memory...");

        while ( ~mcse.control_unit.secure_boot.memory_write_done_r) begin
            @(posedge clk); 
        end 
        @(posedge clk); 
        $displayh("[MCSE] Chip ID Stored in memory = ", mcse.control_unit.mem.ram[0]); 

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
        
        $displayh("[MCSE] Internal MCSE ID = ", mcse.control_unit.secure_boot.mcse_id_r);
        $displayh("[MCSE] Internal Composite IP ID = ", mcse.control_unit.secure_boot.ipid_hash_r);
        $displayh("[MCSE] Internal Golden Chip ID = ", mcse.control_unit.mem.ram[0]);
        $displayh("[MCSE] Internal Generated Chip ID = " , mcse.control_unit.secure_boot.chip_id_r);
        $displayh("[MCSE] Internal Authentic Chip ID Value = ", mcse.control_unit.secure_boot.authentic_chip_id_r); 
    endtask

    task lifecycle_transition_request(input bit [255:0] id); 
        $display("[TB_TOP] Requesting a lifecycle transition..."); 
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
        $displayh("[MCSE] Internal LC Transition Success Value = ", mcse.control_unit.secure_boot.lc_transition_success_r);
        if (mcse.control_unit.secure_boot.lc_transition_success_r) begin
            $display("[MCSE] Lifecycle transition successful");
        end 
        else begin
            $display("[MCSE] Lifecycle transition failed");
        end 
        $displayh("[MCSE] Current Lifecycle State = ", mcse.control_unit.secure_boot.lc_state); 

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
        
        while (mcse.control_unit.secure_boot.lifecycle_authentication_done_r) begin
            @(posedge clk); 
        end 

        lc_authentication_valid = 0; 

        $display("[MCSE] Lifecycle Authentication Complete"); 
        $displayh("[MCSE] Internal Lifecycle Authentication Value = ", mcse.control_unit.secure_boot.lifecycle_authentication_value_r);
        if (mcse.control_unit.secure_boot.lifecycle_authentication_value_r) begin
            $display("[MCSE] Lifecycle authentication successful");
        end
        else begin
            $display("[MCSE] Lifecycle authentication failed");
        end 
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
        $displayh("[MCSE] Current Lifecycle State = ", mcse.control_unit.secure_boot.lc_state); 
        $displayh("[MCSE] First boot flag value = ", mcse.control_unit.secure_boot.first_boot_flag_r);
        if (mcse.control_unit.secure_boot.first_boot_flag_r) begin
            $display("[MCSE] Proceeding with secure boot...");
        end 
        
        chipid_generation(); 

        $displayh("[MCSE] First boot flag value = ", mcse.control_unit.secure_boot.first_boot_flag_r);
        $display("[MCSE] Chip ID generation complete...");
    endtask 

    task oem_lifecycle_first_boot();
        $displayh("[MCSE] Current Lifecycle State = ", mcse.control_unit.secure_boot.lc_state); 
        $displayh("[MCSE] First boot flag value = ", mcse.control_unit.secure_boot.first_boot_flag_r);
        lifecycle_auth(lc_authentication_id_oem); 
        chipid_auth(); 
        if (mcse.control_unit.secure_boot.lifecycle_authentication_value_r && mcse.control_unit.secure_boot.authentic_chip_id_r) begin
            $display("[MCSE] Succesfully completed Lifecycle and Chip ID authentication...");
        end
        @(posedge clk); 
        $displayh("[MCSE] First boot flag value = ", mcse.control_unit.secure_boot.first_boot_flag_r);
    endtask 

    task operation_release_handshake();
        //$display("Waiting for operation release trigger");
        while (gpio_out[4] != 1) begin // sending reset
            @(posedge clk); 
        end 

        //$displayh("Normal operation release pin, gpio_out[4] = ", gpio_out[4]);
        $display("[TB_TOP] Normal operation release trigger received...Sending host ACK");

        gpio_in[5] = 1; // host ack
        @(posedge clk); 

        // Wait for the completion of the reset routine
        while (~mcse.control_unit.secure_boot.operation_release_done_r) begin
            @(posedge clk);
        end

        $display("[MCSE] Normal operation release completed");
        //$displayh("Host ack proof, gpio_reg_rdata[5] = ", mcse.control_unit.secure_boot.gpio_reg_rdata[5]);

    endtask

    task deployment_lifecycle_first_boot();
        $displayh("[MCSE] Current Lifecycle State = ", mcse.control_unit.secure_boot.lc_state); 
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
        $display("[MCSE] Reset routine completed");
        //$displayh("Reset ack proof, gpio_reg_rdata[1] = ", mcse.control_unit.secure_boot.gpio_reg_rdata[1]);

    endtask

    task recall_lifecycle_first_boot();
        $displayh("[MCSE] Current Lifecycle State = ", mcse.control_unit.secure_boot.lc_state); 
        $displayh("[MCSE] First boot flag value = ", mcse.control_unit.secure_boot.first_boot_flag_r);
        lifecycle_auth(lc_authentication_id_recall); 
        chipid_auth(); 
        if (mcse.control_unit.secure_boot.lifecycle_authentication_value_r && mcse.control_unit.secure_boot.authentic_chip_id_r) begin
            $display("[MCSE] Succesfully completed Lifecycle and Chip ID authentication...");
        end
        @(posedge clk); 
        $displayh("[MCSE] First boot flag value = ", mcse.control_unit.secure_boot.first_boot_flag_r);
    endtask 

    task endoflife_lifecycle_boot();
        $displayh("[MCSE] Current Lifecycle State = ", mcse.control_unit.secure_boot.lc_state); 
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
        // reset_handshake();
        // deployment_lifecycle_first_boot();
        // lifecycle_transition_request(lc_transition_id_deployment);
        // reset_handshake(); 
        // // boot in recall
        // reset_handshake(); 
        // recall_lifecycle_first_boot();
        // lifecycle_transition_request(lc_transition_id_recall);
        // reset_handshake(); 
        // // boot in end of life 
        // reset_handshake();
        // endoflife_lifecycle_boot(); 
    endtask 

    initial begin : drive_inputs

        for (integer i = 0; i < 10; i=i+1) begin
            rst = 0;
            fuse =0; 
            gpio_in = 0; 
            @(posedge clk);
        end 

        initialize_array();

    	rst = 1;
        fuse = 1; 
	    @(posedge clk);
        @(posedge clk); 
        @(posedge clk); 

        full_bootflow(); 

        for (int i = 0; i < 10; i++) begin
            @(posedge clk); 
        end 

        $finish; 
    end 

endmodule 