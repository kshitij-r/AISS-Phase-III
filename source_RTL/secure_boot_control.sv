//TODO Configurability of length of IP ID
//TODO Decyrpt and check value of encryption 

`define GPIO_IDATA 6'h5
`define GPIO_ODATA 6'h0

`define SYS_BUS_WAKEUP 24'b1000000

`define IPID_DONE 25'b100000000000000 // gpio pin 

module secure_boot_control # (
    parameter pcm_data_width = 32,
    parameter pcm_addr_width = 32,
    parameter puf_sig_length = 256,
    parameter gpio_N = 32,
    parameter gpio_AW = 32,
    parameter gpio_PW = 2*gpio_AW+40,

    parameter memory_width = 256,
    parameter memory_length = 6,

    parameter ipid_N = 16,
    parameter ipid_width = 256
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
    output logic [511:0]                sha_block,
    output logic                        sha_init,
    output logic                        sha_next,
    output logic                        sha_sel,

    // Boot Control to GPIO 
    output logic                        gpio_reg_access,
    output logic [gpio_PW-1:0]          gpio_reg_packet,    

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

typedef enum logic [1:0] {START, FINISH, TEMP, TEMP2 } state_t;
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
    cam_key_rdy_next = 1; 

    case (half)
        1'b0 : begin
            cam_data_rdy_next = 1; 
            cam_data_in_next = data_input[255:128];
            if (cam_output_rdy) begin
                half_next = 1; 
                encryption_output_next[255:128] = cam_data_out;
                cam_data_rdy_next = 0; 
            end 
        end 
        1'b1 : begin 
            cam_data_in_next = data_input[127:0];
            cam_data_rdy_next = 1; 
            if (cam_output_rdy) begin
                half_next = 0; 
                encryption_output_next[127:0] = cam_data_out;
                cam_key_rdy_next = 0;
                cam_data_rdy_next = 0; 
                encryption_done_next = 1; 
            end 
        end 
    endcase  
endfunction

logic [1:0] ipid_handshake_counter_r, ipid_handshake_counter_next; 
logic [gpio_N-1:0] gpio_wrData_r, gpio_wrData_next; 
logic [5:0] gpio_data_type_r, gpio_data_type_next; 
logic gpio_RW_r, gpio_RW_next;
logic gpio_reg_access_next; 
assign gpio_reg_packet = {14'h0, gpio_wrData_r, 1'b0, 3'b000, 20'b0,  gpio_data_type_r, 2'b0, 7'b0, gpio_RW_r};

logic [ipid_N-1:0][ipid_width-1:0] ipid_r, ipid_next;
logic [4:0] ipid_counter_r, ipid_counter_next; 
logic ipid_trigger_r, ipid_trigger_next; 
logic [1:0] ipid_valid_r, ipid_valid_next; 
logic [3:0] ipid_index_r, ipid_index_next; 
logic ipid_extraction_done_r, ipid_extraction_done_next;

