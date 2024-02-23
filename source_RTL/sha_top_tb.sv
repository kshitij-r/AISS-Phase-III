`timescale 1 ns / 100 ps

module sha_top_tb;


logic [511:0] block;
logic clk = 0;
logic rst;
logic init;
logic next;
logic sel;
logic [255:0] digest;
logic ready;
logic digest_valid;
logic [255:0] pufout;

sha_top sha (.*); 

	initial begin :generate_clock
		while (1)
			#5 clk = ~clk;
	end	



initial begin : drive; 
    sel = 1; 
    rst = 1;
    block = 0;
    init = 0;
    next = 0;
    for (int i = 0; i < 10; i++) begin
        @(posedge clk); 
    end 

    rst = 0; 
    block = {256'h124, 256'h322}; 
    //block = {256'h874, 256'ha2a2};
    next = 1; 
    init = 0; 
    @(posedge clk);
    next = 0;
    block = {256'h874, 256'ha2a};
    @(posedge clk); 
    next = 1; 
    @(posedge clk); 
    next =0;
    init = 1; 
    @(posedge clk);

    init =0; 
    @(posedge clk); 
    

    while (digest_valid != 1) begin
        @(posedge clk); 
    end 
    $displayh(digest);

    /*
    //rst =1;
    for (int i =0; i < 5; i++) begin
        @(posedge clk); 
    end 

    rst = 0;
    //block = {256'h123, 256'h322}; 
    block = {256'h874, 256'ha2a2};
    next = 0; 
    init = 0; 
    @(posedge clk);
    
    next =0;
    init = 1; 
    @(posedge clk);

    init =0; 
    @(posedge clk); 

    while (digest_valid != 1) begin
        @(posedge clk); 
    end 
    $displayh(digest);
    */
    /*
    next = 1; 
    block = 0; 
    block = {256'h123, 256'h322};
        $displayh(digest);
    @(posedge clk);
    next =0; 
    init =1; 
    @(posedge clk); 

    while (digest_valid != 1) begin
        @(posedge clk); 
    end 

    for (int i = 0; i < 5; i++) begin
        @(posedge clk); 
    end 
    */
     

    $stop; 
end 


endmodule 