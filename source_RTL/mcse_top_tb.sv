
module mcse_top_tb;


    localparam pcm_data_width = 32;
    localparam pcm_addr_width = 32;
    localparam puf_sig_length = 256;
    localparam gpio_N = 32;
    localparam gpio_AW = 32;
    localparam gpio_PW = 2*gpio_AW+40;

    logic                 clk=0;
    logic                 rst;
	logic  [gpio_N-1:0]   gpio_in;
    logic                 ami_ack;

    logic [255:0]        mcse_ami_out;
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
        for (int i = 0; i < 16; i++) begin
            gpio_in[13] = 1;
            $displayh("IP ID Trigger received...Sending IP ID from address ", gpio_out[11:8]); 
            for (int j = 0; j < 18; j++) begin
				if (j == 0) begin 
					gpio_in[31:16] = 16'h7A7A;
                    $displayh("[TB] GPIO_IN[31:16] = ", gpio_in[31:16]);
					@(posedge clk);
					continue;
				end 
				else if (j == 17) begin
					gpio_in[31:16] = 16'hB9B9;
                    $displayh("[TB] GPIO_IN[31:16] = ", gpio_in[31:16]);
					@(posedge clk);
					continue;
				end else begin 
				gpio_in[31:16] = ipid_array[k];
                //gpio_in[31:16] = $urandom_range(0,65536);
                k = k+1;
                $displayh("[TB] GPIO_IN[31:16] = ", gpio_in[31:16]);
				@(posedge clk); 
                end  
            end 

            $display("Waiting for IP ID trigger deassert.."); 
            gpio_in[13] = 0; 
            while (gpio_out[12] != 0) begin
                @(posedge clk); 
            end 
            $display("IP ID trigger deasserted");
            //gpio_in[15] = 1;
            $displayh("Internal IP ID = " , mcse.control_unit.secure_boot.ipid_r[i]);
            if (i != 15) begin 
                $display("Waiting for IP ID trigger...");
                while (gpio_out[12] != 1) begin
                    @(posedge clk); 
                end 
            end 

        end
    endtask

    task bus_wakeup_handshake();
        $display("Waiting for bus wakeup");
        while (gpio_out[6] != 1) begin // bus wakeup
            @(posedge clk); 
        end 

        $display("Bus wakeup received...Sending bus wakeup ACK");
        gpio_in[7] = 1; // bus wakeup ack
        @(posedge clk); 
    endtask

    task chipid_generation(); //incomplete
        bus_wakeup_handshake(); 
        $display("Waiting for IP ID Trigger");
        while (gpio_out[12] != 1) begin // wait for first ip id trigger    
            @(posedge clk); 
        end
       
        ipid_send();   
        $display("[MCSE] IP ID Extraction Complete");   
    endtask

    task initialize_array();
        for (int i = 0; i < 256; i++) begin
            ipid_array[i] = $urandom_range(0,65536);
        end 
    endtask 

    initial begin : drive_inputs

        for (integer i = 0; i < 10; i=i+1) begin
            rst = 0;
            gpio_in = 0; 
            @(posedge clk);
        end 

        initialize_array();

    	rst = 1;
	    @(posedge clk);
        @(posedge clk); 
        @(posedge clk); 

        chipid_generation();
        

        while (~mcse.control_unit.secure_boot.chip_id_generation_done_r) begin
            @(posedge clk); 
        end 
        $displayh("[MCSE] Generated Chip ID, storing in memory...");

        chipid_generation(); 

        while (~mcse.control_unit.secure_boot.chip_id_challenge_done_r) begin
            @(posedge clk); 
        end
        
        $displayh("[MCSE] Internal MCSE ID = ", mcse.control_unit.secure_boot.mcse_id_r);
        $displayh("[MCSE] Internal Composite IP ID = ", mcse.control_unit.secure_boot.ipid_hash_r);
        $displayh("[MCSE] Internal Golden Chip ID = ", mcse.control_unit.mem.ram[0]);
        $displayh("[MCSE] Internal Generated Chip ID = " , mcse.control_unit.secure_boot.chip_id_r);
        $displayh("[MCSE] Internal Authentic Chip ID Value = ", mcse.control_unit.secure_boot.authentic_chip_id_r); 

        $finish; 
    end 

endmodule 