function void ipid_extraction();

    case (ipid_handshake_counter_r)
        2'b00 : begin // bus wake up
            gpio_wrData_next = `SYS_BUS_WAKEUP;
            gpio_RW_next = 1'b1;
            gpio_data_type_next = `GPIO_ODATA;
            gpio_reg_access_next = 1; 
            ipid_handshake_counter_next = ipid_handshake_counter_r + 1; 
        end 
        2'b01 : begin // wait for bus wake up ack
            gpio_data_type_next = `GPIO_IDATA; 
            gpio_RW_next = 0;
            if (gpio_reg_rdata[7]) begin
                ipid_handshake_counter_next = ipid_handshake_counter_r + 1;
            end 
        end
        2'b10 : begin // ip id extraction 
            if (ipid_counter_r >= ipid_N) begin
                ipid_extraction_done_next = 1; 
                ipid_counter_next = 0; 
                ipid_handshake_counter_next = 0;
            end 
            else begin
                case (ipid_trigger_r) 
                    1'b0 : begin // trigger ip id extraction 
                        gpio_wrData_next = {19'b0, 1'b1, ipid_counter_r[3:0], 8'b0}; // constructs ip id packet and with ip id trigger
                        gpio_data_type_next = `GPIO_ODATA; 
                        gpio_RW_next = 1; 
                        ipid_trigger_next = 1; 
                    end
                    1'b1 : begin // take in ip ids
                        gpio_data_type_next = `GPIO_IDATA;
                        gpio_wrData_next = 0; 
                        gpio_RW_next = 0; 
                        case (ipid_valid_r) 
                            2'b00 : begin
                                if (gpio_reg_rdata[31:16] == 16'h7A7A && gpio_reg_rdata[13]) begin
                                    ipid_valid_next = ipid_valid_r + 1; 
                                end 
                            end 
                            2'b01 : begin 
                                case (ipid_index_r) 
                                    4'b0000 : begin
                                        if (gpio_reg_rdata[13]) begin
                                            ipid_next[ipid_counter_r][255:240] = gpio_reg_rdata[31:16];
                                            ipid_index_next = ipid_index_r + 1; 
                                        end 
                                    end    
                                    4'b0001 : begin
                                        if (gpio_reg_rdata[13]) begin
                                            ipid_next[ipid_counter_r][239:224] = gpio_reg_rdata[31:16];
                                            ipid_index_next = ipid_index_r + 1; 
                                        end 
                                    end 
                                    4'b0010 : begin
                                        if (gpio_reg_rdata[13]) begin
                                            ipid_next[ipid_counter_r][223:208] = gpio_reg_rdata[31:16];
                                            ipid_index_next = ipid_index_r + 1; 
                                        end 
                                    end   
                                    4'b0011 : begin
                                        if (gpio_reg_rdata[13]) begin
                                            ipid_next[ipid_counter_r][207:192] = gpio_reg_rdata[31:16];
                                            ipid_index_next = ipid_index_r + 1; 
                                        end 
                                    end 
                                    4'b0100 : begin
                                        if (gpio_reg_rdata[13]) begin
                                            ipid_next[ipid_counter_r][191:176] = gpio_reg_rdata[31:16];
                                            ipid_index_next = ipid_index_r + 1; 
                                        end 
                                    end  
                                    4'b0101 : begin
                                        if (gpio_reg_rdata[13]) begin
                                            ipid_next[ipid_counter_r][175:160] = gpio_reg_rdata[31:16];
                                            ipid_index_next = ipid_index_r + 1; 
                                        end 
                                    end   
                                    4'b0110 : begin
                                        if (gpio_reg_rdata[13]) begin
                                            ipid_next[ipid_counter_r][159:144] = gpio_reg_rdata[31:16];
                                            ipid_index_next = ipid_index_r + 1; 
                                        end 
                                    end  
                                    4'b0111 : begin
                                        if (gpio_reg_rdata[13]) begin
                                            ipid_next[ipid_counter_r][143:128] = gpio_reg_rdata[31:16];
                                            ipid_index_next = ipid_index_r + 1; 
                                        end 
                                    end 
                                    4'b1000 : begin
                                        if (gpio_reg_rdata[13]) begin
                                            ipid_next[ipid_counter_r][127:112] = gpio_reg_rdata[31:16];
                                            ipid_index_next = ipid_index_r + 1; 
                                        end 
                                    end 
                                    4'b1001 : begin
                                        if (gpio_reg_rdata[13]) begin
                                            ipid_next[ipid_counter_r][111:96] = gpio_reg_rdata[31:16];
                                            ipid_index_next = ipid_index_r + 1; 
                                        end 
                                    end  
                                    4'b1010 : begin
                                        if (gpio_reg_rdata[13]) begin
                                            ipid_next[ipid_counter_r][95:80] = gpio_reg_rdata[31:16];
                                            ipid_index_next = ipid_index_r + 1; 
                                        end 
                                    end  
                                    4'b1011 : begin
                                        if (gpio_reg_rdata[13]) begin
                                            ipid_next[ipid_counter_r][79:64] = gpio_reg_rdata[31:16];
                                            ipid_index_next = ipid_index_r + 1; 
                                        end 
                                    end   
                                    4'b1100 : begin
                                        if (gpio_reg_rdata[13]) begin
                                            ipid_next[ipid_counter_r][63:48] = gpio_reg_rdata[31:16];
                                            ipid_index_next = ipid_index_r + 1; 
                                        end 
                                    end  
                                    4'b1101 : begin
                                        if (gpio_reg_rdata[13]) begin
                                            ipid_next[ipid_counter_r][47:32] = gpio_reg_rdata[31:16];
                                            ipid_index_next = ipid_index_r + 1; 
                                        end 
                                    end      
                                    4'b1110 : begin
                                        if (gpio_reg_rdata[13]) begin
                                            ipid_next[ipid_counter_r][31:16] = gpio_reg_rdata[31:16];
                                            ipid_index_next = ipid_index_r + 1; 
                                        end 
                                    end    
                                    4'b1111 : begin
                                        if (gpio_reg_rdata[13]) begin
                                            ipid_next[ipid_counter_r][15:0] = gpio_reg_rdata[31:16];
                                            ipid_valid_next = ipid_valid_r + 1; 
                                        end 
                                    end                                                                                                                                                                                                                                                                                                                                                                                                            
                                endcase 
                            end
                            2'b10 : begin 
                                if (gpio_reg_rdata[31:16] == 16'hB9B9 && gpio_reg_rdata[13]) begin
                                    gpio_data_type_next = `GPIO_ODATA; 
                                    gpio_wrData_next = `IPID_DONE; // send ip id done 
                                    gpio_RW_next = 1; 
                                    // need a ipid done? 
                                    ipid_counter_next = ipid_counter_r + 1; 
                                    ipid_index_next = 0;
                                    ipid_valid_next = ipid_valid_r + 1; 
                                    ipid_trigger_next = 0; 
                                end 
                            end 
                            2'b11 : begin 
                                gpio_data_type_next = `GPIO_IDATA;
                                gpio_RW_next = 0; 
                                if (gpio_reg_rdata[15]) begin // wait for ip id done ack
                                    ipid_valid_next = 0; 
                                end  
                            end 
                        endcase 
                    end 
                endcase
            end 
        end 

    endcase 

