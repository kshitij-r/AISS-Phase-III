
`include "mcse_def.svh"
module mcse_control_unit #(
    parameter gpio_N                = 32,
    parameter gpio_AW               = 32,
    parameter gpio_PW               = 2*gpio_AW+40,
    parameter scan_key_width        = `SCAN_KEY_WIDTH,
    parameter scan_key_number       = `SCAN_KEY_NUMBER

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


    // *** To Boot Control 
    input  [511:0]        lc_transition_id,
    input                 lc_transition_request_in,
    input  [511:0]        lc_authentication_id,
    input                 lc_authentication_valid, 


    // *** To Vimscan
    input [scan_key_width-1:0]      scan_key,

    // Boot control to Camellia 
    output [127:0]                  cam_data_in,
    output [255:0]                  cam_key,
    output [0:1]                    cam_k_len,
    output                          cam_enc_dec,
    output                          cam_data_rdy,
    output                          cam_key_rdy,

     // Boot control to SHA
    output logic [511:0]                  sha_block,
    output logic                          sha_init,
    output logic                         sha_next,
    output logic                          sha_sel,


    // Boot Control to GPIO 
    output                          gpio_reg_access,
    output [gpio_PW-1:0]            gpio_reg_packet,  


    // Vimscan to MCSE control unit
    output logic                    scan_unlock

);

    localparam memory_width = 512;
    localparam memory_length = 6;

    wire lc_transition_request;
    wire [511:0] lc_identifier;
    wire lc_success;
    wire lc_done; 
    wire [2:0] lc_state; 
    


    logic                            rd_en;
    logic                            wr_en;
    logic [$clog2(memory_length)-1:0] addr;
    logic [memory_width/2-1:0]         wrData;
    logic [memory_width-1:0]         rdData;
    logic                            rdData_valid;

   

    lifecycle_protection lc_protection ( .rst_n(init_config_n), .* );

    secure_memory #(.WIDTH(memory_width), .LENGTH(memory_length) ) mem (.rst_n(init_config_n), .*);


    secure_boot_control #( 
    .gpio_N(gpio_N), .gpio_AW(gpio_AW), .gpio_PW(gpio_PW), .memory_width(memory_width), .memory_length(memory_length) )
    secure_boot ( .* );


    vim_scan_control #(.scan_key_width(scan_key_width), .scan_key_number(scan_key_number)) scan_control ( .* );


endmodule 