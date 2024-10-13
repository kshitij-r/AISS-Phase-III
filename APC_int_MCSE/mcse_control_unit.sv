`include "mcse_def.svh"
module mcse_control_unit #(
    parameter pcm_data_width        = 32,
    parameter pcm_addr_width        = 32,
    parameter puf_sig_length        = 256,
    parameter gpio_N                = 32,
    parameter gpio_AW               = 32,
    parameter gpio_PW               = 2*gpio_AW+40,
    parameter ipid_N                = `IPID_N,
    parameter ipid_width            = `IPID_WIDTH,
    parameter fw_image_N            = `FW_N,
    parameter fw_block_width        = `FW_WIDTH,
    parameter scan_key_width        = `SCAN_KEY_WIDTH,
    parameter scan_key_number       = `SCAN_KEY_NUMBER,
    parameter pAHB_ADDR_WIDTH       = 32,
    parameter pPAYLOAD_SIZE_BITS    = 128

)
(
    input                      clk,
    input                      rst_n,
    input                      init_config_n, 
    


    // Camellia to Boot Control
    input [127:0]              cam_data_out,
    input                      cam_data_acq,
    input                      cam_key_acq,
    input                      cam_output_rdy,
    input [255:0]              cam_puf_out,

    // APC to Boot Control
    input                      apc_data_req,
    input                      apc_sleep_out_aes,
    input                      apc_data_out_valid_aes,
    input                      apc_data_out_aes,

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
    /*
    input [pcm_data_width-1:0] pcm_control_out,
    input [pcm_data_width-1:0] pcm_status,
    input                      pcm_comp_out,
    input                      pcm_S_c,
    input                      pcm_A_c,
    */
    input [puf_sig_length-1:0]      pcm_puf_out,
    input                           pcm_puf_out_valid,
    input                           pcm_S_c,

    // *** To Boot Control 
    input  [255:0]        lc_transition_id,
    input                 lc_transition_request_in,
    input  [255:0]        lc_authentication_id,
    input                 lc_authentication_valid,     

    // Bus Translation unit to Boot control 
    input                           bootControl_bus_done,
    input [pPAYLOAD_SIZE_BITS-1:0]  bootControl_bus_rdData,

    // *** To Vimscan
    input [scan_key_width-1:0]      scan_key,

    // Boot control to Camellia 
    output [127:0]                  cam_data_in,
    output [255:0]                  cam_key,
    output [0:1]                    cam_k_len,
    output                          cam_enc_dec,
    output                          cam_data_rdy,
    output                          cam_key_rdy,

    // Boot Control to APC
    output                          core_reset,
    output                          apc_data_in,
    output                          apc_data_in_valid,
    output                          apc_word_en,

    // Boot control to SHA
    output logic [511:0]                  sha_block,
    output logic                          sha_init,
    output logic                         sha_next,
    output logic                          sha_sel,

    // Boot Control to GPIO 
    output                          gpio_reg_access,
    output [gpio_PW-1:0]            gpio_reg_packet,   

    // Vimscan to ***
    output logic                    scan_unlock, 

    // Boot Control to PCM 
    /*
    output [puf_sig_length-1:0]     pcm_sig_in,
    output [pcm_data_width-1:0]     pcm_IP_ID_in,
    output [2:0]                    pcm_instruction_in,
    output                          pcm_sig_valid,
    */
    output [1:0]                   pcm_instruction,
    output [puf_sig_length-1:0]    pcm_puf_in,
    output                         pcm_puf_in_valid,
    output [$clog2(ipid_N)-1:0]    pcm_ipid_number,

    // Boot control to Bus Translation unit 
    output logic                         bootControl_bus_go,
    output logic [pAHB_ADDR_WIDTH-1:0]    bootControl_bus_addr,
    output logic [pPAYLOAD_SIZE_BITS-1:0] bootControl_bus_write,
    output logic                         bootControl_bus_RW

);

    localparam memory_width = `SECURE_MEMORY_WIDTH;
    localparam memory_length = `SECURE_MEMORY_LENGTH;

    wire lc_transition_request;
    wire [255:0] lc_identifier;
    wire lc_success;
    wire lc_done; 
    wire [2:0] lc_state; 
    
    

    lifecycle_protection lc_protection ( .rst_n(init_config_n), .* );

    wire                            secureboot_rd_en;
    wire                            secureboot_wr_en;
    wire [$clog2(memory_length)-1:0] secureboot_addr;
    wire [memory_width-1:0]         secureboot_wrData;
    

    wire [511:0]                        secureboot_sha_block;
    wire                                secureboot_sha_init;
    wire                                secureboot_sha_next;
    wire                                secureboot_sha_sel;


// secureboot module to Bus Translation unit 
    wire                                secureboot_bootControl_bus_go;
    wire [pAHB_ADDR_WIDTH-1:0]          secureboot_bootControl_bus_addr;
    wire [pPAYLOAD_SIZE_BITS-1:0]       secureboot_bootControl_bus_write;
    wire                                secureboot_bootControl_bus_RW;


    

    // FW authentication module to sha
    wire [511:0]                        fw_sha_block;
    wire                                fw_sha_init;
    wire                                fw_sha_next;
    wire                                fw_sha_sel;


// FW Authentication module to Bus Translation unit 
    wire                                fw_bootControl_bus_go;
    wire [pAHB_ADDR_WIDTH-1:0]          fw_bootControl_bus_addr;
    wire [pPAYLOAD_SIZE_BITS-1:0]       fw_bootControl_bus_write;
    wire                                fw_bootControl_bus_RW;

// FW authentication module to Secure Memory 
    wire                                fw_rd_en;
    wire                                fw_wr_en;
    wire [$clog2(memory_length)-1:0]    fw_addr;
    wire [memory_width-1:0]             fw_wrData;


    logic                            rd_en;
    logic                            wr_en;
    logic [$clog2(memory_length)-1:0] addr;
    logic [memory_width-1:0]         wrData;
    logic [memory_width-1:0]         rdData;
    logic                            rdData_valid;

    logic fw_authentication_trigger;
    logic secureboot_fw_sel;

    logic                                     fw_auth_result;
    logic                                      fw_auth_done;

    wire              apc_select;
    wire [255:0]      chip_id_to_apc;
    wire              apc_encryption_done;
    wire [255:0]      encrypted_chip_id_from_apc;



    secure_memory #(.WIDTH(memory_width), .LENGTH(memory_length) ) mem (.rst_n(init_config_n), .*);

    secure_boot_control #(.pcm_data_width(pcm_data_width), .pcm_addr_width(pcm_addr_width), .puf_sig_length(puf_sig_length), 
    .gpio_N(gpio_N), .gpio_AW(gpio_AW), .gpio_PW(gpio_PW), .memory_width(memory_width), .memory_length(memory_length), .ipid_N(ipid_N),
    .ipid_width(ipid_width), .pAHB_ADDR_WIDTH(pAHB_ADDR_WIDTH), .pPAYLOAD_SIZE_BITS(pPAYLOAD_SIZE_BITS)) 
    secure_boot (.rd_en(secureboot_rd_en), .wr_en(secureboot_wr_en), .addr(secureboot_addr), .wrData(secureboot_wrData),
    .bootControl_bus_go(secureboot_bootControl_bus_go), .bootControl_bus_addr(secureboot_bootControl_bus_addr),
    .bootControl_bus_RW(secureboot_bootControl_bus_RW), .bootControl_bus_write(secureboot_bootControl_bus_write),
    .sha_block(secureboot_sha_block), .sha_init(secureboot_sha_init), .sha_next(secureboot_sha_next), .sha_sel(secureboot_sha_sel),
    .pcm_puf_in(pcm_puf_in),
     .* );

    fw_authentication #(.gpio_N(gpio_N), .gpio_AW(gpio_AW), .gpio_PW(gpio_PW),
    .fw_image_N(fw_image_N), .fw_block_width(fw_block_width),
    .pAHB_ADDR_WIDTH(pAHB_ADDR_WIDTH), .pPAYLOAD_SIZE_BITS(pPAYLOAD_SIZE_BITS), .memory_width(memory_width), .memory_length(memory_length))
    fw_auth ( .* );

    vim_scan_control #(.scan_key_width(scan_key_width), .scan_key_number(scan_key_number)) scan_control ( .* );

    apc_wrapper apc ( .* );

    
    always_comb begin
        if ( ~secureboot_fw_sel) begin
            // secure memory 
            rd_en = secureboot_rd_en;
            wr_en = secureboot_wr_en;
            addr = secureboot_addr;
            wrData = secureboot_wrData;
            

            bootControl_bus_go = secureboot_bootControl_bus_go;
            bootControl_bus_addr =  secureboot_bootControl_bus_addr;
            bootControl_bus_write = secureboot_bootControl_bus_write;
            bootControl_bus_RW = secureboot_bootControl_bus_RW;

            sha_block = secureboot_sha_block;
            sha_init  = secureboot_sha_init;
            sha_next  =  secureboot_sha_next;
            sha_sel  =    secureboot_sha_sel;
            
        end
        else begin

            rd_en = fw_rd_en;
            wr_en = fw_wr_en;
            addr = fw_addr;
            wrData = fw_wrData;
            

            bootControl_bus_go = fw_bootControl_bus_go;
            bootControl_bus_addr =  fw_bootControl_bus_addr;
            bootControl_bus_write = fw_bootControl_bus_write;
            bootControl_bus_RW = fw_bootControl_bus_RW;

            sha_block = fw_sha_block;
            sha_init  = fw_sha_init;
            sha_next  =  fw_sha_next;
            sha_sel  =   fw_sha_sel;

        end 
    end 

endmodule 