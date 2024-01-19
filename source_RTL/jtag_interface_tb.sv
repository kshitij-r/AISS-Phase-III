`timescale 1 ns / 100 ps

module jtag_interface_tb;

	parameter concatenated_input_data_width = 8;
    parameter concatenated_output_data_width = 8;
    parameter tap_width = 8;
    parameter tap_id = 0;
    parameter tap_version = 0;
    parameter tap_part = 0;
    parameter tap_man_num = 0;
    parameter tap_sync_mode = 0;
    parameter tap_tst_mode = 1;
	parameter instruction_width = 8; // change as needed

 // Clock and reset signals
    logic clk=0;
    logic rst_n;

    // JTAG interface signals
    logic tck;
    logic trst_n;
    logic tms;
    logic tdi;
    logic mode;
    logic tdo;
    logic tdo_en;
    logic bypass_sel;
    logic [tap_width-2 : 0] sentinel_val;

    // Normal IP signals
    logic [concatenated_input_data_width-1 : 0] input_data, IP_output_data;
    logic [concatenated_output_data_width-1 : 0] output_data, IP_input_data;
	
	jtag_interface DUT (.*);
	
	initial begin :generate_clock
		while (1)
			#5 clk = ~clk;
	end	
	
	initial
	begin
	
	rst_n = 1;
	@(posedge clk);
	
	rst_n = 0;
	@(posedge clk);
	end 
endmodule 