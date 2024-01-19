`define GPIO_IDATA 6'h5
`define GPIO_ODATA 6'h0

`define         AHB_TRANS_IDLE                      2'b00
`define         AHB_DATA_WIDTH_BITS                 32


module fsm_driver(
	input clk,
	input rst,
	input [2:0] ami_ack,
	input [255:0] ami_out,
	input  [255:0] 	jtag_in,
	/*
	input logic [2:0] fw_instruction,
	input logic [255:0] encrypted_fw,
	output reg [255:0] fw_fsm_out,
	output logic fw_expected_hash_rdy,
	output logic fw_chipid_rdy,
	*/
	output logic [255:0] fsm_ami,
	
	input  [23:0] gpio_in,
	output logic [23:0] gpio_out,
	output [23:0] gpio_en,
	output 	        gpio_irq,    
	output [31:0]   gpio_ilat
	
	/*
	// ahb bus input
	// used to write 
	output logic [31:0] ahb_I_int_addr,
	output logic [127:0] ahb_I_int_wdata,
	output logic ahb_I_int_write,
	output logic ahb_I_go,
	output logic ahb_I_hreadyout,
	// unsure of use
	output logic [31:0] ahb_I_hrdata,
	output logic ahb_i_hready,
	output logic [1:0] ahb_I_hresp
	*/
	// ahb logic output 
	
	
	
	
	//input fw_trigger
	//output fw_trigger_to_fwmodule
	);

	typedef enum logic [5:0] {BOOT_START, BOOT_START_WAIT, MANUFACTURETEST_START, MANUFACTURETEST1_WAIT, MANUFACTURETEST2, MANUFACTURETEST3_WAIT, MANUFACTURETEST_BOOTED,
	MANUFACTURETEST5, MANUFACTURETEST5_WAIT, OEM_START, CHIPID_LC_AUTH_WAIT, OEM_BOOTED, MANUFACTURETEST_BOOT,OEM4, OEM_BOOT, DEPLOYMENT_START, RECALL_START, EOL_START, MANUFACTURETESTREG_START,
	ABORT, CHIPIDGENERATION, CHIPIDGENERATION1, CHIPIDGENERATION2, CHIPIDGENERATION3, MANUFACTURETESTREG_ASSETS, MANUFACTURETESTREG_ASSETS_WAIT, CHIPIDGENERATION4, 
	CHIPIDGENERATION4_PRE0, CHIPIDGENERATION4_PRE1, LIFECYCLE_CALLBACK, OEM_AUTH, CURROWNID_FETCH, ENCRYPTION, CALLBACK1,
	ASSET_FETCH, ASSET_ENC, CURROWNID_FETCH1, OEM_LIFECYCLEAUTH, ENCRYPTION_CALLBACK, CURROWNID_AUTH, OEM_AMI_AUTH, MEM_FETCH, FW_DECRYPTION, FW_temp, FW_HASH, TEMP_STATE,
	FW_CHIPID, FW_AUTH, UPGRADE_FW, KEY_FETCH, KEY_WAIT, KEY_FETCH1, DEPLOYMENT_BOOTED, KEY_WAIT1, LCTRANSITION_AUTH,
	RECALL_WAIT, RECALL_CURROWN_AUTH, RECALL_BOOTED, CHIPID_AUTH, LIFECYCLEAUTH, RECALL_LCTRANSITION_AUTH,
	RECALL_AMI_AUTH, EOF_START, RECALL_BOOT } state_t;
	state_t state_r, next_state;
	
	//reg [24-1:0] gpio_out;
	//reg [24-1:0] gpio_en;   
	//reg 	        gpio_irq;    
	//reg [31:0]   gpio_ilat;
	wire [255:0] sha_puf_out;
	wire [255:0] cam_puf_out;
	wire [255:0] aes_puf_out;
	wire [127:0] aes_out;
	wire [255:0] sha_dig;
	wire  sha_dig_v;
	wire sha_rd;
	reg aes_out_val;
	logic ctr_rst_r, next_ctr_rst;
	reg [127:0] aes_st;
	reg  aes_strt;
	reg  aes_select;
	reg [511:0] sha_blk;
	reg sha_int_r, next_sha_int;
	reg sha_nxt;
	reg sha_slt;
	reg proc_part_r, next_proc_part;
	reg [255:0] key_r, next_key;
	
	reg reg_access_r, next_reg_access;
	reg [104-1:0] reg_packet_r, next_reg_packet;
	reg [31:0]   reg_rdata;
	reg store_val_r, next_store_val;
	
	logic [127:0] data_in_r, next_data_in;
	reg [0:1] k_len;
	reg enc_dec;
	logic data_rdy_r, next_data_rdy;
	logic key_rdy_r, next_key_rdy;
	reg [127:0] data_out;
	reg data_acq;
	reg key_acq;
	reg output_rdy;
	
	min_security_module #(32,32,256,16,48,24,32,2*32+40,0) m1(.clk(clk),.rst(ctr_rst_r),.data_in(data_in_r),
    .key(key_r),
    .k_len(k_len),
    .enc_dec(enc_dec),
    .data_rdy(data_rdy_r),
    .key_rdy(key_rdy_r),
    .data_out(data_out),
    .data_acq(data_acq),
    .key_acq(key_acq),
    .output_rdy(output_rdy),
    .cam_pufout(cam_puf_out),.sha_block(sha_blk),
	.sha_init(sha_int_r),.sha_next(sha_nxt),.sha_sel(sha_slt),.sha_digest(sha_dig),.sha_ready(sha_rd),.sha_digest_valid(sha_dig_v),.sha_pufout(sha_puf_out),
	.sig_in(),.IP_ID_in(),.Instruction_in(),.sig_valid(),.control_out(),.status(),.comp_out(),
	.S_c(),.A_c(), .reg_access(reg_access_r),.gpio_in(gpio_in),.reg_packet(reg_packet_r),.reg_rdata(reg_rdata),.gpio_out(gpio_out),.gpio_en(gpio_en),.gpio_irq(gpio_irq),.gpio_ilat(gpio_ilat));
	
	reg [255:0] mem_data_out;  ////////////////
	reg read_r, next_read; ///
	reg write_r, next_write; ///
	reg RW_initiate_r, next_RW_initiate, mem_enable; ///////
	reg [255:0] data_r, next_data;
	reg [5:0] mem_address_r, next_mem_address;
	reg  served;
	reg [4:0] address;
	reg [255:0] data_out_mem;
	reg read_en0, write_en0, read_en1, write_en1, mem_enable0, mem_enable1;
	reg [255:0] mem_out0;
	
	
	memory_controller controller (.clk(clk), .rst(rst), .address_in(next_mem_address), .data_in(data_r), .read_in(read_r), .write_in(write_r), .RW_initiate(RW_initiate_r),.served(served), .address_out(address), 
	.data_out(data_out_mem), .read_en0(read_en0), .write_en0(write_en0), .read_en1(read_en1), .write_en1(write_en1), .mem_enable0(mem_enable0), .mem_enable1(mem_enable1));
	memory_module memory (.clk(clk), .data_in(data_out_mem), .address(address), .enable(mem_enable0), .write_en(write_en0), .read_en(read_en0), .rst(rst), .data_out(mem_data_out), .served(served));
	
	logic [2:0] fw_instruction;
	logic [255:0] encrypted_fw;
	logic [255:0] fw_fsm_out;
	logic fw_expected_hash_rdy;
	logic fw_chipid_rdy;
	
	//assign fw_trigger_to_fwmodule = fw_trigger;
	reg [255:0] temp_r, next_temp;
	reg [255:0] enc_temp_r, next_enc_temp;
	reg [255:0] mem1 ;
	reg [255:0] mem2 ;
	reg [255:0] mem3 ; // sentry silicon id
	reg [255:0] EncSentrySiliconID_r, next_EncSentrySiliconID; // encrypted sentry silicon id
	reg [255:0] mem_out;

	reg [0:9][255:0] store_r, next_store; // seperate IP IDs, composite IP ID would be hashed using sha 
	reg [255:0] composite_ip_id;
	reg [255:0] enc_composite_ip_id_r, next_enc_composite_ip_id;
	reg [255:0] enc_watermark; 
	reg [3:0] current_state1;
	reg do_sha;
	logic execute_sha_r, next_execute_sha;
	reg end_storing;
	
	
	reg [255:0] fsm_ami_r, next_fsm_ami;
	
	logic [3:0] counterA_r, next_counterA;
	logic [2:0] counter_r, next_counter;
	logic counter1_r, next_counter1;
	logic counter2_r, next_counter2;
	logic [4:0] counter3_r, next_counter3;
	logic [3:0] counter4_r, next_counter4;
	logic [1:0] call_back_r, next_call_back;
	logic [2:0] call_back1_r, next_call_back1;
	
	logic [5:0] i_r, next_i;
	logic [7:0] index_r, next_index;
	
	logic call_back2_r, next_call_back2;
	//reg chipIDGenerated = 0;
	logic [255:0] mem1_r;
	logic [255:0] mem2_r;
	logic [255:0] mem3_r;
	
	reg ipid_valid_r, next_ipid_valid;
	reg ipid_finished_r, next_ipid_finished;
	logic upgrade_fw_flag_r, next_upgrade_fw_flag;
	assign fsm_ami = fsm_ami_r;
	
	reg [31:0] ahb_I_int_addr_r, next_ahb_I_int_addr;
	assign ahb_I_int_addr = ahb_I_int_addr_r;
	
	reg [127:0] ahb_I_int_wdata_r, next_ahb_I_int_wdata;
	assign ahb_I_int_wdata = ahb_I_int_wdata_r;
	
	reg ahb_I_int_write_r, next_ahb_I_int_write;
	assign ahb_I_int_write = ahb_I_int_write_r;
	
	reg ahb_I_go_r, next_ahb_I_go;
	assign ahb_I_go = ahb_I_go_r;
	
	reg ahb_I_hreadyout_r, next_ahb_I_hreadyout;
	assign ahb_I_hreadyout = ahb_I_hreadyout_r;
	
	logic countertemp_r, next_countertemp; 
	
	// Using a 2-process FSM 
	// The FSM is currently unoptimized and has some reduntant states that perform similar tasks
	
	// AMI and TA2 is simulated through testbench
	
	always @(posedge clk) begin
		if (rst) begin
			state_r <= BOOT_START;
			//state_r <= MANUFACTURETEST_START;
			
			countertemp_r <= 0; /////
			
			RW_initiate_r <= 0;
			mem_address_r <= 0;
			read_r <= 0;
			write_r <= 0;
			EncSentrySiliconID_r <= 0;
			data_r <= 0;
			enc_composite_ip_id_r <= 0;
			enc_temp_r <= 0;
			temp_r <= 0;
			ahb_I_hreadyout_r <= 0;
			ahb_I_int_write_r <= 0;
			ahb_I_int_wdata_r <= 0;
			ahb_I_go_r <= 0;
			upgrade_fw_flag_r <= 0;
			fsm_ami_r <= 'h0;
			counterA_r <= 'h0;
			counter_r <= 'h0;
			counter1_r <= 'h0;
			counter2_r <= 'h0;
			counter3_r <= 'h0;
			counter4_r <= 'h0;
			call_back_r <= 'h0; 
			call_back1_r <= 'h0;
			store_val_r <= 'h0;
			proc_part_r <= 'h0;
			ctr_rst_r <= 'h1;
			data_in_r <= 'h0;
			data_rdy_r <= 'h0;
			key_r <= 'h0;
			key_rdy_r <= 'h0;
			sha_int_r <= 'h0;
			execute_sha_r <= 'h0;
			i_r <= 'h0;
			index_r <= 'h0;
			call_back2_r <= 'b0;
			mem1_r <= 'h0;
			mem2_r <= 'h0;
			mem3_r <= 'h0;
			reg_packet_r <= 'h0;
			reg_access_r <= 1;
			ipid_valid_r <= 0;
			ipid_finished_r <= 0;
			store_r <= 0;
			
			// FOR IP ID EXTRACTION DEMO
			//state_r <= TEMP_STATE;
			
			// FOR LIFECYCLE TRANSITION DEMO
			//state_r <= OEM_BOOT;
		end
		else begin
			state_r<=next_state;
			RW_initiate_r <= next_RW_initiate; 
			countertemp_r <= next_countertemp;
			mem_address_r <= next_mem_address;
			read_r <= next_read;
			write_r <= next_write; 
			data_r <= next_data;
			EncSentrySiliconID_r <= next_EncSentrySiliconID;
			enc_composite_ip_id_r <= next_enc_composite_ip_id; 
			enc_temp_r <= next_enc_temp; 
			temp_r <= next_temp;
			ahb_I_hreadyout_r <= next_ahb_I_hreadyout;
			ahb_I_int_write_r <= next_ahb_I_int_write; 
			ahb_I_int_wdata_r <= next_ahb_I_int_wdata;
			ahb_I_go_r <= next_ahb_I_go;
			upgrade_fw_flag_r <= next_upgrade_fw_flag;
			store_r <= next_store;
			ipid_finished_r <= next_ipid_finished;
			ipid_valid_r <= next_ipid_valid;
			counterA_r <= next_counterA;
			counter_r <= next_counter;
			counter1_r <= next_counter1;
			counter2_r <= next_counter2;
			counter3_r <= next_counter3;
			counter4_r <= next_counter4;
			call_back_r <= next_call_back;
			call_back1_r <= next_call_back1; 
			fsm_ami_r <= next_fsm_ami;
			store_val_r <= next_store_val;
			proc_part_r <= next_proc_part;
			ctr_rst_r <= next_ctr_rst;
			data_in_r <= next_data_in;
			data_rdy_r <= next_data_rdy;
			key_r <= next_key;
			key_rdy_r <= next_key_rdy;
			sha_int_r <= next_sha_int;
			execute_sha_r <= next_execute_sha;
			call_back2_r <= next_call_back2;
			mem1_r <= mem1;
			mem2_r <= mem2;
			mem3_r <= mem3;
			reg_packet_r <= next_reg_packet;
			reg_access_r <= next_reg_access;
		end
	end
	
	always_comb begin
		next_countertemp = countertemp_r;
		next_enc_temp = enc_temp_r; 
		next_temp = temp_r; 
		next_enc_composite_ip_id = enc_composite_ip_id_r; 
		next_data = data_r;
		
		next_EncSentrySiliconID = EncSentrySiliconID_r;
		
		next_RW_initiate = 0;
		next_data_in = data_in_r ;
		next_data_rdy = data_rdy_r;
		next_execute_sha = execute_sha_r;
		next_key_rdy = key_rdy_r;
		next_key = key_r ;
		next_sha_int = sha_int_r;
		sha_blk = 0;
		sha_nxt = 0;
		sha_slt = 1;
	
		
		next_ahb_I_int_write = ahb_I_int_write_r; 
		next_ahb_I_go = ahb_I_go_r;
		next_upgrade_fw_flag = upgrade_fw_flag_r;
		next_store = store_r;
		next_store_val = store_val_r;
		next_ipid_finished = ipid_finished_r;
		next_ipid_valid = ipid_valid_r;
		next_reg_access = reg_access_r;
		next_reg_packet = reg_packet_r;
		mem1 = mem1_r;
		mem2 = mem2_r;
		mem3 = mem3_r;
		
		next_call_back2 = call_back2_r;
		next_counterA = counterA_r;
		next_counter = counter_r;
		next_counter1 = counter1_r;
		next_counter2 = counter2_r;
		next_counter3 = counter3_r;
		next_counter4 = counter4_r;
		
		next_proc_part = proc_part_r;
		
		next_call_back = call_back_r;
		next_call_back1 = call_back1_r;
		next_fsm_ami = fsm_ami_r;
		next_ctr_rst = ctr_rst_r;
		
		next_state = state_r;
		
		k_len = 2'b10;
		enc_dec = 1;
		
		fw_fsm_out = 0;
		fw_expected_hash_rdy=0;
		fw_chipid_rdy=0;
		
		next_read = read_r;
		next_write = write_r;
		next_mem_address= mem_address_r;
		
		case (state_r) 
			// At first boot, the lifecycle will be fetched and then the FSM will move to the corresponding states 
			TEMP_STATE : begin
				// IP ID Extraction 
				
				next_state = CHIPIDGENERATION2;
				//next_reg_packet= {6'h0,  32'h1, 1'b0,  3'b000, 16'b0, 24'b0, `GPIO_ODATA, 2'b0, 7'b0, 1'b1};
				//next_reg_packet= {6'h0,  32'b100, 1'b0,  3'b000, 20'b0, `GPIO_ODATA, 2'b0, 7'b0, 1'b1};
				next_reg_access =1;
				next_ctr_rst = 0;
				
				
				// Lifecycle Transition
				/*
				next_ctr_rst = 0;
				next_reg_access = 1;
				//next_reg_packet= {6'h0,  32'h1, 1'b0,  3'b000, 16'b0, 24'b0, `GPIO_ODATA, 2'b0, 7'b0, 1'b1};
				next_reg_packet= {6'h0,  32'h1, 1'b0,  3'b000, 20'b0, `GPIO_ODATA, 2'b0, 7'b0, 1'b1};
				next_state = OEM_BOOT;
				*/
				
				// FW Authentication 
				/*
				next_reg_access = 1;
				next_reg_packet= {6'h0,  32'h1, 1'b0,  3'b000, 20'b0, `GPIO_ODATA, 2'b0, 7'b0, 1'b1};
				next_state = DEPLOYMENT_START;
				next_ctr_rst = 0;
				*/
			end 
			BOOT_START : begin 
				next_reg_access = 1;
				next_reg_packet= {6'h0,  32'h0, 1'b0,  3'b000, 16'b0, 24'b0, `GPIO_ODATA, 2'b0, 7'b0, 1'b1};
				//Lifecycle fetch 
				if (served == 1) begin
					next_data = 'h0;
					next_write = 0;
					next_read = 1;
					mem_enable = 1;
					next_mem_address = 'h07;
					next_RW_initiate = 1;
					next_state = BOOT_START_WAIT;
					next_counterA = 'h0;
				end
			end
			BOOT_START_WAIT : begin 
			next_reg_access = 0;
			next_reg_packet= {6'h0,  32'h0, 1'b0,  3'b000, 16'b0, 24'b0, `GPIO_ODATA, 2'b0, 7'b0, 1'b0};
			//Lifecycle state fetch
				next_RW_initiate = 0;
			
				if (counterA_r < 1) begin
					if (served == 1) begin 
						next_counterA = counterA_r + 1;
					end 
				end 
				else begin
					if (served == 1) begin 
						next_counterA = 0;	
						if (mem_data_out[2:0] == 3'b000) begin
							next_state = MANUFACTURETEST_START;
							
						end
						else if (mem_data_out[3:0] == 4'b0001) begin
							next_state = MANUFACTURETEST_START;
						end
						else if (mem_data_out[3:0] == 4'b1001) begin
							next_reg_access = 1;
							next_reg_packet= {6'h0,  32'h1, 1'b0,  3'b000, 20'b0, `GPIO_ODATA, 2'b0, 7'b0, 1'b1};
							next_state = MANUFACTURETEST_BOOT;
						end 
						else if (mem_data_out[3:0] == 4'b0010) begin
							next_state = OEM_START;
						end 
						else if (mem_data_out[3:0] == 4'b1010) begin
							next_reg_access = 1;
							next_reg_packet= {6'h0,  32'h1, 1'b0,  3'b000, 20'b0, `GPIO_ODATA, 2'b0, 7'b0, 1'b1};
							next_state = OEM_BOOT;
						end 
						else if (mem_data_out[3:0] == 4'b0011) begin
							next_state = DEPLOYMENT_START;
						end 
						else if (mem_data_out[3:0] == 4'b1011) begin
							next_reg_access = 1;
							//gpio packet to boot SoC
							next_reg_packet= {6'h0,  32'h1, 1'b0,  3'b000, 16'b0, 24'b0, `GPIO_ODATA, 2'b0, 7'b0, 1'b1}; 
							next_state = DEPLOYMENT_START;
						end 
						else if (mem_data_out[3:0] == 4'b0100) begin
							next_state = RECALL_START;
						end
						else if (mem_data_out[3:0] == 4'b1100) begin
							next_state = EOF_START; 
						end 
						else if (mem_data_out[2:0] == 3'b101) begin
							next_state = EOF_START; 
						end 
						
						/*
						if (countertemp_r == 0) begin
							next_state = MANUFACTURETEST_START;
						end 
						else if (countertemp_r == 1) begin
							next_state = OEM_START; 
						end 
						*/
					end 
				end 
			end 
			MANUFACTURETEST_START : begin 
				next_ctr_rst = 1;
				next_state = CHIPIDGENERATION;
				next_EncSentrySiliconID=256'h0;
				next_call_back = 'b00;
				
			end
			CHIPIDGENERATION : begin
				// This state grabs the PUF signatures from Camellia and SHA  
			
				sha_slt=1'b1;
                mem1=cam_puf_out;
                mem2=sha_puf_out;
                mem3=mem1 ^ mem2; 
                next_state=KEY_FETCH;
                next_proc_part=2'b0;
				next_ctr_rst = 1;
				next_reg_access = 0;
			end 
			KEY_FETCH : begin
				if (served == 1) begin
					next_data = 'h0;
					next_write = 0;
					next_read = 1;
					mem_enable = 1;
					next_mem_address = 'h01;
					next_RW_initiate = 1;
					next_state = KEY_WAIT;
				end
			end
			KEY_WAIT : begin
				if (counterA_r < 1) begin
					if (served == 1) begin 
						next_counterA = counterA_r + 1;
					end 
				end 
				else begin
					if (served == 1) begin 
						next_counterA = 0;
						next_key = mem_data_out;
						next_state = CHIPIDGENERATION1;
					end 
				end 
			end
			// For encyption, cam_key is provided using the testbench. This key will later come from the memory module.
			// This state encrypts the Sentry Silicon ID
			CHIPIDGENERATION1 : begin
				next_ctr_rst=0; ///////////////////
				if(proc_part_r == 0) begin
				
					next_data_in=mem3[255:128];
					enc_dec=1;
					next_data_rdy=1;
					//next_key = cam_key;
					k_len=2'b10;
					next_key_rdy=1;
					if(key_acq==1) begin
						next_key_rdy=0;
					end
					if(output_rdy ==1) begin
						next_EncSentrySiliconID[255:128]=data_out;
						next_proc_part=1;
						next_ctr_rst=1;
					end      
				end
				else if(proc_part_r==1) begin
					next_ctr_rst=0;
					next_data_in=mem3[127:0];
					enc_dec=1;
					next_data_rdy=1;
					//next_key = cam_key;
					k_len=2'b10;
					next_key_rdy=1;
					if(key_acq==1) begin
						next_key_rdy=0;
					end
					if(output_rdy ==1) begin
						next_proc_part=1'b0;
						next_EncSentrySiliconID[127:0]=data_out;
						//end_state_3<=1;
						next_state=CHIPIDGENERATION2;
						next_reg_access = 1;
						next_reg_packet= {6'h0,  32'b100, 1'b0,  3'b000, 20'b0, `GPIO_ODATA, 2'b0, 7'b0, 1'b1};
						next_key_rdy=0;
						next_data_rdy=0;
						next_ctr_rst=1;
						next_sha_int=0;
						next_store_val=0;
						next_counter=0;
						next_execute_sha=0;
						do_sha=0;
						end_storing=0;
					end
				end          
			end
			CHIPIDGENERATION2 : begin
			//This state grabs the IP IDs from the TA2 IPs and stores them in the register store
			
			//comes from gpio 
			next_ctr_rst=0;
			
				next_proc_part =0;
						//counter<=0;
				//next_counter1=0;
				//next_counter2=0;
				//counter3<=56;
				//counter4<=20;
				//ctr_rst<=0;
				next_reg_access=1;
				//sha_int<=1;
				///next_reg_packet= {6'h0,  32'd0, 1'b0,  3'b000, 16'b0, 24'b0, `GPIO_IDATA, 2'b0, 7'b0, 1'b0};
				
				case (counter_r) 
					3'b000 : begin 
						next_reg_packet = {6'h0,  32'b100, 1'b0,  3'b000, 20'b0, `GPIO_ODATA, 2'b0, 7'b0, 1'b1};
						next_counter = counter_r+1; 
					end 
					3'b001 : begin 
						next_reg_packet = {6'h0,  32'b0000, 1'b0,  3'b000, 20'b0, `GPIO_ODATA, 2'b0, 7'b0, 1'b1};
						next_counter = counter_r+1; 
					end 
					3'b010 : begin
						
						next_reg_packet = {6'h0,  32'b0000, 1'b0,  3'b000, 20'b0, `GPIO_IDATA, 2'b0, 7'b0, 1'b0};
						if (reg_rdata[3] == 1'b1) begin 
							next_counter = counter_r+1; 
						end 
					end 
					3'b011 : begin
						next_store_val=1; 
						next_reg_packet = {6'h0,  32'b10000, 1'b0,  3'b000, 20'b0, `GPIO_ODATA, 2'b0, 7'b0, 1'b1};;
						next_counter = counter_r+1; 
					end 
					3'b100 : begin
						next_reg_packet = {6'h0,  32'b000, 1'b0,  3'b000, 20'b0, `GPIO_ODATA, 2'b0, 7'b0, 1'b1};
						next_counter = counter_r+1; 
					end
					3'b101 : begin
						next_reg_packet = {6'h0,  32'b000, 1'b0,  3'b000, 20'b0, `GPIO_IDATA, 2'b0, 7'b0, 1'b0};
					end 
				endcase 
				
				
				if(ipid_finished_r == 1) begin
					next_counter3=0;
					next_counter4=counter4_r+1;
					next_ipid_finished = 0;
				end
				if(counter4_r>=4'b1010) begin
					next_state = CHIPIDGENERATION3;
					next_counter4 =0;
					next_reg_access=0;
					next_store_val=0;
				end
				
				if(store_val_r==1) begin
				
					if (reg_rdata[23:8] == 'h7A7A) begin
						next_ipid_valid = 1;
					end 
					
					if (ipid_valid_r == 1) begin 
						next_reg_access=1;
						case (counter3_r)
							5'b00000: begin
								next_store[counter4_r][255:240]=reg_rdata[23:8];
								next_counter3=counter3_r+1;
							end 
							5'b00001: begin
								next_store[counter4_r][239:224]=reg_rdata[23:8];
								next_counter3=counter3_r+1;
							end
							5'b00010: begin
								next_store[counter4_r][223:208]=reg_rdata[23:8];
								next_counter3=counter3_r+1;
							end
							5'b00011: begin
								next_store[counter4_r][207:192]=reg_rdata[23:8];
								next_counter3=counter3_r+1;
							end
							5'b00100: begin
								next_store[counter4_r][191:176]=reg_rdata[23:8];
								next_counter3=counter3_r+1;
							end
							5'b00101: begin
								next_store[counter4_r][175:160]=reg_rdata[23:8];
								next_counter3=counter3_r+1;
							end
							5'b00110: begin
								next_store[counter4_r][159:144]=reg_rdata[23:8];
								next_counter3=counter3_r+1;
							end
							5'b00111: begin
								next_store[counter4_r][143:128]=reg_rdata[23:8];
								next_counter3=counter3_r+1;
							end
							5'b01000: begin
								next_store[counter4_r][127:112]=reg_rdata[23:8];
								next_counter3=counter3_r+1;
							end
							5'b01001: begin
								next_store[counter4_r][111:96]=reg_rdata[23:8];
								next_counter3=counter3_r+1;
							end
							5'b01010: begin
								next_store[counter4_r][95:80]=reg_rdata[23:8];
								next_counter3=counter3_r+1;
							end
							5'b01011: begin
								next_store[counter4_r][79:64]=reg_rdata[23:8];
								next_counter3=counter3_r+1;
							end
							5'b01100: begin
								next_store[counter4_r][63:48]=reg_rdata[23:8];
								next_counter3=counter3_r+1;
							end
							5'b01101: begin
								next_store[counter4_r][47:32]=reg_rdata[23:8];
								next_counter3=counter3_r+1;
							end
							5'b01110: begin
								next_store[counter4_r][31:16]=reg_rdata[23:8];
								next_counter3=counter3_r+1;
							end
							5'b01111: begin
								next_store[counter4_r][15:0]=reg_rdata[23:8];
								next_counter3=counter3_r+1;
							end
							5'b10000: begin
								if (reg_rdata[23:8] == 16'hB9B9) begin 
									next_ipid_finished = 1;
									next_ipid_valid = 0;
								end 
								else begin
									next_reg_packet= {6'h0,  32'b100, 1'b0,  3'b000, 20'b0, `GPIO_ODATA, 2'b0, 7'b0, 1'b1};
									next_store_val = 0;
									next_counter = 0;
									next_counter3 = 0;
									next_counter4 = 0;
									next_ipid_valid = 0;
									next_store = 0;
								end 
							end 
						endcase
					end 
				end
			end
			CHIPIDGENERATION3 : begin
			// This state hashes the TA2 IP IDs to a 256 bit Composite IP ID 
				next_reg_access=0;	
				next_ctr_rst=0;
				do_sha=0;
				//sha_int<=1;
					
				if (counter4_r == 0) begin
					next_sha_int = 0;
					sha_blk={store_r[counter4_r+1],store_r[counter4_r]};
					next_counter4=counter4_r + 2;
					//sha_nxt <=1;
					//execute_sha <= 1;
				end 
				else if (counter4_r < 9) begin
					sha_nxt = 1;
					sha_blk={store_r[counter4_r+1],store_r[counter4_r]};
					next_counter4= counter4_r + 2;
				end 
				else begin
					next_execute_sha=1;
				end 
					
				if (execute_sha_r ==1 ) begin
					next_sha_int =1;
					if (sha_rd == 1 && sha_dig_v == 1) begin
						next_temp = sha_dig;
						next_state=CHIPIDGENERATION4_PRE0;
						next_sha_int=0;
						next_ctr_rst=0;
					end 
					
					//execute_sha<=0;
					//ctr_rst<=1;
				end  
				
			end 
			CHIPIDGENERATION4_PRE0: begin
				sha_nxt=0;
				next_counter4=0;
				next_counter3=0;
				next_ctr_rst = 0;
				next_state = CHIPIDGENERATION4_PRE1;
			end 
			CHIPIDGENERATION4_PRE1 : begin
				sha_slt=1'b1;
                next_state=CHIPIDGENERATION4;
                next_proc_part=2'b0;
				next_ctr_rst = 1;
			end 
			CHIPIDGENERATION4 : begin
			// This state is responsible for encrypting the Composite IP IDs 
					next_ctr_rst=0; ///////////////////
				if(proc_part_r == 0) begin
				
					next_data_in=temp_r[255:128];
					enc_dec=1;
					next_data_rdy=1;
					//next_key = cam_key;
					k_len=2'b10;
					next_key_rdy=1;
					if(key_acq==1) begin
						next_key_rdy=0;
					end
					if(output_rdy ==1) begin
						next_enc_temp[255:128]=data_out;
						next_proc_part=1;
						next_ctr_rst=1;
					end      
				end
				else if(proc_part_r==1) begin
					next_ctr_rst=0;
					next_data_in=temp_r[127:0];
					enc_dec=1;
					next_data_rdy=1;
					//next_key = cam_key;
					k_len=2'b10;
					next_key_rdy=1;
					if(key_acq==1) begin
						next_key_rdy=0;
					end
					if(output_rdy ==1) begin
						next_proc_part=1'b0;
						next_enc_temp[127:0]=data_out;
						//end_state_3<=1;
						next_state=CALLBACK1;
						next_key_rdy=0;
						next_data_rdy=0;
						next_ctr_rst=1;
						next_sha_int=0;
						next_store_val=0;
						next_counter=0;
						next_execute_sha=0;
						do_sha=0;
						end_storing=0;
					end 
				end   
			end
			CALLBACK1 : begin
				if (call_back_r == 'b00) begin
					if (call_back1_r == 'b0) begin
						next_enc_composite_ip_id = enc_temp_r;
						//next_state = CHIPIDGENERATION2; use for watermarking
						next_state = MANUFACTURETESTREG_START; 
						next_call_back1 = 'b1;
					end 
					else if (call_back1_r == 'b1) begin
						enc_watermark = enc_temp_r;
						next_state=LIFECYCLE_CALLBACK;
						
						next_read = 0;
						next_write = 1;
						next_RW_initiate =1;
						next_data = enc_temp_r;
						next_mem_address = 'h04;
					end 
				end 
				else begin
					next_enc_composite_ip_id = enc_temp_r;
					next_state = LIFECYCLE_CALLBACK;
				end 
			end 
			LIFECYCLE_CALLBACK : begin
			
				next_RW_initiate = 0;
				
				if (call_back_r == 'b00) begin
					next_state=MANUFACTURETESTREG_START;
				end
				else if (call_back_r == 'b01) begin
					next_state = CHIPID_AUTH;
				end 
				else if (call_back_r == 'b10) begin
					next_state = FW_CHIPID;
					next_counterA = 'h0;
				end 
				else if (call_back_r == 'b11) begin
					next_state = RECALL_WAIT;
				end 
			end 
			MANUFACTURETESTREG_START : begin 
				next_RW_initiate = 0;
				//Registering Sentry Silicon ID and Composite IP ID on AMI
					if (counterA_r < 1) begin
						next_fsm_ami = EncSentrySiliconID_r;
						next_counterA = counterA_r + 1;
					end
					else if (counterA_r == 1) begin
						next_fsm_ami = enc_composite_ip_id_r;
						next_counterA = counterA_r + 1;
						next_state = MANUFACTURETEST1_WAIT; 
					end 
			end 
			MANUFACTURETEST1_WAIT : begin
				// This state will wait for an acknowledge signal from AMI 
				//EncSentrySiliconID = 'h0;
				//enc_composite_ip_id = 'h0;
				next_RW_initiate = 0;
				
				if (ami_ack == 'b100) begin // If the packet is 'b100 that means AMI communication was successful
					// proceed with registration of other assets as needed
					next_state = MANUFACTURETESTREG_ASSETS;
					next_counterA = 0;
				end 
			end
			MANUFACTURETESTREG_ASSETS : begin
			// These set of states are responsible for reading assets from memory and later encrypting them 
				next_fsm_ami =0;
				if (counterA_r < 8) begin 
					next_RW_initiate =0;
					if (served == 1) begin
						next_read = 1;
						next_write=0;
						next_RW_initiate = 1;
						mem_enable = 1;
						next_mem_address = counterA_r; 
						next_state = ASSET_FETCH;
						next_counter = 0;
						next_proc_part=2'b0;
					end 
				end 
				else begin
					next_state = MANUFACTURETESTREG_ASSETS_WAIT;
				end  
			end 
			ASSET_FETCH : begin
				if (served == 1) begin
					next_counter = counter_r + 1;
					if (counter_r > 0) begin
						next_counterA = counterA_r + 1;
						next_temp = mem_data_out;
						next_state = ASSET_ENC;
						next_proc_part=2'b0;
						next_ctr_rst =1;
					end 
				end 
			end 
			ASSET_ENC : begin
				next_counter = 'h0;
					next_ctr_rst=0; ///////////////////
				if(proc_part_r == 0) begin
				
					next_data_in=temp_r[255:128];
					enc_dec=1;
					next_data_rdy=1;
					//next_key = cam_key;
					k_len=2'b10;
					next_key_rdy=1;
					if(key_acq==1) begin
						next_key_rdy=0;
					end
					if(output_rdy ==1) begin
						next_enc_temp[255:128]=data_out;
						next_proc_part=1;
						next_ctr_rst=1;
					end      
				end
				else if(proc_part_r==1) begin
					next_ctr_rst=0;
					next_data_in=temp_r[127:0];
					enc_dec=1;
					next_data_rdy=1;
					//next_key = cam_key;
					k_len=2'b10;
					next_key_rdy=1;
					if(key_acq==1) begin
						next_key_rdy=0;
					end
					if(output_rdy ==1) begin
						next_proc_part=1'b0;
						next_enc_temp[127:0]=data_out;
						//end_state_3<=1;
						next_state=MANUFACTURETESTREG_ASSETS_WAIT;
						next_key_rdy=0;
						next_data_rdy=0;
						next_ctr_rst=1;
						next_sha_int=0;
						next_store_val=0;
						next_counter=0;
						next_execute_sha=0;
						do_sha=0;
						end_storing=0;
						
						
					end 
				end
			end 
			MANUFACTURETESTREG_ASSETS_WAIT : begin
			// After Encryption, the FSM will register the asset with AMI and will send an ACK packet 
				next_RW_initiate = 0;
				if (counterA_r < 8) begin
					next_fsm_ami = enc_temp_r;
					if (ami_ack == 'b100) begin
						next_state = MANUFACTURETESTREG_ASSETS; 
					end 
				end 
				else begin 
					next_state =MANUFACTURETEST2; 
					next_counterA= 0;
				end 
			end 
			MANUFACTURETEST2 : begin
			//save lifecycle state storage on chip memory (changing the lifecycle state to Manufacture and Test)
				if (counterA_r < 1) begin
					
					next_data = 'h01;
					next_write = 1;
					next_read = 0;
					next_RW_initiate = 1;
					next_mem_address = 'h07;
					mem_enable = 1;
					next_counterA = counterA_r + 1;
				end 
				else begin
					//register lifecycle state with AMI
					next_RW_initiate = 0;
					next_state = MANUFACTURETEST3_WAIT;
				end 
			end 
			MANUFACTURETEST3_WAIT : begin
				// wait for AMI ack
				next_RW_initiate = 0;
				next_fsm_ami = 'h01;
				if (ami_ack == 'b100) begin
					next_state = MANUFACTURETEST_BOOT;
					next_fsm_ami = 'h0;
					next_reg_access = 1;
					next_reg_packet= {6'h0,  32'h1, 1'b0,  3'b000, 20'b0, `GPIO_ODATA, 2'b0, 7'b0, 1'b1};
					
					next_RW_initiate = 1;
					next_write = 1;
					next_read = 0;
					next_mem_address = 'h7;
					next_data = 4'b1001;
				end 
			end 
			MANUFACTURETEST_BOOT : begin
				next_RW_initiate = 0;
				next_reg_access = 1;
				next_reg_packet= {6'h0,  32'h0, 1'b0,  3'b000, 20'b0, `GPIO_ODATA, 2'b0, 7'b0, 1'b1};
				next_state = MANUFACTURETEST_BOOTED;
			end 
			MANUFACTURETEST_BOOTED : begin
				//taking in jtag input for lifecycle transition or authentication of other assets
				next_RW_initiate = 0;
				next_reg_access = 0;
				next_reg_packet= {6'h0,  32'h0, 1'b0,  3'b000, 20'b0, `GPIO_ODATA, 2'b0, 7'b0, 1'b0};
				//simulating a jtag input, unsure about acutal functionality. using 010 for lifecycle transition request with next 3 bits as lifecycle state
				//code for other jtag functionality also goes here. This can be changed as needed. 
				if (jtag_in[2:0] == 3'b010) begin 
					if (jtag_in[5:3] == 3'b010) begin
						next_data = jtag_in[5:3];
						next_write = 1;
						next_read = 0;
						next_RW_initiate = 1;
						next_mem_address = 'h07;
						mem_enable = 1;
						next_state = MANUFACTURETEST5;
					end 
				end 
			end
			MANUFACTURETEST5 : begin
				// register new lifecycle state with AMI and then go back to boot state to go into the next lifecycle
				next_RW_initiate = 0;
				
				next_state = MANUFACTURETEST5_WAIT;
				
				next_countertemp=1;
			end
			MANUFACTURETEST5_WAIT : begin
				// wait for AMI ack
				next_RW_initiate = 0;
				next_fsm_ami = 'h02;
				if (ami_ack == 'b100) begin
					next_fsm_ami = 'h0;
					next_state = BOOT_START;
					next_reg_access = 1;
					next_reg_packet= {6'h0,  32'h2, 1'b0,  3'b000, 20'b0, `GPIO_ODATA, 2'b0, 7'b0, 1'b1};
				end 
			end 
			OEM_START : begin
				next_state = OEM_START;
			
				//go to chip id generation states, once finished, return to CHIPID_AUTH which is done using call_back register 
				next_state = CHIPIDGENERATION;	
				next_RW_initiate = 0;
				next_call_back = 'b01;
				next_fsm_ami = 0;
				next_counterA=0;
				next_ctr_rst = 1;
			end
			CHIPID_AUTH : begin
				//Send SentrySiliconID and CompositeIPID for AMI for authentication 
				if (counterA_r < 1) begin
					next_fsm_ami = EncSentrySiliconID_r;
					next_counterA = counterA_r + 1;
				end
				else if (counterA_r == 1) begin
					next_fsm_ami = enc_composite_ip_id_r;
					next_counterA = 0;
					next_state = LIFECYCLEAUTH;
				end 		
			end 
			LIFECYCLEAUTH : begin
				next_fsm_ami = 'h0;
				if (counterA_r == 0) begin
					if (served == 1) begin
						// Authenticate Lifecycle
						next_data = 'h0;
						next_write = 0;
						next_read = 1;
						next_RW_initiate = 1;
						next_mem_address = 'h07;
						next_counterA = counterA_r + 1;
					end 
				end 
				else if (counterA_r == 1) begin
					if (served == 1) begin
						next_counterA = counterA_r + 1;
					end 
				end 
				else if (counterA_r > 1) begin
					if (served == 1) begin
						mem1 = mem_data_out; 
						next_state = ENCRYPTION;
						next_proc_part = 0;
						next_call_back1 = 'b00;
						next_ctr_rst = 1;
					end 
				end 
				
			end 
			CHIPID_LC_AUTH_WAIT : begin 
				// wait for AMI 
				next_RW_initiate = 0;
				next_counterA = 0;
				// if authentication passes, proceed to currownerid fetch, if not, abort
				if (ami_ack == 'b100) begin
					next_state = CURROWNID_FETCH;
					next_fsm_ami = 'h0;
				end 
				else if (ami_ack == 'b010) begin
					next_state = ABORT;
					next_fsm_ami = 'h0;
				end 
			end
			CURROWNID_FETCH : begin
			next_ctr_rst = 1;
				if (served == 1) begin
					next_read = 1;
					next_RW_initiate = 1;
					next_mem_address = 'h03;
					next_state = CURROWNID_FETCH1;
				end 
			end 
			CURROWNID_FETCH1 : begin
				next_RW_initiate = 0;
				if (counterA_r < 1) begin
					if (served == 1) begin 
						next_counterA = counterA_r + 1;
						next_ctr_rst = 0;
					end 
				end 
				else begin
					if (served == 1) begin 
						mem1 = mem_data_out;
						next_state = ENCRYPTION;
						next_proc_part = 0;
						next_call_back1 = 'b01;
						next_ctr_rst =1;
					end 
				end 
			end 
			ENCRYPTION : begin
			// This state encrypts the Current Owner ID or any other assets will later be authenticated by AMI 
				next_RW_initiate = 0;
				next_ctr_rst=0; ///////////////////
				if(proc_part_r == 0) begin
					
						next_data_in=mem1_r[255:128];
						enc_dec=1;
						next_data_rdy=1;
						//next_key = cam_key;
						k_len=2'b10;
						next_key_rdy=1;
						if(key_acq==1) begin
							next_key_rdy=0;
						end
						if(output_rdy ==1) begin
							mem2[255:128]=data_out;
							next_proc_part=1;
							next_ctr_rst=1;
						end     
					end
					else if(proc_part_r==1) begin
						next_ctr_rst=0;
						next_data_in=mem1_r[127:0];
						enc_dec=1;
						next_data_rdy=1;
						//next_key = cam_key;
						k_len=2'b10;
						next_key_rdy=1;
					if(key_acq==1) begin
						next_key_rdy=0;
					end
					if(output_rdy ==1) begin
						next_proc_part=1'b0;
						mem2[127:0]=data_out;
						//end_state_3<=1;
						next_state=ENCRYPTION_CALLBACK;
						next_key_rdy=0;
						next_data_rdy=0;
						next_ctr_rst=1;
						next_sha_int=0;
						next_store_val=0;
						next_counter=0;
						next_execute_sha=0;
						do_sha=0;
						end_storing=0;
						next_counterA=0;
					end
				end 
			end 
			ENCRYPTION_CALLBACK : begin
				if (call_back1_r == 'b000) begin
					next_state = CHIPID_LC_AUTH_WAIT ;
					next_fsm_ami = mem2_r; 
				end 
				else if (call_back1_r == 'b001) begin
					next_state = CURROWNID_AUTH;
					next_fsm_ami = mem2_r;
				end 
				else if (call_back1_r == 'b010) begin
					next_state = OEM_AMI_AUTH;
					next_fsm_ami = mem2_r;
				end 
				else if (call_back1_r == 'b011) begin
					next_state = LCTRANSITION_AUTH;
					next_fsm_ami = mem2_r;
				end 
				else if (call_back1_r == 'b100) begin
					next_state = LCTRANSITION_AUTH;
					next_fsm_ami = mem2_r; 
				end 
				else if (call_back1_r == 'b101) begin
					next_state = RECALL_CURROWN_AUTH;
					next_fsm_ami = mem2_r; 
				end 
				else if (call_back1_r == 'b110) begin
					next_state = RECALL_LCTRANSITION_AUTH;
					next_fsm_ami = mem2_r;
				end 
				else if (call_back1_r == 'b111) begin
					next_state = RECALL_AMI_AUTH;
					next_fsm_ami = mem2_r;
				end 
			end 
			CURROWNID_AUTH : begin
					
				if (ami_ack == 3'b100) begin
					if (call_back2_r == 'b0) begin
						next_state = OEM_BOOT;
						next_fsm_ami = 'h0;
						next_reg_access = 1;
						next_reg_packet= {6'h0,  32'h1, 1'b0,  3'b000, 20'b0, `GPIO_ODATA, 2'b0, 7'b0, 1'b1};
						
						next_RW_initiate = 1;
						next_write = 1;
						next_read = 0;
						next_mem_address = 'h7;
						next_data = 4'b1010;
					end 
					else if (call_back2_r == 'b1) begin
						next_state = RECALL_BOOT;
						next_fsm_ami = 'h0;
						
						next_RW_initiate = 1;
						next_write = 1;
						next_read = 0;
						next_mem_address = 'h7;
						next_data = 4'b1100;
					end 
				end
				else if (ami_ack == 3'b010) begin
					next_state = ABORT;
					next_fsm_ami = 'h0;
				end 
			end 
			OEM_BOOT : begin
				next_RW_initiate =0;
				next_reg_access = 1;
				next_reg_packet= {6'h0,  32'h0, 1'b0,  3'b000, 20'b0, `GPIO_ODATA, 2'b0, 7'b0, 1'b1};
				next_state = OEM_BOOTED;
			end 
			OEM_BOOTED : begin
				next_reg_access = 0;
				next_reg_packet= {6'h0,  32'h0, 1'b0,  3'b000, 20'b0, `GPIO_ODATA, 2'b0, 7'b0, 1'b0};
				// wait for JTAG input to trigger a lifecycle transition or AMI to authenticate other asset
				if (jtag_in[2:0] == 3'b010) begin 
					if (jtag_in[5:3] == 3'b011) begin
						next_data = jtag_in[5:3];
						next_write = 1;
						next_read = 0;
						next_RW_initiate = 1;
						next_mem_address = 'h07;
						mem_enable = 1;
						//next_state= MANUFACTURETEST5;  
						next_state = KEY_FETCH1;
						next_counterA = 'h0;
						next_call_back1 = 'b11;
						mem1 = jtag_in[5:3];
						//next_ctr_rst = 1;
						//enc_dec = 0;
					end 
				end 
				else if (ami_out[5:3] == 3'b100) begin
					if ((ami_out[2:0] == 3'b110) || (ami_out[2:0] == 3'b101) || (ami_out[2:0] == 3'b100)) begin //system integrator id, chipmanufacturer id, composite watermark
						next_write = 0;
						next_read = 1;
						next_mem_address = ami_out[2:0];
						next_RW_initiate = 1;
						next_state = MEM_FETCH;
						next_counterA = 0;
						next_call_back1 = 'b10;
					end
				end 
			end 
			MEM_FETCH : begin
				next_RW_initiate = 0;
				if (counterA_r < 1) begin
					if (served == 1) begin 
						next_counterA = counterA_r + 1;
						next_ctr_rst = 1;
					end 
				end 
				else begin
					if (served == 1) begin 
						mem1 = mem_data_out;
						next_state = KEY_FETCH1;
						next_proc_part = 0;
						next_ctr_rst =1;
					end 
				end 
			end 
			KEY_FETCH1 : begin
				if (served == 1) begin
					next_data = 'h0;
					next_write = 0;
					next_read = 1;
					mem_enable = 1;
					next_mem_address = 'h01;
					next_RW_initiate = 1;
					next_state = KEY_WAIT1;
				end
			end
			KEY_WAIT1 : begin
				if (counterA_r < 1) begin
					if (served == 1) begin 
						next_counterA = counterA_r + 1;
					end 
				end 
				else begin
					if (served == 1) begin 
						next_counterA = 0;
						next_key = mem_data_out;
						next_state = ENCRYPTION;
						next_ctr_rst = 1;
					end 
				end 
			end
			OEM_AMI_AUTH : begin
				if (ami_ack == 'b100) begin
					next_state = OEM_BOOTED;
				end 
				else if (ami_ack == 'b010) begin
					next_state = ABORT;
				end 
			end 	
			ABORT : begin
				next_state = ABORT;
			end
			DEPLOYMENT_START : begin
				
				
				next_RW_initiate = 1;
				next_mem_address = 'h7;
				next_data = 'b1011;
				next_write=1;
				next_read=0;
				
				if (counterA_r < 1) begin
					next_reg_access = 1;
					next_reg_packet= {6'h0,  32'h1, 1'b0,  3'b000, 20'b0, `GPIO_ODATA, 2'b0, 7'b0, 1'b1};
					//next_state = DEPLOYMENT_BOOTED;
					next_counterA = 1;
				end 
				else begin
					next_reg_access = 1;
					next_reg_packet= {6'h0,  32'h0, 1'b0,  3'b000, 20'b0, `GPIO_ODATA, 2'b0, 7'b0, 1'b1};
					next_state = DEPLOYMENT_BOOTED;
					next_counterA = 0;
					
				end
				
			end 
			DEPLOYMENT_BOOTED : begin 
			next_RW_initiate = 0;
			next_reg_access = 1;
			next_reg_packet= {6'h0,  32'd0, 1'b0,  3'b000, 20'b0, `GPIO_IDATA, 2'b0, 7'b0, 1'b0};
				// Waits for jtag input for lifecycle transition 
				if (jtag_in[2:0] == 3'b010) begin 
					if (jtag_in[5:3] == 3'b100) begin			
						next_data = jtag_in[5:3];
						next_write = 1;
						next_read = 0;
						next_RW_initiate = 1;
						next_mem_address = 'h07;
						mem_enable = 1;
						//next_state= MANUFACTURETEST5;  
						next_state = KEY_FETCH1;
						next_counterA = 'h0;
						next_call_back1 = 'b100; //////////////
						mem1 = jtag_in[5:3];
					end 
				end 
				else if (fw_instruction == 3'b001) begin
					enc_dec = 0;
					//encrypted_fw;
					next_call_back = 'b10;
					next_state = CHIPIDGENERATION;
					
					sha_slt=1'b1;
					next_ctr_rst=1;
					enc_dec = 0;
				end
			end
			FW_DECRYPTION : begin
				fw_chipid_rdy=0;
				enc_dec=0;
				next_RW_initiate = 0;
				next_ctr_rst=0; ///////////////////
				if(proc_part_r == 0) begin
					
						next_data_in=encrypted_fw[255:128];
						//enc_dec=0;
						next_data_rdy=1;
						//next_key = cam_key;
						k_len=2'b10;
						next_key_rdy = 1;
						if(key_acq==1) begin
							next_key_rdy=0;
						end
						if(output_rdy ==1) begin
							mem2[255:128]=data_out;
							next_proc_part=1;
							next_ctr_rst=1;
						end     
					end
					else if(proc_part_r==1) begin
						next_ctr_rst=0;
						next_data_in=encrypted_fw[127:0];
						enc_dec=0;
						next_data_rdy=1;
						//next_key = cam_key;
						k_len=2'b10;
						next_key_rdy=1;
					if(key_acq==1) begin
						next_key_rdy=0;
					end
					if(output_rdy ==1) begin
						next_proc_part=1'b0;
						mem2[127:0]=data_out;
						//end_state_3<=1;
						next_state=FW_AUTH;
						next_key_rdy=0;
						next_data_rdy=0;
						next_ctr_rst=1;
						next_sha_int=0;
						next_store_val=0;
						next_counter=0;
						next_execute_sha=0;
						do_sha=0;
						end_storing=0;
						next_counterA=0;
						
						next_counter4 = 0;
					end
				end 
			end 
			FW_AUTH : begin
				fw_fsm_out = mem2_r; 
				fw_expected_hash_rdy=1;
				if (fw_instruction == 3'b100) begin
					next_state = UPGRADE_FW;
					fw_expected_hash_rdy=0;
					fw_fsm_out='h0;
					next_counter3 = 'h0;
				end 
				else if (fw_instruction == 3'b010) begin
					next_state = DEPLOYMENT_BOOTED;
					fw_expected_hash_rdy=0;
					fw_fsm_out='h0;
				end 
			end 
			FW_CHIPID : begin
				fw_chipid_rdy = 1;
				if (counterA_r < 1) begin
					fw_fsm_out = EncSentrySiliconID_r;
					next_counterA = 1;
				end 
				else begin
					fw_fsm_out = enc_composite_ip_id_r;
					next_state = FW_DECRYPTION;
					next_ctr_rst = 1;
					next_proc_part = 0;
				end
			end 
			UPGRADE_FW : begin
				next_reg_access = 1;
				next_ctr_rst = 0;
				case (counterA_r)
					'h0 : begin
						next_reg_packet= {6'h0,  32'b00100000, 1'b0,  3'b000, 20'b0, `GPIO_ODATA, 2'b0, 7'b0, 1'b1};
						next_counterA = 1;
						next_counter3 = 0;
					end 
					'h1 : begin 
						next_reg_packet= {6'h0,  32'b00000000, 1'b0,  3'b000, 20'b0, `GPIO_ODATA, 2'b0, 7'b0, 1'b1};
						next_counterA = counterA_r + 1;
					end 
					'h2 : begin
						next_reg_packet = {6'h0,  32'b0000000, 1'b0,  3'b000, 20'b0, `GPIO_IDATA, 2'b0, 7'b0, 1'b0};
						
						if (reg_rdata[6] == 1'b1) begin
							next_counterA = counterA_r + 1;
							next_reg_packet= {6'h0,  32'b10000000, 1'b0,  3'b000, 20'b0, `GPIO_ODATA, 2'b0, 7'b0, 1'b1};
							//next_upgrade_fw_flag = 1;
						end 
					end 
					'h3 : begin 
						next_counterA = counterA_r + 1;
					end 
					'h4 : begin
						case (counter3_r) 
							'h0 : begin 
								//ahb_I_go = 
							end 
							'h1 : begin
							
							end
						endcase
						/*
						case (counter3_r) 
							'h0 : begin
								ta2_bus = mem2_r[255:224];
								next_counter3 = counter3_r + 1;
							end 
							'h1 : begin 
								ta2_bus = mem2_r[223:192];
								next_counter3 = counter3_r + 1;
							end 
							'h2 : begin
								ta2_bus = mem2_r[191:160];
								next_counter3 = counter3_r + 1;
							end 
							'h3 : begin
								ta2_bus = mem2_r[159:128];
								next_counter3 = counter3_r + 1;
							end 
							'h4 : begin
								ta2_bus = mem2_r[127:96];
								next_counter3 = counter3_r + 1;
							end 
							'h5 : begin
								ta2_bus = mem2_r[95:64];
								next_counter3 = counter3_r + 1;
								
							end 
							'h6 : begin
								ta2_bus = mem2_r[63:32];
								next_counter3 = counter3_r + 1;
								next_reg_packet= {6'h0,  32'b00000000, 1'b0,  3'b000, 20'b0, `GPIO_ODATA, 2'b0, 7'b0, 1'b1};
							end 
							'h7 : begin
								ta2_bus = mem2_r[31:0];
								next_counter3 = counter3_r + 1;
								next_state = DEPLOYMENT_BOOTED;
							end 
						endcase 
						*/
					end 
					
				endcase
			end 
			LCTRANSITION_AUTH : begin
				next_RW_initiate = 0;
				
				if (ami_ack == 'b100) begin
					next_fsm_ami = 'h0;
					next_state = BOOT_START;
					next_reg_access = 1;
					next_reg_packet= {6'h0,  32'h2, 1'b0,  3'b000, 20'b0, `GPIO_ODATA, 2'b0, 7'b0, 1'b1};
				end
				else if (ami_ack == 'b010) begin
					next_fsm_ami = 'h0;
					next_state = ABORT;
				end 
			end 
			RECALL_START : begin
				next_state = CHIPIDGENERATION;
				next_call_back = 'b01;
				next_call_back1 = 'b101;
				next_call_back2 = 'b1;
			end 
			RECALL_BOOT : begin
				if (counterA_r == 'h0) begin
					next_reg_access = 1;
					next_reg_packet= {6'h0,  32'h1, 1'b0,  3'b000, 20'b0, `GPIO_ODATA, 2'b0, 7'b0, 1'b1};
					next_counterA = 'h1;
				end 
				else begin
					next_reg_access = 1;
					next_reg_packet= {6'h0,  32'h0, 1'b0,  3'b000, 20'b0, `GPIO_ODATA, 2'b0, 7'b0, 1'b1};
					next_state = RECALL_BOOTED;
				end 
				
			end 
			RECALL_BOOTED : begin
				next_reg_access = 0;
				next_reg_packet= {6'h0,  32'd0, 1'b0,  3'b000, 16'b0, 24'b0, `GPIO_IDATA, 2'b0, 7'b0, 1'b0};
				if (jtag_in[2:0] == 3'b010) begin 
					if (jtag_in[5:3] == 3'b101) begin			
						next_data = jtag_in[5:3];
						next_write = 1;
						next_read = 0;
						next_RW_initiate = 1;
						next_mem_address = 'h07;
						mem_enable = 1;
						next_state = KEY_FETCH1;
						next_counterA = 'h0;
						next_call_back1 = 'b110; 
						mem1 = jtag_in[5:3];
						next_ctr_rst=1;
						next_proc_part=0;
					end 
				end 
				else if (ami_out[5:3] == 3'b100) begin
					if ((ami_out[2:0] == 3'b110) || (ami_out[2:0] == 3'b101) || (ami_out[2:0] == 3'b100)) begin
						next_write = 0;
						next_read = 1;
						next_mem_address = ami_out[2:0];
						next_RW_initiate = 1;
						next_state = MEM_FETCH;
						next_counterA = 0;
						next_call_back1 = 'b111;
					end
				end 
			end 
			RECALL_LCTRANSITION_AUTH : begin
				next_RW_initiate = 0;
				
				if (ami_ack == 'b100) begin
					next_fsm_ami = 'h0;
					next_state = BOOT_START;
					next_reg_access = 1;
					next_reg_packet= {6'h0,  32'h2, 1'b0,  3'b000, 20'b0, `GPIO_ODATA, 2'b0, 7'b0, 1'b1};
				end
				else if (ami_ack == 'b010) begin
					next_fsm_ami = 'h0;
					next_state = ABORT;
				end
			end 	
			RECALL_AMI_AUTH : begin
				if (ami_ack == 'b100) begin
					next_state = RECALL_BOOTED;
				end 
				else if (ami_ack == 'b010) begin
					next_state = ABORT;
				end 
			end 
			EOF_START : begin // clear from ami
				if (counterA_r < 8) begin
					next_RW_initiate = 1;
					next_mem_address = counterA_r;
					next_write = 1;
					next_read = 0;
					next_data = 'h0;
					next_counterA = counterA_r + 1;
				end 
			end 
		endcase
	end

endmodule