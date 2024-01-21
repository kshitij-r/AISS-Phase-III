module memory_module
	#( 
	)
	(
		input clk,
		input [255:0] data_in,
		input [4:0] address,
		input write_en,
		input read_en,
		input rst,
		input enable,
		output reg [255:0] data_out,
		output reg served
	);
	
	reg [255:0] ram [7:0];
	reg [255:0] temp_data;
	reg [1:0] count;
	
	integer i;
	initial begin
		//ram[9] = 'h01;
		//for (i = 0; i <9; i = i+1) begin
		//	ram[i] = {$random, $random, $random, $random, $random, $random, $random, $random};
		//end
		count = 0;
		ram[0] = 'h33a344a35afd82155e5a6ef2d092085d704dc70561dde45d27962d79ea56a24a;
		ram[1] = 256'hBFD6A48E497ACE3E68CEF97A5CE0E75340E85A30136F9E8ABC19C9860EEF5D4F;
		ram[2] = 'h988b6a57b75f5696f01b8207b1c99bc888b4a2421a0ab4b29bd302f5b8a93348;
		ram[3] = 'h4893565d146d9fa19dc850e0c409b2a62ec5cb53eea4d4719c93a882f988284e;
		ram[4] = 'hcabc36e4f52fcd1a8b62d82d975e4c8595da7f6df52e2143174c3dc8b3870e03;
		ram[5] = 'hc3e0fed656de0ab97d4c2e2f8798ff16c8c4ac54192046fc72debd8e4fd801e5;
		ram[6] = 'h4b05ec8a48c0e8e779b01ff6f0ef2013f37b1a89f3cf92b63ec96a3bb0da265d;
		ram[7] = 'b0000;
	end
	
	
	
	always@(posedge clk)
	begin
		if (rst) begin
			count <= 0;
		end
		else begin
			//if (enable) begin
				count <= count + 1;
				if (write_en) begin
					ram[address] <= data_in;
					
				end
					
				if (read_en) begin
					temp_data <= ram[address];
					
				end
				else begin
					temp_data <= 'h0;
					
				end
				
				if (count == 2) begin
					served <= 1;
					count <= 0;
				end
				else begin
					served <= 0;
				end
				
				data_out <= temp_data;
			//end
			//else begin
			//	temp_data <= 'h0;
			//	count <= 0;
			//	served <= 0;
			//end 
		end
	end
	

	

endmodule