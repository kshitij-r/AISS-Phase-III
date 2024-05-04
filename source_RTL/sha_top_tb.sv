// `timescale 1 ns / 100 ps

module sha_top_tb;


logic [511:0] block;
logic [255:0] signing_key;
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
    
    // start hashing of first 512 bits block
    rst = 0;
    // block = 'h24d5ea98efbd684ff4e6dab9f1a288631a0e3ccc94ded1a1f7197ea7a34e7f53491a0deed0d2194c80facf106b11678655d5d758952376a7a02107c23494ef64;
    signing_key = 256'h3F7A81E6B9F934FB8F6D4C9E3426A1D7E61D97B597F7DBB7E61D2A4FCC4A596D;
    block = {32{'h36}} ^ ;
    init = 1;
    next = 0;
    @(posedge clk);
    init = 0;
    next = 0;
    @(posedge clk);

    while (!digest_valid) begin // wait for the digest_valid (done signal) to become one
        @(posedge clk);
    end
    
    //when digest_valid=1, it means hashing of input 512 block is done and it can be displayed
    $displayh(digest); // display 256 bit hash of first block

    // start hashing of next 512 bit block
    // rst = 0;
    // // block = 'h24d5ea98efbd684ff4e6dab9f1a288631a0e3ccc94ded1a1f7197ea7a34e853491a0deed0d2194c80facf106b11678655d5d758952376a7a02107c23494ef64;
    // block = 1792'h12abef9;
    // init = 1;
    // next = 0;
    // @(posedge clk);
    // init = 0;
    // next = 0;
    // @(posedge clk);

    // while (!digest_valid) begin
    //     @(posedge clk);
    // end

    // $displayh(digest); // display 256 bits hash of second block

    // rst = 0; 
    // block = 'h24d5ea98efbd684ff4e6dab9f1a288631a0e3ccc94ded1a1f7197ea7a34e7f53491a0deed0d2194c80facf106b11678655d5d758952376a7a02107c23494ef64;
    // //block = 'h14d5ea98efbd684ff4e6dab9f1a288631a0e3ccc94ded1a1f7197ea7a34e7f53491a0dffd0d2194c80facf106b11638655d5d758952376a7a02107c11094ef64; 
    // //block = {256'h874, 256'ha2a2};
    // next = 0; 
    // init = 1; 
    // @(posedge clk);
    // //block = 'h24d5ea98efbd684ff4e6dab9f1a288631a0e3ccc94ded1a1f7197ea7a34e7f53491a0deed0d2194c80facf106b11678655d5d758952376a7a02107c23494ef64;
    // next = 0;
    // init = 0; 
    // @(posedge clk); 
    
    // while (digest_valid != 1) begin
    //     @(posedge clk); 
    // end 
    // $displayh(digest);

    // rst = 0; 
    // block = 'h24d5ea98efbd684aa4e6dab9f1a288631a0e3ccc94ded1a1f7197ea7a34e7f53491a0deed0d2194c80facf106b11678655d5d758952376a7a02107c23494ef64;
    // //block = 'h14d5ea98efbd684ff4e6dab9f1a288631a0e3ccc94ded1a1f7197ea7a34e7f53491a0dffd0d2194c80facf106b11638655d5d758952376a7a02107c11094ef64; 
    // //block = {256'h874, 256'ha2a2};
    // next = 1; 
    // init = 0; 
    // @(posedge clk);
    // //block = 'h24d5ea98efbd684ff4e6dab9f1a288631a0e3ccc94ded1a1f7197ea7a34e7f53491a0deed0d2194c80facf106b11678655d5d758952376a7a02107c23494ef64;
    // next = 0;
    // init = 0; 
    // @(posedge clk); 
    
    // while (digest_valid != 1) begin
    //     @(posedge clk); 
    // end 
    // $displayh(digest);

    $finish;
end 


endmodule 