module fsm_top 
	(
	input logic clk, rst,
	input logic [2:0] ami_ack ,
	input logic [255:0] jtag_in,
//	output logic [255:0] mem_data_out,
	output logic [255:0] fsm_ami,
	input logic [255:0] ami_out,
	
	input [23:0] gpio_in,
	output [23:0] gpio_out,
	output [23:0] gpio_en,
	output 	        gpio_irq,    
	output [31:0]   gpio_ilat
	
	/*
	input logic [255:0] oem_input, // from sentry
	input logic [255:0] ami_output, // from ami
	*/ 
	
	/*
	output wire [255:0] hash_output,
	output wire [255:0] ami_input,
	input logic fw_trigger,
	*/
	
	//output farom ahb bus (sentry to ta2) 
	/*
	output wire [32:0] ta2_O_haddr,
	output wire [2:0] ta2_O_hburst,
	output wire ta2_O_hmastlock,
	output  wire   [3:0]   ta2_O_hprot,
    output  wire                                   ta2_O_hnonsec,
    output  wire   [2:0]   ta2_O_hsize,
    output  wire   [1:0]   ta2_O_htrans,
    output  wire   [31:0]   ta2_O_hwdata,
    output  wire                                   ta2_O_hwrite,
    output wire [127:0] ta2_O_int_rdata,
	output wire ta2_O_int_rdata_valid,
	output wire ta2_O_done
    */
	);
	/*
	wire [255:0] data;
	wire [5:0] mem_address;
	wire read, write, RW_initiate, served, mem_enable;
	wire [4:0] address;
	wire [255:0] data_out;
	wire read_en0, write_en0, read_en1, write_en1, mem_enable0, mem_enable1;
	wire [255:0] mem_out0;
	*/
	
	/*
	wire fw_chipid_rdy;
	wire fw_expected_hash_rdy;
	wire [2:0] fw_instruction;
	wire [255:0] encrypted_fw_out;
	wire [255:0] fw_fsm_out;
	//wire fw_trigger;
	
	wire [31:0] ahb_I_int_addr;
	wire [127:0] ahb_I_int_wdata;
	wire ahb_I_int_write;
	wire ahb_I_go;
	wire ahb_I_hreadyout;
	// unsure of use
	wire [31:0] ahb_I_hrdata;
	wire ahb_I_hready;
	wire [1:0] ahb_I_hresp;
	*/
	
	
	fsm_driver fsm (.clk(clk), .rst(rst), .jtag_in(jtag_in), .ami_ack (ami_ack ), 
    .fsm_ami(fsm_ami), .gpio_in(gpio_in), .gpio_out(gpio_out), .gpio_en(gpio_en), .gpio_irq(gpio_irq), .gpio_ilat(gpio_ilat),
	.ami_out(ami_out));
	
	/*
	fw_ami fw (.clk(clk), .rst(rst), .trigger(fw_trigger), .fw_chipid_rdy(fw_chipid_rdy), .fw_expected_hash_rdy(fw_expected_hash_rdy),
	.fw_fsm_out(fw_fsm_out), .encrypted_fw_signature(oem_input), .expected_hash(ami_output), .fw_instruction(fw_instruction), .hash_output(hash_output), .encrypted_fw_out(encrypted_fw_out),
	.ChipID_out(ami_input));
	*/
	
	/*
	data_worker sentry_to_ta2_ahb (.clk(clk), .rst_n(!rst), .I_hrdata(ahb_I_hrdata), .I_hready(ahb_I_hready), .I_hresp(ahb_I_hresp), .I_hreadyout(ahb_I_hreadyout), .I_int_addr(ahb_I_int_addr),
	.I_int_wdata(ahb_I_int_wdata), .I_int_write(ahb_I_int_write), .O_haddr(ta2_O_haddr), .O_hburst(ta2_O_hburst), .hmastlock(ta2_O_hmastlock), .O_hprot(ta2_O_hprot), .O_hnonsec(ta2_O_hnonsec),
	.O_hsize(ta2_O_hsize), .O_htrans(ta2_O_htrans), .O_hwdata(ta2_O_hwdata), .O_hwrite(ta2_O_hwrite), .O_int_rdata(ta2_O_int_rdata), .O_int_rdata_valid(ta2_O_int_rdata_valid), .O_done(ta2_O_done) );
	*/
	//assign mem_data_out = mem_out0;
	
endmodule 