endfunction 

logic [511:0] sha_block_next; 
logic [4:0] hash_counter_r, hash_counter_next; 
logic execute_sha_r, execute_sha_next;
logic sha_init_next; 
logic [255:0] ipid_hash_r, ipid_hash_next; 
logic hash_done_r, hash_done_next; 
logic sha_next_next; 
logic sha_sel_next; 

function void ipid_hash(); // only works for even right now  

    if (execute_sha_r) begin
        sha_init_next =0; 
        if (sha_digest_valid == 1 && sha_ready == 1) begin
            ipid_hash_next = sha_digest; 
            sha_init_next = 0; 
            sha_sel_next = 1; 
            hash_done_next = 1; 
            execute_sha_next = 0; 
            hash_counter_next = 0; 
        end 
    end 
    else begin 
        sha_sel_next = 1; 
        if (hash_counter_r == 0) begin
            sha_block_next = {ipid_r[hash_counter_r+1], ipid_r[hash_counter_r]};
            hash_counter_next = hash_counter_r + 2; 
        end 
        else if (hash_counter_r < ipid_N) begin
             sha_next_next = 1;
             sha_block_next = {ipid_r[hash_counter_r+1], ipid_r[hash_counter_r]};
             hash_counter_next = hash_counter_r + 2; 
        end 
        else begin
            execute_sha_next = 1; 
            sha_next_next = 0; 
            sha_init_next = 1; 
        end 
    end    
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
        ipid_handshake_counter_r <= 0;
        gpio_wrData_r <= 0;
        gpio_reg_access <= 0; 
        gpio_RW_r <= 0; 
        gpio_data_type_r <= 0; 
        ipid_counter_r <= 0; 
        ipid_trigger_r <= 0;
        ipid_valid_r <= 0; 
        ipid_index_r <= 0; 
        ipid_r <= 0; 
        ipid_extraction_done_r <= 0;
        hash_counter_r <= 0; 
        sha_block <= 0; 
        sha_next <= 0;
        execute_sha_r <= 0;
        sha_init <= 0;
        ipid_hash_r <= 0; 
        hash_done_r <= 0; 
        sha_sel <= 1; 
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

        ipid_handshake_counter_r <= ipid_handshake_counter_next;
        gpio_wrData_r <= gpio_wrData_next; 
        gpio_RW_r <= gpio_RW_next; 
        gpio_data_type_r <= gpio_data_type_next; 
        gpio_reg_access <= gpio_reg_access_next; 
        ipid_counter_r <= ipid_counter_next; 
        ipid_trigger_r <= ipid_trigger_next; 
        ipid_valid_r <= ipid_valid_next; 
        ipid_index_r <= ipid_index_next; 
        ipid_r <= ipid_next; 
        ipid_extraction_done_r <= ipid_extraction_done_next; 

        hash_counter_r <= hash_counter_next; 
        sha_block <= sha_block_next; 
        sha_next <= sha_next_next; 
        execute_sha_r <= execute_sha_next; 
        sha_init <= sha_init_next; 
        ipid_hash_r <= ipid_hash_next; 
        hash_done_r <= hash_done_next; 
        sha_sel <= sha_sel_next; 
    end 
