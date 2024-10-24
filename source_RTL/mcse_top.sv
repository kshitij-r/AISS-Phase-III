`define         AHB_DATA_WIDTH_BITS                 32
`include "mcse_def.svh"

module mcse_top # (
    parameter pcm_data_width     = 32,
    parameter pcm_addr_width     = 32,
    parameter puf_sig_length     = 256,
    parameter gpio_N             = 32,
    parameter gpio_AW            = 32,
    parameter gpio_PW            = 2*gpio_AW+40,
    parameter ipid_N             = 1,
    parameter ipid_width         = 256,
    parameter fw_image_N         = 9,
    parameter fw_block_width     = 256,
    parameter pAHB_DATA_WIDTH    = `AHB_DATA_WIDTH_BITS,
    parameter pAHB_HRESP_WIDTH   = 2,
    parameter pAHB_ADDR_WIDTH    = 32,
    parameter pPAYLOAD_SIZE_BITS = 256,
    parameter pAHB_BURST_WIDTH   = 3,
    parameter pAHB_PROT_WIDTH    = 4,
    parameter pAHB_SIZE_WIDTH    = 3,
    parameter  pAHB_TRANS_WIDTH  = 2

)
(
    input   wire                                    clk,
    input   wire                                    rst_n,
    input   wire                                    init_config_n, 
    input   wire    [gpio_N-1:0]                    gpio_in,

    input   wire    [255:0]                         lc_transition_id,
    input   wire                                    lc_transition_request_in,
    input   wire    [255:0]                         lc_authentication_id,
    input   wire                                    lc_authentication_valid, 

    // System side AHB requester port
    input   wire    [pAHB_DATA_WIDTH-1        :0]   I_hrdata,
    input   wire                                    I_hready,
    input   wire    [pAHB_HRESP_WIDTH-1       :0]   I_hresp,
    input   wire                                    I_hreadyout,

    output  logic    [gpio_N-1:0]                   gpio_out,

    // System side AHB requester port
    output  logic   [pAHB_ADDR_WIDTH-1        :0]   O_haddr,
    output  logic   [pAHB_BURST_WIDTH-1       :0]   O_hburst,
    output  logic                                   O_hmastlock,
    output  logic   [pAHB_PROT_WIDTH-1        :0]   O_hprot,
    output  logic                                   O_hnonsec,
    output  logic   [pAHB_SIZE_WIDTH-1        :0]   O_hsize,
    output  logic   [pAHB_TRANS_WIDTH-1       :0]   O_htrans,
    output  logic   [pAHB_DATA_WIDTH-1        :0]   O_hwdata,
    output  logic                                   O_hwrite

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

    // SHA Inputs
    wire [511:0]              fw_sha_block;
    wire                      fw_sha_init;
    wire                      fw_sha_next;
    wire                      fw_sha_sel;
    // SHA Outputs
    wire [255:0]              fw_sha_digest;
    wire                      fw_sha_ready;
    wire                      fw_sha_digest_valid;
    wire [255:0]              fw_sha_puf_out;

    // GPIO Inputs 
    wire                      gpio_reg_access;
    wire [gpio_PW-1:0]        gpio_reg_packet;
    //GPIO Outputs
    wire [gpio_N-1:0]         gpio_reg_rdata;
    wire [gpio_N-1:0]         gpio_en;
    wire                      gpio_irq;
    wire [gpio_N-1:0]         gpio_ilat;   

    wire                           bootControl_bus_go;
    wire [pAHB_ADDR_WIDTH-1:0]     bootControl_bus_addr;
    wire [pPAYLOAD_SIZE_BITS-1:0]  bootControl_bus_write;
    wire                           bootControl_bus_RW;
    wire                           bootControl_bus_done;
    wire [pPAYLOAD_SIZE_BITS-1:0]  bootControl_bus_rdData; 

    wire                           fw_bus_go;
    wire [pAHB_ADDR_WIDTH-1:0]     fw_bus_addr;
    wire [pPAYLOAD_SIZE_BITS-1:0]  fw_bus_write;
    wire                           fw_bus_RW;
    wire                           fw_bus_done;
    wire [pPAYLOAD_SIZE_BITS-1:0]  fw_bus_rdData;
    
    wire  [1:0]                  pcm_instruction;
    wire [puf_sig_length-1:0]    pcm_puf_in;
    wire                         pcm_puf_in_valid;
    wire [$clog2(ipid_N)-1:0]    pcm_ipid_number;
    wire [puf_sig_length-1:0]    pcm_puf_out;
    wire                         pcm_puf_out_valid;
    wire                         pcm_S_c; 

    min_security_module #(
    .ipid_N(ipid_N), .data_width(pcm_data_width), .addr_width(pcm_addr_width), .puf_sig_length(puf_sig_length), .N(gpio_N),
    .AW(gpio_AW), .PW(gpio_PW), .pAHB_ADDR_WIDTH(pAHB_ADDR_WIDTH), .pPAYLOAD_SIZE_BITS(pPAYLOAD_SIZE_BITS)) 
    min_sec (
    .clk(clk), .rst(~rst_n),
    .data_in(cam_data_in), .key(cam_key), .key_rdy(cam_key_rdy), .k_len(cam_k_len), .enc_dec(cam_enc_dec),.data_rdy(cam_data_rdy), .data_out(cam_data_out),
    .data_acq(cam_data_acq), .key_acq(cam_data_acq), .output_rdy(cam_output_rdy), .cam_pufout(cam_puf_out),

    .sha_block(sha_block), .sha_init(sha_init), .sha_next(sha_next), .sha_sel(sha_sel), .sha_digest(sha_digest), .sha_ready(sha_ready),
    .sha_digest_valid(sha_digest_valid), .sha_pufout(sha_puf_out),

    .reg_access(gpio_reg_access), .gpio_in(gpio_in), .reg_packet(gpio_reg_packet), .reg_rdata(gpio_reg_rdata), .gpio_out(gpio_out),
    .gpio_en(gpio_en), .gpio_irq(gpio_irq), .gpio_ilat(gpio_ilat),

    .pcm_instruction(pcm_instruction), .pcm_puf_in(pcm_puf_in), .pcm_puf_in_valid(pcm_puf_in_valid), .pcm_ipid_number(pcm_ipid_number),
    .pcm_puf_out(pcm_puf_out), .pcm_puf_out_valid(pcm_puf_out_valid), .pcm_S_c(pcm_S_c), 

    .*
    ); 


    mcse_control_unit #(.pcm_data_width(pcm_data_width), .pcm_addr_width(pcm_addr_width), .puf_sig_length(puf_sig_length), .gpio_N(gpio_N),
    .gpio_AW(gpio_AW), .gpio_PW(gpio_PW), .ipid_N(ipid_N), .ipid_width(ipid_width), .pAHB_ADDR_WIDTH(pAHB_ADDR_WIDTH), 
    .pPAYLOAD_SIZE_BITS(pPAYLOAD_SIZE_BITS), .fw_image_N(fw_image_N), .fw_block_width(fw_block_width))
    control_unit (.*);

endmodule