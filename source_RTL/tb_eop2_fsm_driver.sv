module tb_eop2_fsm_driver;
 
    localparam NUM_TESTS = 100 ;
    localparam clk_change = 5;
    localparam data_width = 32;
    localparam addr_width = 32;
    localparam puf_sig_length = 256;
    localparam valid_byte_offset = 16;
    localparam parity_bits_width = 48;
    localparam N = 24;
    localparam AW = 32;
    localparam PW = 2*AW+40;
    localparam ID = 0;
    integer count;
    integer    test_passed;
    int chipIDh;
    int outFile1;
    int outFile2;
    int outfile3;
    int outfile4;
    int outfile5;
    int outfile6;
    int outfile7;
    int check;
    reg clk;
    reg rst;
    reg [255:0]   random_sha_hash[0:9];
    reg [127:0]   cam_data_in;
    reg [255:0]   cam_key;
    reg           cam_sel;
    reg [511:0]   sha_block;
    reg           sha_init;
    reg           sha_next;
    reg           sha_sel;
    reg 	        reg_access;
    reg  [N-1:0]  gpio_in;
    reg [PW-1:0]  reg_packet;
    wire [31:0]   reg_rdata;   
    wire [N-1:0]  gpio_out;   
    wire [N-1:0]  gpio_en;   
    wire 	        gpio_irq; 
    wire [31:0]   gpio_ilat;
    integer i, j,l;
    int num;
    int ran;
// SENTRY Security Controller DUT Instantiation    
    eop2_fsm_driver #(.N(N),
        .AW(AW),
        .PW(PW)) uut(.clk(clk),.rst(rst),.cam_data_in(cam_data_in),.cam_key(cam_key),
        .sha_block(sha_block),.sha_init(sha_init),.sha_next(sha_next),.sha_sel(sha_sel),.gpio_in(gpio_in),.gpio_out(gpio_out),
        .gpio_en(gpio_en),.gpio_irq(gpio_irq),.gpio_ilat(gpio_ilat)
        );
 