end

always_comb begin
    state_next = state_r;
    cam_data_in_next = cam_data_in;
    cam_key_next = cam_key;
    cam_k_len_next = cam_k_len;
    cam_data_rdy_next = cam_data_rdy;
    cam_key_rdy_next = cam_key_rdy;
    cam_enc_dec_next = cam_enc_dec;

    encryption_output_next = encryption_output_r;
    half_next = half_r;
    encryption_done_next = encryption_done_r;

    ipid_handshake_counter_next = ipid_handshake_counter_r;
    gpio_wrData_next = gpio_wrData_r; 
    gpio_RW_next = gpio_RW_r; 
    gpio_reg_access_next = gpio_reg_access; 
    gpio_data_type_next = gpio_data_type_next; 
    ipid_counter_next = ipid_counter_r;
    ipid_trigger_next = ipid_trigger_r; 
    ipid_valid_next = ipid_valid_r; 
    ipid_index_next = ipid_index_r; 
    ipid_next = ipid_r; 
    ipid_extraction_done_next = ipid_extraction_done_r; 

    hash_counter_next = hash_counter_r; 
    sha_next_next = sha_next; 
    execute_sha_next = execute_sha_r; 
    sha_init_next = sha_init; 
    ipid_hash_next = ipid_hash_r;
    hash_done_next = hash_done_r; 
    sha_sel_next = sha_sel; 

    case (state_r) 
        START : begin
            ipid_extraction();
            if (ipid_extraction_done_r) begin
                state_next = FINISH; 
            end 
            /*
            encryption(data_tmp, key_tmp, half_r); 
            if (encryption_done_r) begin
                state_next = FINISH;
                encryption_done_next = 0;
            end 
            */
        end 
        FINISH : begin
            ipid_hash(); 
            if (hash_done_r) begin
                state_next = TEMP;
                hash_done_next = 0; 
                sha_init_next = 0;
            end 
        end 
        TEMP : begin
            ipid_hash(); 
            if (hash_done_r) begin
                state_next = TEMP2;
                hash_done_next = 0; 
                sha_init_next = 0; 
            end 
        end 
        TEMP2 : begin
            ipid_hash(); 
            
        end 
    endcase
end 

endmodule