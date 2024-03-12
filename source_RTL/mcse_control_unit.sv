module mcse_control_unit #(
    parameter pcm_data_width = 32,
    parameter pcm_addr_width = 32,
    parameter puf_sig_length = 256,
    parameter gpio_N = 32,
    parameter gpio_AW = 32,
    parameter gpio_PW = 2*gpio_AW+40
)
(
    input                      clk,
    input                      rst,
    input                      fuse, 

    // Camellia to Boot Control
    input [127:0]              cam_data_out,
    input                      cam_data_acq,
    input                      cam_key_acq,
    input                      cam_output_rdy,
    input [255:0]              cam_puf_out,

    // SHA to Boot Control
    input [255:0]              sha_digest,
    input                      sha_ready,
    input                      sha_digest_valid,
    input [255:0]              sha_puf_out,

    // GPIO to Boot Control
    input [gpio_N-1:0]         gpio_reg_rdata,
    input [gpio_N-1:0]         gpio_en,
    input                      gpio_irq,
    input [gpio_N-1:0]         gpio_ilat,  

    // PCM to Boot Control
    input [pcm_data_width-1:0] pcm_control_out,
    input [pcm_data_width-1:0] pcm_status,
    input                      pcm_comp_out,
    input                      pcm_S_c,
    input                      pcm_A_c,

    // *** To Boot Control 
    input  [255:0]        lc_transition_id,
    input                 lc_transition_request_in,
    input  [255:0]        lc_authentication_id,
    input                 lc_authentication_valid,     

    // Boot control to Camellia 
    output [127:0]              cam_data_in,
    output [255:0]              cam_key,
    output [0:1]                cam_k_len,
    output                      cam_enc_dec,
    output                      cam_data_rdy,
    output                      cam_key_rdy,

    // Boot control to SHA
    output [511:0]              sha_block,
    output                      sha_init,
    output                      sha_next,
    output                      sha_sel,

    // Boot Control to GPIO 
    output                      gpio_reg_access,
    output [gpio_PW-1:0]        gpio_reg_packet,    

    // Boot Control to PCM 
    output [puf_sig_length-1:0] pcm_sig_in,
    output [pcm_data_width-1:0] pcm_IP_ID_in,
    output [2:0]                pcm_instruction_in,
    output                      pcm_sig_valid


);

    localparam memory_width = 256;
    localparam memory_length = 16;

    wire lc_transition_request;
    wire [255:0] lc_identifier;
    wire lc_success;
    wire lc_done; 
    wire [2:0] lc_state; 
    

    lifecycle_protection lc_protection ( .rst(fuse), .* );

    wire                            rd_en;
    wire                            wr_en;
    wire [$clog2(memory_length)-1:0] addr;
    wire [memory_width-1:0]         wrData;
    wire [memory_width-1:0]         rdData;
    wire                            rdData_valid;
    

    secure_memory #(.WIDTH(memory_width), .LENGTH(memory_length) ) mem (.rst(fuse), .*);

    secure_boot_control #(.pcm_data_width(pcm_data_width), .pcm_addr_width(pcm_addr_width), .puf_sig_length(puf_sig_length), 
    .gpio_N(gpio_N), .gpio_AW(gpio_AW), .gpio_PW(gpio_PW),
    .memory_width(memory_width), .memory_length(memory_length)) secure_boot ( .* );


endmodule 