//Clock generator 
    initial begin
        clk <= 0 ;
        j=0;
        while (1)
            #5 clk = ~clk;
    end
 
 reg control;
 initial 
 begin
     check=0;
     $timeformat(-9, 0, "ns");
     $display("[INFO]: Initializing tests for SENTRY Security Controller");  
     @(posedge clk);
     test_passed = 0 ;
    num=10;
    // reset the module 
    rst = 1 ;
    reg_access = 0;
    reg_packet = {2*32+40-1{1'b0}};
    gpio_in = {24{1'b0}};
    random_sha_hash[0]= 256'haa12953e81bfedd3176c87a91fe95e927be9fca4be0efd73877cd0d717085ecd;
    random_sha_hash[1]= 256'h9e728b80f7693271b0e7d7eacf320525e250b05af26d00cfe08854d6774ba6ab;
    random_sha_hash[2]= 256'hb2959f02f8a864225a24d90b1f0180c98eea668dd6404835cfe1eb4666923c6d;
    random_sha_hash[3]= 256'hb2b9453e3239346a7b19376c3fdde6c2d9b0eec6dd8b9d2c50f90273aa8e00ca;
    random_sha_hash[4]= 256'h008334a7c811fa0e7b05ac2699d282d0d84b46eebcf9ec7c6a30b694f3405488;
    random_sha_hash[5]= 256'hef5fbab58211ce090385a1970a22de47da4297a16dbd9f834dd30879268692ea;
    random_sha_hash[6]= 256'h3013cf837dda038419d944bb3afa43e21d3757813b3c3e5b22ab090c40fda900;
    random_sha_hash[7]= 256'h889317a54055ec678feabbe44bca8754aa8da40fa42bfe2defa5a19dd6b4bd41;
    random_sha_hash[8]= 256'he39729f1575e36bd809c3b398e77bd0f12d7abecaa41620a41486442ef358b88;
    random_sha_hash[9]= 256'hc842c3f31306f14f4187f1badd64ce3deffe6e3c84c0a22bfc67bfac5bd6ff4b;

    chipIDh = $fopen("chipID.txt", "w");  // capture the variables of the aes
    outFile1 = $fopen("eop2_fsm_driver_original_outputs1.txt", "w"); // captures whether gpio in can be written into the internal memory logic 
    outFile2 = $fopen("eop2_fsm_driver_original_outputs2.txt", "w"); // same as outfile 1, and also the sha outputs
    outfile3 = $fopen("IPID.txt", "w");
    outfile4 = $fopen("hash_test.txt", "w");
    outfile5 = $fopen("enc_test.txt", "w");
    outfile6 = $fopen("fsm_out_test.txt", "w");
    outfile7 = $fopen("state6_result.txt", "w");
    count <= 0;
    $display("[INFO]: Asserting reset for 10 clock cycles"); 
    for(integer i=0; i< 10 ; i++) begin
        @(posedge clk);
    end
     
    $display("[INFO]: Deasserting reset"); 
    @(posedge clk);
    rst <= 0 ;

    $display("[INFO]: Starting SENTRY Tests"); 
    for (integer i=0; i < NUM_TESTS; i++) 
    begin
        
        $display("[INFO]: Running Test:%d.",i); 
        $display("[INFO]: Initiating SHA and CAMELLIA Modules for ChipID Computation"); 
        @(posedge clk);
        $display("[INFO]: CAMELLIA & SHA256 modules triggered");
        sha_sel <= 1; 
        
        
	    cam_key <=256'hBFD6A48E497ACE3E68CEF97A5CE0E75340E85A30136F9E8ABC19C9860EEF5D4F;

        
        $display("CAMELLIA Key = BFD6A48E497ACE3E68CEF97A5CE0E75340E85A30136F9E8ABC19C9860EEF5D4F");


        count <= 0;
        $display("[INFO]: Polling the status ports for 100 clock cycles."); 
        
        while(count < 100) 
        begin
            //This test the STATE6 of the FSM. At first choose_out value is set to 1, at that time it prints the encrypted CHIP ID. Then the value is set to 2.
            //When choose_out is 2 at that time it prints the encrypted value of the corresponding IP ID, which can be choosen by setting sha_enc_i to any of the 10 values from 0 to 9.

            if(uut.begin_state_6==1) begin
                
                $fwrite(outfile5,"proc_part: %d ",uut.proc_part,"ctr_rst: %d ",uut.ctr_rst,"enc: %d ",uut.enc,"counter6: %d ",uut.counter6,"cam_st: %h ",uut.data_in,"store: %h ",uut.store[0][255:128],"output_rdy: %d, ",uut.output_rdy,"aes_out: %h",uut.data_out, "\n");
                if(uut.enc==0) begin
                    //@(posedge clk);
                    if(uut.choose_out==0) begin
                        uut.choose_out<=1;
                    end
                    else if(uut.choose_out==1) begin
                        $fwrite(outfile6,"fsm_enc_out: %d ",uut.fsm_enc_out,"choose_out: %d ",uut.choose_out, "\n");
                        uut.choose_out<=2;
                        uut.sha_enc_i<=7;
                    end
                    else if(uut.choose_out==2) begin
                        $fwrite(outfile6,"fsm_enc_out: %d ",uut.fsm_enc_out,"choose_out: %d ",uut.choose_out, "\n");
                        uut.choose_out<=3;
                    end
                    else if(uut.choose_out==3) begin
                        $fwrite(outfile6,"fsm_enc_out: %d ",uut.fsm_enc_out,"choose_out: %d ",uut.choose_out, "\n");
                        uut.choose_out<=4;
                    end
                    
                end
            end
            //This tests the STATE7 of the FSM. It prints the hash of the chip manufacturer id and the hash of the system integrator id
            if(uut.current_state==6 && uut.completed_state7==1) begin
                $fwrite(outfile7,"store_chip_man_id_hash: %d ",uut.store_chip_man_id_hash,"store_sys_int_id_hash: %d ",uut.store_sys_int_id_hash, "\n");
            end
            $display("Count : %d",count);
            @(posedge clk);
            
            if(uut.output_rdy == 1'b1) begin
                $fwrite(chipIDh,"Encrypted ChipID: %d",uut.mem4, "Unencrypted ChipID: %d",uut.mem3, "CAMELLIA PUF CRP: %d",uut.cam_puf_out,"SHA PUF CRP: %d",uut.sha_puf_out,"Encryption Key: %d",cam_key,"\n");
            end
            
            $fwrite(outFile1,"current_state: %d ",uut.current_state,"key: %d ",uut.key,"data_in: %d ",uut.data_in,"data_out: %d ",uut.data_out,"data_rdy: %d ",uut.data_rdy,"key_rdy: %d ",uut.key_rdy,"key_acq: %d ",uut.key_acq,"data_acq: %d ",uut.data_acq,"output_rdy: %d ",uut.output_rdy, "\n"); 

//When the state3 ends, end_state3 is asserted 
            if(uut.end_state_3==1) begin
        //Start passing 10 random 256 bit PUF signatures through gpio_in[23:8]
                while (j<10) begin
                    $display("Passing %d th signature in slices", j);
                    for (i = 0; i < 16; i =i+1) begin
                        @(posedge clk);
                        $fwrite(outFile2,"%h.clk ",uut.clk,"%h.end_state_3 ",uut.end_state_3,"%h.do_sha ",uut.do_sha,"%h.execute_sha ",uut.execute_sha,"%h.counter4 ",uut.counter4,"%h.sha_blk ",uut.sha_blk,"%h.sha_int ",uut.sha_int,"%h.sha_rd ",uut.sha_rd,"%h.sha_dig_v ",uut.sha_dig_v,"%h.sha_dig ",uut.sha_dig, "\n");
                        $fwrite(outFile1,"%h.clk ",uut.clk,"%h.end_state_3 ",uut.end_state_3,"%h.counter3 ",uut.counter3,"%h.counter4 ",uut.counter4,"%h.gpio_in[23:8] ",uut.gpio_in[23:8],"%h.store[9] ",uut.store,"%h.reg_rdata ",uut.reg_rdata,"%h.store_val ",uut.store_val, "\n");
                        // Drive gpio_in with random number
                        gpio_in[23:8] = $urandom_range(0,65536);
                        $fwrite(outFile2,"%h.clk ",uut.clk,"%h.end_state_3 ",uut.end_state_3,"%h.do_sha ",uut.do_sha,"%h.execute_sha ",uut.execute_sha,"%h.counter4 ",uut.counter4,"%h.sha_blk ",uut.sha_blk,"%h.sha_int ",uut.sha_int,"%h.sha_rd ",uut.sha_rd,"%h.sha_dig_v ",uut.sha_dig_v,"%h.sha_dig ",uut.sha_dig, "\n");
                    end
                    j = j+1;
                end
                if(uut.end_storing==1 && check==0) begin
                    check=check+1;
                    for (int x = 0; x < 9; x =x+1) begin
                        $fwrite(outfile3,"Unhashed IPID [%d]: %h ",x,uut.store[x], "\n");
                    end
                end
            end
            // $fwrite(outFile2,"%h.clk ",uut.clk,"%h.end_state_3 ",uut.end_state_3,"%h.do_sha ",uut.do_sha,"%h.execute_sha ",uut.execute_sha,"%h.counter4 ",uut.counter4,"%h.sha_blk ",uut.sha_blk,"%h.sha_int ",uut.sha_int,"%h.sha_rd ",uut.sha_rd,"%h.sha_dig_v ",uut.sha_dig_v,"%h.sha_dig ",uut.sha_dig, "\n");
            // $fwrite(outfile4,"State4: %d ",uut.end_state_4,"Counter4 %d",uut.counter4,"Counter5 %d",uut.counter5," execute_sha %h",uut.execute_sha, "\n");
            if(uut.end_state_4==1 && uut.begin_state_6!=1) begin
                @(posedge clk);
                for (l = 0; l < num; l =l+1) begin
                    
                    uut.compare_hash <= random_sha_hash[l];
                    @(posedge clk);
                    $fwrite(outfile4,"l: %d ",l,"Hash: %h ",uut.compare_hash,"Flag: %h ",uut.flag, "\n");
                end
                if(l==num) begin
                    uut.begin_state_6=1;
                end
            end
            
            
            count++;
        end
    end 
    $fwrite(outfile3,"\nHashed IPID [0]: %h ",uut.store[0], "\n");
    $fwrite(outfile3,"Hashed IPID [1]: %h ",uut.store[1], "\n");
    $fwrite(outfile3,"Hashed IPID [2]: %h ",uut.store[2], "\n");
    $fwrite(outfile3,"Hashed IPID [3]: %h ",uut.store[3], "\n");
    $fwrite(outfile3,"Hashed IPID [4]: %h ",uut.store[4], "\n");
    $fwrite(outfile3,"Hashed IPID [5]: %h ",uut.store[5], "\n");
    $fwrite(outfile3,"Hashed IPID [6]: %h ",uut.store[6], "\n");
    $fwrite(outfile3,"Hashed IPID [7]: %h ",uut.store[7], "\n");
    $fwrite(outfile3,"Hashed IPID [8]: %h ",uut.store[8], "\n");
    $fwrite(outfile3,"Hashed IPID [9]: %h ",uut.store[9], "\n");
    $finish;
end
endmodule
