module memory_controller
	(
	input logic clk, rst,
	input logic [5:0] address_in,
	input logic [255:0] data_in,
	input logic read_in, write_in, RW_initiate, served, mem_enable,
	output logic [4:0] address_out,
	output logic [255:0] data_out,
	output logic mem_enable0, mem_enable1, read_en0, write_en0, read_en1, write_en1
	);
	
	wire [9:0] RW_logic;
	assign RW_logic = {mem_enable, RW_initiate, read_in, write_in, address_in};
	wire [9:0] RW_logic_out;
	wire [255:0] fifo_data_out;
	
	fifo_buffer #(.WIDTH(10)) fifo1 (.clk(clk), .rst(rst), .write_en(RW_initiate), .read_en(served), .data_in(RW_logic), .data_out(RW_logic_out));
	fifo_buffer #(.WIDTH (256)) fifo2 (.clk(clk), .rst(rst), .write_en(RW_initiate), .read_en(served), .data_in(data_in), .data_out(fifo_data_out));

	wire read_buffered, write_buffered, RW_initiate_buffered, mem_enable_buffered;
	wire [5:0] address_in_buffered;
	
	assign mem_enable_buffered = RW_logic_out[9];
	assign RW_initiate_buffered = RW_logic_out[8];
	assign read_buffered = RW_logic_out[7];
	assign write_buffered = RW_logic_out[6];
	assign address_in_buffered = RW_logic_out[5:0];
	
	
	assign data_out = fifo_data_out;
	
	
	always_comb begin
		
		address_out = 'h0;
		read_en0 = 0;
		write_en0 = 0;
		read_en1 = 0;
		write_en1 = 0;
		mem_enable0 = 0;
		mem_enable1 = 0;
		
		address_out = address_in_buffered[4:0];
		
		if (address_in_buffered < 32 & RW_initiate_buffered) begin
			read_en0 = read_buffered;
			write_en0 = write_buffered;
			mem_enable0 = mem_enable_buffered;
		end
		else begin
			read_en1 = read_buffered;
			write_en1 = write_buffered;
			address_out = address_in_buffered[4:0] - 32;
			mem_enable1 = 1;
		end
	end
	
endmodule 