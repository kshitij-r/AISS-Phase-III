`timescale 1 ns / 100 ps

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

	initial begin :generate_clock
		while (1)
			#5 clk = ~clk;
	end	

    mcse_top #(.pcm_data_width(pcm_data_width), .pcm_addr_width(pcm_addr_width), . puf_sig_length(puf_sig_length),
    .gpio_N(gpio_N), .gpio_AW(gpio_AW), .gpio_PW(gpio_PW) )mcse ( .* );

    task ipid_send();
       
        for (int i = 0; i < 16; i++) begin
            gpio_in[13] = 1;
            $displayh("Sending IP ID from address ", gpio_out[11:8]); 
            for (int j = 0; j < 18; j++) begin
				if (j == 0) begin 
					gpio_in[31:16] = 16'h7A7A;
					@(posedge clk);
					continue;
				end 
				else if (j == 17) begin
					gpio_in[31:16] = 16'hB9B9;
					@(posedge clk);
					continue;
				end else begin 
				gpio_in[31:16] = $urandom_range(0,65536);
				@(posedge clk); 
                end  
            end 

            $display("Waiting for IP ID trigger deassert.."); 
            gpio_in[13] = 0; 
            while (gpio_out[12] != 0) begin
                @(posedge clk); 
            end 

            gpio_in[15] = 1;

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
    endtask

    initial begin : drive_inputs

        for (integer i = 0; i < 10; i=i+1) begin
            rst = 0;
            gpio_in = 0; 
            @(posedge clk);
        end 
    
    	rst = 1;
	    @(posedge clk);
        @(posedge clk); 
        @(posedge clk); 

        chipid_generation();

        for (int i = 0; i < 600; i++) begin
            @(posedge clk); 
        end 

        $stop; 
    end 

endmodule 