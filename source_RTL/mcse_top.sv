module mcse_top # (
    parameter pcm_data_width = 32,
    parameter pcm_addr_width = 32,
    parameter puf_sig_length = 256,
    parameter gpio_N = 32,
    parameter gpio_AW = 32,
    parameter gpio_PW = 2*gpio_AW+40
)
(
    input                 clk,
    input                 rst,
    input                 init_config, // temporary for simulation 
	input  [gpio_N-1:0]   gpio_in,

    input  [255:0]        lc_transition_id,
    input                 lc_transition_request_in,
    input  [255:0]        lc_authentication_id,
    input                 lc_authentication_valid, 

	output [gpio_N-1:0]   gpio_out
);

    // Camellia Inputs 
    wire [127:0]              cam_data_in;
    wire [255:0]              cam_key;
    wire [0:1]                cam_k_len;
    wire                      cam_enc_dec;
    wire                      cam_data_rdy;
    wire                      cam_key_rdy;
    // Camellia Outputs
    wire [127:0]              cam_data_out;
    wire                      cam_data_acq;
    wire                      cam_key_acq;
    wire                      cam_output_rdy;
    wire [255:0]              cam_puf_out;

    // SHA Inputs
    wire [511:0]              sha_block;
    wire                      sha_init;
    wire                      sha_next;
    wire                      sha_sel;
    // SHA Outputs
    wire [255:0]              sha_digest;
    wire                      sha_ready;
    wire                      sha_digest_valid;
    wire [255:0]              sha_puf_out;

    // GPIO Inputs 
    wire                      gpio_reg_access;
    wire [gpio_PW-1:0]        gpio_reg_packet;
    //GPIO Outputs
    wire [gpio_N-1:0]         gpio_reg_rdata;
    wire [gpio_N-1:0]         gpio_en;
    wire                      gpio_irq;
    wire [gpio_N-1:0]         gpio_ilat;   

    // PCM Inputs
    wire [puf_sig_length-1:0] pcm_sig_in;
    wire [pcm_data_width-1:0] pcm_IP_ID_in;
    wire [2:0]                pcm_instruction_in;
    wire                      pcm_sig_valid;
    // PCM Outputs
    wire [pcm_data_width-1:0] pcm_control_out;
    wire [pcm_data_width-1:0] pcm_status;
    wire                      pcm_comp_out;
    wire                      pcm_S_c;
    wire                      pcm_A_c;

    min_security_module #(
    .data_width(pcm_data_width), .addr_width(pcm_addr_width), .puf_sig_length(puf_sig_length), .N(gpio_N),
    .AW(gpio_AW), .PW(gpio_PW)) 
    min_sec (
    .clk(clk), .rst(~rst),
    .data_in(cam_data_in), .key(cam_key), .key_rdy(cam_key_rdy), .k_len(cam_k_len), .enc_dec(cam_enc_dec),.data_rdy(cam_data_rdy), .data_out(cam_data_out),
    .data_acq(cam_data_acq), .key_acq(cam_data_acq), .output_rdy(cam_output_rdy), .cam_pufout(cam_puf_out),

    .sha_block(sha_block), .sha_init(sha_init), .sha_next(sha_next), .sha_sel(sha_sel), .sha_digest(sha_digest), .sha_ready(sha_ready),
    .sha_digest_valid(sha_digest_valid), .sha_pufout(sha_puf_out),

    .reg_access(gpio_reg_access), .gpio_in(gpio_in), .reg_packet(gpio_reg_packet), .reg_rdata(gpio_reg_rdata), .gpio_out(gpio_out),
    .gpio_en(gpio_en), .gpio_irq(gpio_irq), .gpio_ilat(gpio_ilat),

    .sig_in(pcm_sig_in), .IP_ID_in(pcm_IP_ID_in), .Instruction_in(pcm_instruction_in), .sig_valid(pcm_sig_valid), .control_out(pcm_control_out),
    .status(pcm_status), .comp_out(pcm_comp_out), .S_c(pcm_S_c), .A_c(pcm_A_c)
    ); 

    mcse_control_unit #(.pcm_data_width(pcm_data_width), .pcm_addr_width(pcm_addr_width), .puf_sig_length(puf_sig_length), .gpio_N(gpio_N),
    .gpio_AW(gpio_AW), .gpio_PW(gpio_PW)) control_unit (.*);

endmodule