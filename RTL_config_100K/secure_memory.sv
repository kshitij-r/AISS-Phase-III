//TODO Buffer/Fifo
module secure_memory #(
    parameter WIDTH = 512,
    parameter LENGTH = 6
)
(
    input  logic                      clk,
	input  logic 					  rst_n,
	input  logic					  rd_en, 
	input  logic				      wr_en,
    input  logic [$clog2(LENGTH)-1:0] addr,
	input  logic [WIDTH/2-1:0]		  wrData,

    output logic [WIDTH-1:0]          rdData,
	output logic 					  rdData_valid
);

reg [WIDTH-1:0] ram [LENGTH-1:0]; 





always @(posedge clk, negedge rst_n) begin
	if (~rst_n) begin
		rdData <= 0;

		//ram[0] <= 0; //Chip ID
		ram[1] <= 256'h49361d1ee0abd2c572b0edf565a9984c3ed4923ab2f88cd6b0eaa30d0c13ef1b; // secure communication key 
		ram[2] <= 512'h431909d9da263164ab4d39614e0c50a32774a49b3390a53ffa63e8d74b8e7c0b431909d9da263164ab4d39614e0c50a32774a49b3390a53ffa63e8d74b8e7c0b; 
		ram[3] <= 512'h8e30701845bea3e44d0aed1ba6d4893a0de91fea6f42571d3714a3c6daa399788e30701845bea3e44d0aed1ba6d4893a0de91fea6f42571d3714a3c6daa39978;
		ram[4] <= 512'hd995f5ddfb1625e3a33b0ee123b6672f35df88d6652eaec51d26f3a50b030ad8d995f5ddfb1625e3a33b0ee123b6672f35df88d6652eaec51d26f3a50b030ad8;
		ram[5] <= 512'hdf0f326b1bf6611d944491d7a0618af56ac57e391ba38425f9f33cafdd7439a9df0f326b1bf6611d944491d7a0618af56ac57e391ba38425f9f33cafdd7439a9;
	
	end 
	else begin
		if (wr_en) begin
			ram[addr] <= wrData;
		end 
		else if (rd_en) begin
			rdData <= ram[addr];
			rdData_valid <= 1; 
		end 
		else begin
			rdData <= 0;
			rdData_valid <= 0; 
		end 
		
	end 
	
end 

endmodule