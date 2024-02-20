module secure_boot_control # (
    parameter pcm_data_width = 32,
    parameter pcm_addr_width = 32,
    parameter puf_sig_length = 256,
    parameter gpio_N = 24,
    parameter gpio_AW = 32,
    parameter gpio_PW = 2*gpio_AW+40,

    parameter memory_width = 256,
    parameter memory_length = 6
)
(
    input                               clk,
    input                               rst,

    // Camellia to Boot Control
    input [127:0]                       cam_data_out,
    input                               cam_data_acq,
    input                               cam_key_acq,
    input                               cam_output_rdy,
    input [255:0]                       cam_puf_out,

    // SHA to Boot Control
    input [255:0]                       sha_digest,
    input                               sha_ready,
    input                               sha_digest_valid,
    input [255:0]                       sha_pufout,

    // GPIO to Boot Control
    input [gpio_N-1:0]                  gpio_reg_rdata,
    input [gpio_N-1:0]                  gpio_en,
    input                               gpio_irq,
    input [gpio_N-1:0]                  gpio_ilat,  

    // PCM to Boot Control
    input [pcm_data_width-1:0]          pcm_control_out,
    input [pcm_data_width-1:0]          pcm_status,
    input                               pcm_comp_out,
    input                               pcm_S_c,
    input                               pcm_A_c,

    // LC Protection to Boot Control
    input                               lc_success,
    input [2:0]                         lc_state,

    // Seucre memory to Boot Control
    input [memory_width-1:0]            rdData,
    input                               valid,

    // Boot control to Camellia 
    output logic [127:0]                cam_data_in,
    output logic [255:0]                cam_key,
    output logic [1:0]                  cam_k_len,
    output logic                        cam_enc_dec,
    output logic                        cam_data_rdy,
    output logic                        cam_key_rdy,

    // Boot control to SHA
    output [511:0]                      sha_block,
    output                              sha_init,
    output                              sha_next,
    output                              sha_sel,

    // Boot Control to GPIO 
    output                              gpio_reg_access,
    output [gpio_PW-1:0]                gpio_reg_packet,    

    // Boot Control to PCM 
    output [puf_sig_length-1:0]         pcm_sig_in,
    output [pcm_data_width-1:0]         pcm_IP_ID_in,
    output [2:0]                        pcm_instruction_in,
    output                              pcm_sig_valid,

    // Boot control to LC Protection
    output                              lc_transition_request,
    output [255:0]                      lc_identifier,

    // Boot Control to Secure Memory 
    output                              rd_en,
    output                              wr_en,
    output [$clog2(memory_length)-1:0]  addr,
    output [memory_width-1:0]           wrData
);

reg [255:0] encryption_output_r, encryption_output_next; 
reg half_r, half_next; 
reg encryption_done_r, encryption_done_next;

typedef enum logic [1:0] {START, FINISH} state_t;
state_t state_r, state_next;

logic [127:0]                    cam_data_in_next;
logic [255:0]                    cam_key_next;
logic [1:0]                      cam_k_len_next;
logic                           cam_enc_dec_next;
logic                           cam_data_rdy_next;
logic                           cam_key_rdy_next;

logic [255:0] data_tmp = {128'hfd81c1769533a1a9690b0b57ca5c9483, 128'hdfbffd392442a7efa38867fe19a98416};
logic [255:0] key_tmp = 256'h2bb5c55800d08af413a7dc5ed359c8e8a2c4e2f608c1f3809eb133d7e64d51d8;

function void encryption(input bit [255:0] data_input, input bit [255:0] key_input, input bit half);
    
    cam_enc_dec_next = 1;
    cam_k_len_next = 2'b10; 
    cam_key_next = key_input; 
    cam_key_rdy = 1; 


    case (half)
        0 : begin
            cam_data_rdy_next = 1; 
            cam_data_in_next = data_input[255:128];
            if (cam_output_rdy) begin
                half_next = 1; 
                encryption_output_next[255:128] = cam_data_out;
                cam_data_rdy_next = 0; 
            end 
        end 
        1 : begin 
            cam_data_in_next = data_input[127:0];
            cam_data_rdy_next = 1; 
            if (cam_output_rdy) begin
                half_next = 0; 
                encryption_output_next[127:0] = cam_data_out;
                cam_key_rdy = 0;
                cam_data_rdy = 0; 
                encryption_done_next = 1; 
            end 
        end 
    endcase  
endfunction

always@(posedge clk, negedge rst) begin 
    if (~rst) begin
        state_r <= START;
        cam_data_in <= 0;
        cam_key <= 0; 
        cam_k_len <= 2'b10;
        cam_enc_dec <= 1; 
        cam_data_rdy <= 0;
        cam_key_rdy <= 0; 
        encryption_output_r <= 0;
        half_r <= 0; 
        encryption_done_r <= 0; 
    end 
    else begin
        state_r <= state_next; 
        
        cam_data_in <= cam_data_in_next;
        cam_key <= cam_key_next;
        cam_k_len <= cam_k_len_next;
        cam_enc_dec <= cam_enc_dec_next; 
        cam_data_rdy <= cam_data_rdy_next; 
        cam_key_rdy <= cam_key_rdy_next; 
        

        encryption_output_r <= encryption_output_next; 
        half_r <= half_next;
        encryption_done_r <= encryption_done_next; 
    end 
end

always_comb begin
    state_next = state_r;
    cam_data_in_next = cam_data_in;
    cam_key_next = cam_key;
    cam_k_len_next = cam_k_len;
    cam_data_rdy_next = cam_enc_dec;
    cam_key_rdy_next = cam_key_rdy;

    encryption_output_next = encryption_output_r;
    half_next = half_r;
    encryption_done_next = encryption_done_r;


    case (state_r) 
        START : begin
            encryption(data_tmp, key_tmp, half_r); 
            if (encryption_done_r) begin
                state_next = FINISH;
                encryption_done_next = 0;
            end 
        end 
        FINISH : begin

        end 
    endcase
end 

endmodule