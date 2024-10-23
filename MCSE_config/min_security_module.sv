/*
`include "definitions.svh"
`include "sha_top.sv"
`include "camellia_top.sv"
`include "gpio.v"
`include "camellia.v"
`include "c1908.v"
`include "gpio_regmap.v"
`include "oh_dsync.v"
`include "packet2emesh.v"
`include "pcm.v"
`include "sha256_puf_256.v"
`include "primitives.v"
`include "io.v"
*/
`include "mcse_def.svh"

module min_security_module  #( 
        parameter ipid_N                = `IPID_N,
        parameter fw_image_N            =`FW_N,    
        parameter data_width            = 32,
        parameter addr_width            = 32,
        parameter puf_sig_length        = `IPID_WIDTH,
        parameter N                     = 24,     
        parameter AW                    = 32,      
        parameter PW                    = 2*AW+40,
        parameter pAHB_DATA_WIDTH       = `AHB_DATA_WIDTH_BITS,
        parameter pAHB_HRESP_WIDTH      = 2,
        parameter pAHB_ADDR_WIDTH       = 32,
        parameter pAHB_BURST_WIDTH      = 3,
        parameter pAHB_PROT_WIDTH       = 4,
        parameter pAHB_SIZE_WIDTH       = 3,
        parameter pAHB_TRANS_WIDTH      = 2,
        parameter pPAYLOAD_SIZE_BITS    = `IPID_WIDTH
    )

    (
    // Global signals for minimum security module
    input clk, 
    input rst,

    // `ifdef ENCRYPTION_FUNCTION
    //     `ifdef Camellia
        /*
        IO interface for CAMELLIA inside the minimum security module
        */
            input [127:0] data_in,
            input [255:0] key,
            input [0:1] k_len,
            input enc_dec,
            input data_rdy,
            input key_rdy,
            output [127:0] data_out,
            output data_acq,
            output key_acq,
            output output_rdy,
            output [255:0] cam_pufout,

        // `elsif AES
        /*
        IO interface for APC inside the minimum security module
        */
            input core_reset,
            input apc_data_in, 
            input apc_data_in_valid, 
            input apc_word_en,
            output apc_data_req,
            output apc_sleep_out_sha3, 
            output apc_sleep_out_aes,
            output apc_data_out_aes, 
            output apc_data_out_sha3,
            output apc_data_out_valid_aes, 
            output apc_data_out_valid_sha3,
           
    //     `endif 
        
    // `endif 



    /*
    IO interface for SHA256 inside the minimum security module
    */
    input [511:0]   sha_block,
    input           sha_init,
    input           sha_next,
    input           sha_sel,
    output [255:0]  sha_digest,
    output          sha_ready,
    output          sha_digest_valid,
    output [255:0]  sha_pufout,

    /*
    IO interface for PUF Control Module (PCM) inside the minimum security module
    */
    /*
    input [puf_sig_length-1 : 0]   sig_in,
    input [data_width-1 : 0]       IP_ID_in,
    input [2:0]                    Instruction_in,
    input                          sig_valid,
    output reg [data_width-1 : 0]  control_out,
    output reg [data_width-1 : 0]  status,
    output reg                     comp_out,
    output reg                     S_c,
    output reg                     A_c, 
    */
    input        [1:0]                   pcm_instruction,
    input        [puf_sig_length-1:0]    pcm_puf_in,
    input                                pcm_puf_in_valid,
    input        [$clog2(ipid_N)-1:0]    pcm_ipid_number,
    output logic [puf_sig_length-1:0]    pcm_puf_out,
    output logic                         pcm_puf_out_valid,
    output logic                         pcm_S_c,


    /*
    IO interface for Boot Control (GPIO) inside the minimum security module
    */
   // input           nreset,      
    input           reg_access, 
    input  [N-1:0]  gpio_in, 
    input [PW-1:0]  reg_packet,  
    output [N-1:0]   reg_rdata,   
    output [N-1:0]  gpio_out,    
    output [N-1:0]  gpio_en,    
    output          gpio_irq,    
    output [N-1:0]   gpio_ilat,  

    /*
    IO Interface for AHB-Lite // System side AHB requester port
    */
    input   wire    [pAHB_DATA_WIDTH-1        :0]   I_hrdata,
    input   wire                                    I_hready,
    input   wire    [pAHB_HRESP_WIDTH-1       :0]   I_hresp,
    input   wire                                    I_hreadyout,

     // System side AHB requester port
    output  logic   [pAHB_ADDR_WIDTH-1        :0]   O_haddr,
    output  logic   [pAHB_BURST_WIDTH-1       :0]   O_hburst,
    output  logic                                   O_hmastlock,
    output  logic   [pAHB_PROT_WIDTH-1        :0]   O_hprot,
    output  logic                                   O_hnonsec,
    output  logic   [pAHB_SIZE_WIDTH-1        :0]   O_hsize,
    output  logic   [pAHB_TRANS_WIDTH-1       :0]   O_htrans,
    output  logic   [pAHB_DATA_WIDTH-1        :0]   O_hwdata,
    output  logic                                   O_hwrite,

    /*
    IO Interface for bus translation unit 
    */
    input   wire                                    bootControl_bus_go,
    input   wire [pAHB_ADDR_WIDTH-1:0]              bootControl_bus_addr,
    input   wire [pPAYLOAD_SIZE_BITS-1:0]           bootControl_bus_write,
    input   wire                                    bootControl_bus_RW,   
    output logic                                    bootControl_bus_done,
    output logic [pPAYLOAD_SIZE_BITS-1:0]           bootControl_bus_rdData 



);

