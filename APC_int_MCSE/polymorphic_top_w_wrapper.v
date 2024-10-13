module polymorphic_top_w_wrapper(word_en, data_in, data_in_valid, clk, reset, core_reset, data_req, sleep_out_aes, 
sleep_out_sha3, data_out_aes, data_out_sha3, data_out_valid_aes, data_out_valid_sha3);

//input
input clk, reset, core_reset;
input data_in, data_in_valid, word_en;

//output
output data_req; 
output sleep_out_sha3, sleep_out_aes;
output data_out_aes, data_out_sha3;
output data_out_valid_aes, data_out_valid_sha3;

//DUT INSTANTS   
wire sleep_in_pipe, ko_pipe_sha3, ko_pipe_aes;
wire data_out_valid_aes_ki, data_out_valid_sha3_ki;
wire ki;
wire [2*612-1:0] data;
wire ki_aes, ki_sha3;
wire [611:0] check_data;
wire [127:0] check_aes_data;
wire [511:0] check_sha3_data;
wire [255:0] a2sdata_aes;
wire [1023:0] a2sdata_sha3;
wire [1023:0] sha3_out_sr;
wire [255:0] aes_out_sr;

// Chooses SHA3 or AES functionality
wire vdd_sel = 1'b0; // 1'b0 for AES, 1'b1 for SHA3
wire vdd_sel_inv = 1'b1; // 1'b1 for AES, 1'b0 for SHA3

// Power and ground
wire VDD = 1'b1;
wire VSS = 1'b0;


//Input wrapper
sync_to_MTD3L_s2p_bit_vector 
	u_input  (.data_in(data_in), .data_in_valid(data_in_valid), .clk(clk), .reset(reset), 
		.word_en(word_en), .data_req(data_req), .ki(ki), .sleep_out(sleep_in_pipe), 
		.s0(), .ns1(), 
		.z(data));

//Polymorphic Core
polymorphic_top 
	I1(.vdd_sel(vdd_sel), .reset(core_reset), .data_in_sr(data), .sleep_in(sleep_in_pipe), 
		.sha3_ki(ki), .sha3_ko(ko_pipe_sha3), .sha3_sleep_out(sleep_out_sha3), .sha3_out_sr(sha3_out_sr), 
		.aes_ki(ki), .aes_out_sr(aes_out_sr), .aes_ko(ko_pipe_aes), .aes_sleep_out(sleep_out_aes));

assign a2sdata_sha3[1023:0] = sha3_out_sr[1023:0]; //sha3
assign a2sdata_aes[255:0] = aes_out_sr[255:0]; //aes

//AES output wrapper
MTD3L_to_sync_p2s_bit_vector_AES 
	aes_output (.data_in(a2sdata_aes), .sleep_in(sleep_out_aes), .ko(ki_aes), .clk(clk), 
		.reset(reset), 
		.ki_b(data_out_valid_aes_ki),
		.data_valid(data_out_valid_aes), .data_out(data_out_aes));	

//SHA3 output wrapper
MTD3L_to_sync_p2s_bit_vector_SHA3 
	sha3_output (.data_in(a2sdata_sha3), .sleep_in(sleep_out_sha3), .ko(ki_sha3), .clk(clk), 
		.reset(reset), 
		.ki_b(data_out_valid_sha3_ki),
		.data_valid(data_out_valid_sha3), .data_out(data_out_sha3));	

//Outputs for valid data
assign data_out_valid_aes_ki = data_out_valid_aes;
assign data_out_valid_sha3_ki = data_out_valid_sha3;

//Ki verify
th22_a Ki_verify (.a(ki_sha3), .b(ki_aes), .z(ki));

endmodule  