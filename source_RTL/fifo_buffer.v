module fifo_buffer
	#(
	parameter LENGTH = 32,
	parameter WIDTH
	)
	(
	input clk, rst,
	input write_en, read_en,
	//input RW_initiate,
	input [WIDTH-1:0] data_in,
	output reg [WIDTH-1:0] data_out
	//output full, empty
	);
	
	reg [WIDTH-1:0] fifo [LENGTH:0];
	reg [$clog2(LENGTH)-1:0] write_ptr, read_ptr, count;
	reg full, empty;
	
	always@(posedge clk) begin
		if (rst) begin
			write_ptr <= 0;
			read_ptr <= 0;
			data_out <= 0;
			count <= 0;
		end
	end
	
	always@(posedge clk) begin
		if(write_en & !full) begin
		//if (write_en) begin
			fifo[write_ptr] <= data_in;
			write_ptr <= write_ptr + 1;
			//count <= count +1;
		end
	end
	
	always@(posedge clk) begin
		if (read_en & !empty) begin
		//if (read_en) begin
			data_out <= fifo[read_ptr];
			//fifo[read_ptr] <= 'h0;
			read_ptr <= read_ptr + 1;
			//count <= count -1;
		end
	end
	
	//always@ (*) begin

	assign	full = ((write_ptr+1'b1) == read_ptr);
	assign	empty = (write_ptr == read_ptr);
	//end
	
endmodule