module ipid_stream_tb;
    logic                 clk=0;
    logic                rst;
    logic                 go;
    logic         [255:0] ipid_in;
    logic          valid;
    logic  [15:0]  ipid_chunk;


    initial begin :generate_clock
		while (1)
			#5 clk = ~clk;
	end

    ipid_stream DUT (.*);

    initial begin
        rst = 0; 
        go = 0;
        ipid_in = 256'h33a344a35afd82155e5a6ef2d092085d704dc70561dde45d27962d79ea56a24a;
        @(posedge clk);
        rst = 1;
        @(posedge clk);

        go = 1; 
        @(posedge clk); 

        for (int i = 0; i <20; i++) begin
            @(posedge clk); 
        end

        go = 0;
        @(posedge clk);
        go = 1; 
        
        for (int i = 0; i < 20; i++) begin
            @(posedge clk); 
        end 

        $finish; 
    end 
endmodule 