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
module min_security_module 
    #( data_width        = 32,
       addr_width        = 32,
       puf_sig_length    = 256,
       N      = 24,     
       AW     = 32,      
       PW     = 2*AW+40
    )

    (
    // Global signals for minimum security module
    input clk, 
    input rst,

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
    input [puf_sig_length-1 : 0]   sig_in,
    input [data_width-1 : 0]       IP_ID_in,
	input [2:0]                    Instruction_in,
	input                          sig_valid,
    output reg [data_width-1 : 0]  control_out,
	output reg [data_width-1 : 0]  status,
    output reg                     comp_out,
    output reg                     S_c,
	output reg                     A_c, 

    /*
    IO interface for Boot Control (GPIO) inside the minimum security module
    */
   // input           nreset,      
    input 	        reg_access, 
    input  [N-1:0]  gpio_in, 
    input [PW-1:0]  reg_packet,  
    output [N-1:0]   reg_rdata,   
    output [N-1:0]  gpio_out,    
    output [N-1:0]  gpio_en,    
    output 	        gpio_irq,    
    output [N-1:0]   gpio_ilat  
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

endmodule
