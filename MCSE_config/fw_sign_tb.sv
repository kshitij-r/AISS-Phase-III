// `timescale 1 ns / 100 ps

module sha_top_tb;


logic [511:0] block;
// logic [255:0] signing_key;
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

logic [255:0] signing_key;
logic [255:0] ipad;
logic [255:0] opad;
logic [255:0] ipad_xor;
logic [255:0] opad_xor;

initial begin : drive; 
    sel = 1; 
    rst = 1;
    block = 0;
    init = 0;
    next = 0;
    for (int i = 0; i < 10; i++) begin
        @(posedge clk); 
    end 
    
    
    signing_key = 256'h3F7A81E6B9F934FB8F6D4C9E3426A1D7E61D97B597F7DBB7E61D2A4FCC4A596D;
    ipad = {32{'h36}};
    opad = {32{'h5C}};
    ipad_xor = ipad ^ signing_key;
    opad_xor = opad ^ signing_key;
    // fw_r = {opad_xor, 256'h3F8D42ABE9A7E09DAB743FA1F3E67839CA1FC4F22BC526CCFF9E2F74B3447561,
    //                   256'h79050A0F7F87BEBD3D253A83C9F3E205BCBB8A76FA7DF79BB345F859366B2D9E, 
    //                   256'h6A195890AE4F30F88F7A6730578C209F2C7CE3F12A5EEDBFCE0657BDB8F140D5, 
    //                   256'h1F20967289AEBDB7F9564B96C3B9D6FED4E328EC10EBB2D20C21CB1776A934D9, 
    //                   256'h4053D28E9563E5A87498B056D078A9D8B02F4D43CC26D0A8A6740A3842F34571, 
    //                   256'h2B8FD78103B1C8919AF80FDB2E14A1BC61FD8E4004902F90C6A5F0C4BB6A13D2, 
    //                   256'h45C575D8C76D92BCF4DC0B8F73AC6D65F78EF13D7BDF23903C8C6A77AB7BCDDA, 
    //                   256'h7E694B750F0CBFC7842E92F45DE89E5BDC9D105037A5903C4C4F2B4B0C2DD1E7, 
    //                   ipad_xor}
    // 
    rst = 0;
    block = {256'h7E694B750F0CBFC7842E92F45DE89E5BDC9D105037A5903C4C4F2B4B0C2DD1E7, ipad_xor};
    init = 1;
    next = 0;
    @(posedge clk);
    init = 0;
    next = 0;
    @(posedge clk);

    while (!digest_valid) begin // wait until the hashing of first 512 blocks is done
        @(posedge clk);
    end
    
    rst = 0;
    block = {256'h2B8FD78103B1C8919AF80FDB2E14A1BC61FD8E4004902F90C6A5F0C4BB6A13D2,  
              256'h45C575D8C76D92BCF4DC0B8F73AC6D65F78EF13D7BDF23903C8C6A77AB7BCDDA};
    init = 0;
    next = 1;
    @(posedge clk);
    init = 0;
    next = 0;
    @(posedge clk);
    while (!digest_valid) begin // wait until the hashing of second 512 blocks is done
        @(posedge clk);
    end

    rst = 0;
    block = {256'h1F20967289AEBDB7F9564B96C3B9D6FED4E328EC10EBB2D20C21CB1776A934D9,
               256'h4053D28E9563E5A87498B056D078A9D8B02F4D43CC26D0A8A6740A3842F34571};
    init = 0;
    next = 1;
    @(posedge clk);
    init = 0;
    next = 0;
    @(posedge clk);
    while (!digest_valid) begin // wait until the hashing of third 512 blocks is done
        @(posedge clk);
    end

    rst = 0;
    block = {256'h79050A0F7F87BEBD3D253A83C9F3E205BCBB8A76FA7DF79BB345F859366B2D9E, 
               256'h6A195890AE4F30F88F7A6730578C209F2C7CE3F12A5EEDBFCE0657BDB8F140D5};
    init = 0;
    next = 1;
    @(posedge clk);
    init = 0;
    next = 0;
    @(posedge clk);
    while (!digest_valid) begin // wait until the hashing of fourth 512 blocks is done
        @(posedge clk);
    end

    rst = 0;
    block = {opad_xor, 256'h3F8D42ABE9A7E09DAB743FA1F3E67839CA1FC4F22BC526CCFF9E2F74B3447561};
    init = 0;
    next = 1;
    @(posedge clk);
    init = 0;
    next = 0;
    @(posedge clk);
    while (!digest_valid) begin // wait until the hashing of last 512 blocks is done
        @(posedge clk);
    end

    // rst = 0;
    // block = opad_xor;
    // init = 0;
    // next = 1;
    // @(posedge clk);
    // init = 0;
    // next = 0;
    // @(posedge clk)
    // while (!digest_valid) begin // wait until the hashing of {opad_xor, digest from last hash} is done
    //     @(posedge clk);
    // end
    
    $displayh(digest); // display final hash

    $finish;
end 


endmodule 