`include "mcse_def.svh"

module lc_memory #(
    parameter WIDTH = `LC_MEMORY_WIDTH,
    parameter LENGTH = 6
)
(
    input  logic                      clk,
	input  logic 					  rst_n,
	input  logic					  rd_en, 
    input  logic [$clog2(LENGTH)-1:0] addr,

    output logic [WIDTH-1:0]          rdData,
	output logic 					  valid
);

reg [WIDTH-1:0] rom [LENGTH-1:0];

always @(posedge clk, negedge rst_n) begin
	if (~rst_n) begin
		rdData <= 0;
		valid <= 0; 
		rom[0] <= 256'h0;
		// rom[1] <= 256'h33a344a35afd82155e5a6ef2d092085d704dc70561dde45d27962d79ea56a24a;
		rom[1] <= {WIDTH/32{32'h33a344a3}};
		// rom[2] <= 256'h988b6a57b75f5696f01b8207b1c99bc888b4a2421a0ab4b29bd302f5b8a93348;
		rom[2] <= {WIDTH/32{32'h988b6a57}};
		// rom[3] <= 256'h4893565d146d9fa19dc850e0c409b2a62ec5cb53eea4d4719c93a882f988284e;
		rom[3] <= {WIDTH/32{32'h4893565d}};
		// rom[4] <= 256'hcabc36e4f52fcd1a8b62d82d975e4c8595da7f6df52e2143174c3dc8b3870e03;
		rom[4] <= {WIDTH/32{32'hcabc36e4}};
		// rom[5] <= 256'hc3e0fed656de0ab97d4c2e2f8798ff16c8c4ac54192046fc72debd8e4fd801e5;
		rom[5] <= {WIDTH/32{32'hc3e0fed6}};
		//$readmemh("lc_memory_file.mem", rom);
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