/*
SHA 256 MODULE INSTANCE FOR MINIMUM SECURITY MODULE
*/
sha_top sha_control(
    .clk(clk),
    .rst(rst),
    .block(sha_block),
    .init(sha_init),
    .next(sha_next),
    .sel(sha_sel),
    .digest(sha_digest),
    .ready(sha_ready),
    .digest_valid(sha_digest_valid),
    .pufout(sha_pufout)
);

`ifdef ENCRYPTION_FUNCTION 
       if (`ENCRYPTION_FUNCTION == "Camellia") begin
          /*
        CAMELLIA 256 MODULE INSTANCE FOR MINIMUM SECURITY MODULE
        */
        camellia_top camellia_control(
            .clk(clk),
            .rst(rst),
            .data_in(data_in),
            .key(key),
            .k_len(k_len),
            .enc_dec(enc_dec),
            .data_rdy(data_rdy),
            .key_rdy(key_rdy),
            .data_out(data_out),
            .data_acq(data_acq),
            .key_acq(key_acq),
            .output_rdy(output_rdy),
            .pufout(cam_pufout)
            );
         end 

        else begin
             /*
APC MODULE INSTANCE FOR MINIMUM SECURITY MODULE
*/
        polymorphic_top_w_wrapper apc_control(
            .clk(~clk),
            .reset(rst),
            .core_reset(core_reset),
            .data_in(apc_data_in),
            .data_in_valid(apc_data_in_valid),
            .word_en(apc_word_en),
            .data_req(apc_data_req),
            .sleep_out_aes(apc_sleep_out_aes),
            .sleep_out_sha3(apc_sleep_out_sha3),
            .data_out_aes(apc_data_out_aes),
            .data_out_sha3(apc_data_out_sha3),
            .data_out_valid_aes(apc_data_out_valid_aes),
            .data_out_valid_sha3(apc_data_out_valid_sha3)
        );
        end
`endif 


/*
BOOT CONTROL INSTANCE FOR MINIMUM SECURITY MODULE
*/
gpio boot_control(
        .clk(clk),
        .nreset(~rst),
        .reg_access(reg_access),
        .gpio_in(gpio_in),
        .reg_packet(reg_packet),
        .reg_rdata(reg_rdata),
        .gpio_out ( gpio_out), 
         .gpio_en ( gpio_en),
         .gpio_irq ( gpio_irq),
         .gpio_ilat ( gpio_ilat)
);

/*
PUF CONTROL MODULE FOR MINIMUM SECURITY MODULE
*/
//pcm pcm_mod(.*);
error_correction # ( .puf_sig_length(puf_sig_length), .ipid_N(ipid_N) )
pcm (.rst_n(~rst), .*); 


wire [pPAYLOAD_SIZE_BITS-1:0]  O_int_rdata;
wire                           O_int_rdata_valid;
wire                           O_done;

wire [pAHB_ADDR_WIDTH-1:0]    I_int_addr;
wire [pPAYLOAD_SIZE_BITS-1:0] I_int_wdata;
wire                          I_int_write;
wire                          I_go;

/*
AHB-LITE INTERFACE MODULE FOR MINIMUM SECURITY MODULE 
*/
data_worker #(.pAHB_ADDR_WIDTH(pAHB_ADDR_WIDTH), .pPAYLOAD_SIZE_BITS(pPAYLOAD_SIZE_BITS))
ahb_interface (.rst_n(~rst), .*);

bus_translation #(.pAHB_ADDR_WIDTH(pAHB_ADDR_WIDTH), .pPAYLOAD_SIZE_BITS(pPAYLOAD_SIZE_BITS))
translation (.rst_n(~rst), .*); 

endmodule