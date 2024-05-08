//`timescale 1 ns / 10 ps  

module lifecycle_protection_tb;

    localparam currOwnerSignature = 256'h33a344a35afd82155e5a6ef2d092085d704dc70561dde45d27962d79ea56a24a;
    logic         clk = 0;
    logic         rst; 

    logic         transition_request;
    logic [255:0] identifier;

    logic         success;
    logic [2:0]   lc_state;
    logic [255:0] foundry_signature = 256'h33a344a35afd82155e5a6ef2d092085d704dc70561dde45d27962d79ea56a24a;
    logic [255:0] oem_signature = 256'h988b6a57b75f5696f01b8207b1c99bc888b4a2421a0ab4b29bd302f5b8a93348;
    logic [255:0] deployment_signature = 256'h4893565d146d9fa19dc850e0c409b2a62ec5cb53eea4d4719c93a882f988284e;
    logic [255:0] recall_signature = 256'hcabc36e4f52fcd1a8b62d82d975e4c8595da7f6df52e2143174c3dc8b3870e03;
    

    lifecycle_protection DUT (.*);

    initial begin : generate_clock 
        while(1)
            #5 clk = ~clk; 
    end 

    task lc_transition_request(input bit [255:0] id);
        transition_request <= 1'b1; 
        identifier <=id;

        for (int i =0; i < 5; i++) 
            @(posedge clk); 
            
        if (success == 1'b1) begin
            $display("[TB] Success received...");
            $display("[LC_MODULE] Current lifecycle state is %0b", lc_state);
        end 
        else begin
             $display("[TB] Success not received...");
            $display("[LC_MODULE] Current lifecycle state is %0b", lc_state);
        end 

        $display("[TB] Deasserting transition request...");
        transition_request <= 1'b0; 
        identifier <= 0;

        for (int i =0; i < 2; i++) 
            @(posedge clk); 
    endtask

    initial begin : drive_inputs
        rst <= 1'b0;
        transition_request <= 1'b1;
        identifier <= 'h0; 

        $display("[TB] Resetting module...");
        for (int i = 0; i < 5; i++) 
            @(posedge clk); 

        @(negedge clk);
        rst <= 1'b1; 

        $display("[LC_MODULE] Current lifecycle state is %0b", lc_state);

        $display("[TB] Requesting a LC Transition with an incorrect signature: %0h", 'hA);
        lc_transition_request('hA);

        $display("[TB] Requesting a LC Transition to Manufacture and Test with the Manufacture and Test Current Owner Signature: %0h", foundry_signature);
        lc_transition_request(foundry_signature);

        $display("[TB] Requesting a LC Transition to OEM with the Manufacture and Test Current Owner Signature: %0h", foundry_signature);
        lc_transition_request(foundry_signature);

        $display("[TB] Requesting a LC Transition to Deployment with the OEM Current Owner Signature: %0h", oem_signature);
        lc_transition_request(oem_signature);

        $display("[TB] Requesting a LC Transition to Recall with the Deployment Current Owner Signature: %0h", deployment_signature);
        lc_transition_request(deployment_signature);

        $display("[TB] Requesting a LC Transition to End of Life with the Recall Current Owner Signature: %0h", recall_signature);
        lc_transition_request(recall_signature);

        $display("[TB] Simulation finished");
        disable generate_clock;
        $finish;
    end

endmodule   
