module secure_memory #(
    parameter WIDTH = 256,
    parameter LENGTH = 6
)
(
    input  logic                      clk,
	input  logic 					  rst,
	input  logic					  rd_en, 
	input  logic				      wr_en,
    input  logic [$clog2(LENGTH)-1:0] addr,
	input  logic [WIDTH-1:0]		  wrData,

    output logic [WIDTH-1:0]          rdData,
	output logic 					  valid
);

reg [WIDTH-1:0] ram [LENGTH-1:0];

initial begin
		ram[0] = 256'h33a344a35afd82155e5a6ef2d092085d704dc70561dde45d27962d79ea56a24a;
		ram[1] = 256'h33a344a35afd82155e5a6ef2d092085d704dc70561dde45d27962d79ea56a24a;
		ram[2] = 256'h988b6a57b75f5696f01b8207b1c99bc888b4a2421a0ab4b29bd302f5b8a93348;
		ram[3] = 256'h4893565d146d9fa19dc850e0c409b2a62ec5cb53eea4d4719c93a882f988284e;
		ram[4] = 256'hcabc36e4f52fcd1a8b62d82d975e4c8595da7f6df52e2143174c3dc8b3870e03;
		ram[5] = 256'hc3e0fed656de0ab97d4c2e2f8798ff16c8c4ac54192046fc72debd8e4fd801e5;
	end

//assign rdData = rom[addr];

always @(posedge clk, negedge rst) begin
	if (~rst) begin
		rdData <= 0;
	end 
	else begin
		if (wr_en) begin
			ram[addr] <= wrData;
		end 
		if (rd_en) begin
			rdData <= ram[addr];
			valid <= 1; 
		end 
		else begin
			rdData <= 0;
			valid <= 0; 
		end 
		
	end 
	
end 

endmodule