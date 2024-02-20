`timescale 1 ns / 100 ps

module mcse_top_tb;


    localparam pcm_data_width = 32;
    localparam pcm_addr_width = 32;
    localparam puf_sig_length = 256;
    localparam gpio_N = 24;
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

    initial begin : drive_inputs

        for (integer i = 0; i < 10; i=i+1) begin
            rst = 0;
            @(posedge clk);
        end 
    
    	rst = 1;
	    @(posedge clk);

        for (int i = 0; i < 100; i=i+1) begin
            @(posedge clk); 
        end 
        $stop; 
    end 

endmodule 