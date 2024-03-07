//TODO Buffer/Fifo
module secure_memory #(
    parameter WIDTH = 256,
    parameter LENGTH = 16
)
(
    input  logic                      clk,
	input  logic 					  rst,
	input  logic					  rd_en, 
	input  logic				      wr_en,
    input  logic [$clog2(LENGTH)-1:0] addr,
	input  logic [WIDTH-1:0]		  wrData,

    output logic [WIDTH-1:0]          rdData,
	output logic 					  rdData_valid
);

reg [WIDTH-1:0] ram [LENGTH-1:0];


always @(posedge clk, negedge rst) begin
	if (~rst) begin
		rdData <= 0;

		//ram[0] <= 0;
		//ram[1] <= 0; 
		ram[2] <= 256'h49361d1ee0abd2c572b0edf565a9984c3ed4923ab2f88cd6b0eaa30d0c13ef1b; // secure communication key 
		ram[10] <= 256'h431909d9da263164ab4d39614e0c50a32774a49b3390a53ffa63e8d74b8e7c0b;

	end 
	else begin
		if (wr_en) begin
			ram[addr] <= wrData;
		end 
		if (rd_en) begin
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