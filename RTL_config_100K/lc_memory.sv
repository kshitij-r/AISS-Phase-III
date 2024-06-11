module lc_memory #(
    parameter WIDTH = 512,
    parameter LENGTH = 6
)
(
    input  logic                      clk,
	input  logic 					  rst_n,
	input  logic					  rd_en, 
    input  logic [2:0]                addr,

    output logic [WIDTH-1:0]          rdData,
	output logic 					  valid
);

reg [WIDTH-1:0] rom [LENGTH-1:0];

always @(posedge clk, negedge rst_n) begin
	if (~rst_n) begin
		rdData <= 0;
		valid <= 0; 
		rom[0] <= 512'h0;
		rom[1] <= 512'h33a344a35afd82155e5a6ef2d092085d704dc70561dde45d27962d79ea56a24a33a344a35afd82155e5a6ef2d092085d704dc70561dde45d27962d79ea56a24a;
		rom[2] <= 512'h988b6a57b75f5696f01b8207b1c99bc888b4a2421a0ab4b29bd302f5b8a93348988b6a57b75f5696f01b8207b1c99bc888b4a2421a0ab4b29bd302f5b8a93348;
		rom[3] <= 512'h4893565d146d9fa19dc850e0c409b2a62ec5cb53eea4d4719c93a882f988284e4893565d146d9fa19dc850e0c409b2a62ec5cb53eea4d4719c93a882f988284e;
		rom[4] <= 512'hcabc36e4f52fcd1a8b62d82d975e4c8595da7f6df52e2143174c3dc8b3870e03cabc36e4f52fcd1a8b62d82d975e4c8595da7f6df52e2143174c3dc8b3870e03;
		rom[5] <= 512'hc3e0fed656de0ab97d4c2e2f8798ff16c8c4ac54192046fc72debd8e4fd801e5c3e0fed656de0ab97d4c2e2f8798ff16c8c4ac54192046fc72debd8e4fd801e5;
	
	end 
	else begin
		rom <= rom;
		if (rd_en) begin
			rdData <= rom[addr];
			valid <= 1; 
		end 
		else begin
			rdData <= 0;
			valid <= 0; 
		end 
		
	end 
	
end 

endmodule