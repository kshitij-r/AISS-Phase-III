
`include "mcse_def.svh"

module fw_authentication # (
    parameter gpio_N                = 32,
    parameter gpio_AW               = 32,
    parameter gpio_PW               = 2*gpio_AW+40,
    parameter pAHB_ADDR_WIDTH       = 32,
    parameter pPAYLOAD_SIZE_BITS    = 128,
    parameter fw_image_N            = `FW_N, 
    parameter fw_block_width        = `FW_WIDTH,
    parameter memory_width          = `SECURE_MEMORY_WIDTH,
    parameter memory_length         = `SECURE_MEMORY_LENGTH
)
(
    input                            clk,
    input                            rst_n,

    input                            fw_authentication_trigger,


// sha to FW authentication module
    input [255:0]                               sha_digest,
    input                                       sha_ready,
    input                                       sha_digest_valid,
    input [255:0]                               sha_puf_out,


// Bus Translation unit to FW authentication module 
    input                                       bootControl_bus_done,
    input [pPAYLOAD_SIZE_BITS-1:0]              bootControl_bus_rdData,  

 // Secure memory to FW authentication module
    input [memory_width-1:0]                    rdData,
    input                                       rdData_valid,  


// FW authentication module to sha
    output logic [511:0]                        fw_sha_block,
    output logic                                fw_sha_init,
    output logic                                fw_sha_next,
    output logic                                fw_sha_sel,


// FW Authentication module to Bus Translation unit 
    output logic                                fw_bootControl_bus_go,
    output logic [pAHB_ADDR_WIDTH-1:0]          fw_bootControl_bus_addr,
    output logic [pPAYLOAD_SIZE_BITS-1:0]       fw_bootControl_bus_write,
    output logic                                fw_bootControl_bus_RW, 

// FW authentication module to Secure Memory 
    output logic                                fw_rd_en,
    output logic                                fw_wr_en,
    output logic [$clog2(memory_length)-1:0]    fw_addr,
    output logic [memory_width-1:0]             fw_wrData,

    output logic                                 fw_auth_result,
    output logic                                 fw_auth_done
);

localparam [pAHB_ADDR_WIDTH-1:0]   fw_address [0:fw_image_N-1] = `FW_ADDR_MAP;

typedef enum logic [2:0] {AUTHENTICATION, FINISH} state_t;
state_t state_r, state_next;



logic                          bootControl_bus_go_next;
logic [pAHB_ADDR_WIDTH-1:0]    bootControl_bus_addr_next;
logic [pPAYLOAD_SIZE_BITS-1:0] bootControl_bus_write_next;
logic                          bootControl_bus_RW_next;  

logic [fw_image_N-1:0][fw_block_width-1:0] fw_r, fw_next;
logic fw_RW_counter_r, fw_RW_counter_next;
logic [4:0] fw_counter_r, fw_counter_next;
logic fw_extraction_done_r, fw_extraction_done_next;



function void fw_extraction();
    if (~fw_extraction_done_r) begin
        if (fw_counter_r >= fw_image_N) begin // checks if entire fw image has been extracted or not
            fw_extraction_done_next = 1;
            fw_counter_next = 0;
            // fw_handshake_counter_next = 0;
        end
        else begin
            case (fw_RW_counter_r)
                1'b0: begin
                    bootControl_bus_addr_next = fw_address[fw_counter_r];
                    bootControl_bus_RW_next = 0;
                    bootControl_bus_go_next = 1;
                    fw_RW_counter_next = 1;
                end 
                1'b1: begin
                    bootControl_bus_addr_next = 0;
                    bootControl_bus_RW_next = 0;
                    bootControl_bus_go_next = 0;
                    if (bootControl_bus_done) begin
                       fw_next[fw_counter_r] = bootControl_bus_rdData;
                       fw_counter_next = fw_counter_r + 1;
                       fw_RW_counter_next = 0; 
                    end
                end
            endcase
        end
    end   
endfunction

logic rd_en_next;
logic [$clog2(memory_length)-1:0] addr_next;
logic [255:0] rdData_r, rdData_next;  
logic memory_read_done_r, memory_read_done_next; 

function void memory_read(input bit [$clog2(memory_length)-1:0] rdAddress);
    if (~memory_read_done_r) begin
        rd_en_next = 1;
        addr_next = rdAddress; 
        // $display("address = ", addr_next);
        if (rdData_valid) begin
            rdData_next = rdData; 
            rd_en_next = 0;
            addr_next = 0; 
            memory_read_done_next = 1;
        end
    end 
endfunction 



logic [511:0] sha_block_next; 
logic [3:0] hash_counter_r, hash_counter_next; 
logic sha_init_next; 
logic [255:0] fw_hash_r, fw_hash_next; 
logic hash_done_r, hash_done_next; 
logic sha_next_next; 
logic sha_sel_next; 
logic [1:0] strobe_r, strobe_next; 


logic [255:0] ipad_xor;
logic [255:0] opad_xor;
logic [255:0] ipad_xor_next;
logic [255:0] opad_xor_next;
logic [255:0] signing_key;
logic [fw_image_N:0][fw_block_width-1:0] fw_for_hmac;
logic [fw_block_width-1:0] signature_challenge;
logic [fw_image_N-2:0][fw_block_width-1:0] fw_temp;



assign signature_challenge = fw_r [0];


function void fw_hash(); 
    if (~hash_done_r) begin
        for (int i = 1; i < 9; i = i + 1) begin
            fw_temp[i-1] = fw_r[i];
        end
        fw_for_hmac = {opad_xor_next, fw_temp, ipad_xor_next};
        if (hash_counter_r == 0) begin       
            sha_block_next = {fw_for_hmac[hash_counter_r+1], fw_for_hmac[hash_counter_r]};
            
            case (strobe_r) 
                2'b00 : begin
                    sha_init_next = 1; 
                    strobe_next = 1; 
                end 
                2'b01 : begin
                    sha_init_next = 0;
                    strobe_next = strobe_r +1; 
                end 
                2'b10 : begin
                    if (sha_ready) begin
                        strobe_next = 0; 
                        hash_counter_next = hash_counter_r + 2;
                    end 
                end 
                default : begin

                end 
            endcase 
        end 
        else if (hash_counter_r < 10) begin
            if (hash_counter_r + 1 == 10) begin
                sha_block_next = {256'h0, fw_r[hash_counter_r]};
            end
            else begin
                sha_block_next = {fw_for_hmac[hash_counter_r+1], fw_for_hmac[hash_counter_r]};
            end
            case (strobe_r) 
                2'b00 : begin
                    sha_next_next = 1;
                    strobe_next = 1; 
                end 
                2'b01 : begin
                    sha_next_next = 0; 
                    strobe_next = strobe_r + 1; 
                end 
                2'b10 : begin
                    if (sha_ready) begin
                        strobe_next = 0;
                        hash_counter_next = hash_counter_r + 2; 
                    end 
                end 
                default : begin

                end 
            endcase 
        end 
        else begin
            fw_hash_next = sha_digest; 
            hash_counter_next = 0; 
            sha_block_next = 0;
            strobe_next = 0; 
            hash_done_next = 1; 
        end 
    end
endfunction



logic fw_authentication_done_r, fw_authentication_done_next; 
logic fw_authentication_value_r, fw_authentication_value_next; 
logic [1:0] fw_authentication_counter_r, fw_authentication_counter_next;
logic fw_auth_done_next;
logic fw_auth_result_next;

function fw_authentication();
  if (fw_authentication_trigger) begin
    if (~fw_authentication_done_r) begin
        case (fw_authentication_counter_r)
            2'b00 : begin
                fw_extraction();
                if (fw_extraction_done_r) begin
                fw_authentication_counter_next = fw_authentication_counter_r + 1;
                fw_extraction_done_next = 0;
                end
            end 
        2'b01: begin
            memory_read(`FW_SIGNING_KEY_ADDR);
            if (memory_read_done_r) begin
                signing_key = rdData_next;
                ipad_xor_next = `IPAD ^ signing_key;
                opad_xor_next = `OPAD ^ signing_key;
                memory_read_done_next = 0;
                fw_authentication_counter_next = fw_authentication_counter_r + 1;
            end
        end
            2'b10: begin
                fw_hash();
                if (hash_done_r) begin
                hash_done_next = 0;
                fw_authentication_counter_next = fw_authentication_counter_r + 1;
                end
            end
            2'b11 : begin
                if (sha_digest == signature_challenge) begin
                  fw_authentication_value_next = 1;
                  fw_auth_result_next = 1;
                  fw_auth_done_next = 1;
                end
                else begin
                    fw_authentication_value_next = 0;
                    fw_auth_result_next = 0;
                    fw_auth_done_next = 1;
                end
                fw_authentication_done_next = 1;
                fw_authentication_counter_next = 0;
            end 
        endcase
    end
end
endfunction



always @(posedge clk, negedge rst_n) begin 
    if (~rst_n) begin
        state_r <= AUTHENTICATION;

        ipad_xor <= 0;
        opad_xor <=0;

        fw_extraction_done_r <= 0;
        fw_counter_r <= 0;
        fw_r <= 0;
        fw_RW_counter_r <= 0;
        
        fw_bootControl_bus_go <= 0;
        fw_bootControl_bus_addr <= 0;
        fw_bootControl_bus_write <= 0; 
        fw_bootControl_bus_RW <= 0;

        fw_rd_en <= 0;
        fw_addr <= 0;
        memory_read_done_r <=0;
        rdData_r <= 0;

        hash_counter_r <= 0; 
        fw_sha_block <= 0; 
        fw_sha_next <= 0;
        fw_sha_init <= 0;
        fw_hash_r <= 0; 
        hash_done_r <= 0; 
        fw_sha_sel <= 1; 
        strobe_r <= 0; 
        

        fw_authentication_done_r <= 0;
        fw_authentication_value_r <= 0;
        fw_authentication_counter_r <= 0;
        fw_auth_done <= 0;
        fw_auth_result <= 0;
        

    end 
    else begin
        state_r <= state_next; 

        ipad_xor <= ipad_xor_next;
        opad_xor <= opad_xor_next;
        
        fw_rd_en <= rd_en_next; 
        fw_addr <= addr_next;
        memory_read_done_r <= memory_read_done_next; 
        rdData_r <= rdData_next; 

        fw_extraction_done_r <= fw_extraction_done_next;
        fw_counter_r <= fw_counter_next;
        fw_r <= fw_next;
        fw_RW_counter_r <= fw_RW_counter_next;
        
        fw_bootControl_bus_go <= bootControl_bus_go_next;
        fw_bootControl_bus_addr <= bootControl_bus_addr_next; 
        fw_bootControl_bus_write <= bootControl_bus_write_next; 
        fw_bootControl_bus_RW <= bootControl_bus_RW_next; 

        
        hash_counter_r <= hash_counter_next; 
        fw_sha_block <= sha_block_next; 
        fw_sha_next <= sha_next_next; 
        fw_sha_init <= sha_init_next; 
        fw_hash_r <= fw_hash_next; 
        hash_done_r <= hash_done_next; 
        fw_sha_sel <= sha_sel_next; 
        strobe_r <= strobe_next;     

        fw_authentication_done_r <= fw_authentication_done_next;
        fw_authentication_value_r <= fw_authentication_value_next; 
        fw_authentication_counter_r <= fw_authentication_counter_next;

        fw_auth_done <= fw_auth_done_next;
        fw_auth_result <= fw_auth_result_next;

    end 
end

always_comb begin
    state_next = state_r;

    ipad_xor_next = ipad_xor;
    opad_xor_next = opad_xor;
    
    rd_en_next = fw_rd_en;
    addr_next = fw_addr;
    memory_read_done_next = memory_read_done_r;
    rdData_next = rdData_r; 
    
    fw_extraction_done_next = fw_extraction_done_r;
    fw_next = fw_r;
    fw_counter_next = fw_counter_r;
    fw_RW_counter_next = fw_RW_counter_r;

    bootControl_bus_go_next = fw_bootControl_bus_go;
    bootControl_bus_addr_next = fw_bootControl_bus_addr; 
    bootControl_bus_write_next = fw_bootControl_bus_write; 
    bootControl_bus_RW_next = fw_bootControl_bus_RW; 

    hash_counter_next = hash_counter_r; 
    sha_block_next = fw_sha_block;
    sha_next_next = fw_sha_next; 
    sha_init_next = fw_sha_init; 
    fw_hash_next = fw_hash_r;
    hash_done_next = hash_done_r; 
    sha_sel_next = fw_sha_sel; 
    strobe_next = strobe_r; 

    
    
    fw_authentication_done_next = fw_authentication_done_r;
    fw_authentication_value_next = fw_authentication_value_r;
    fw_authentication_counter_next = fw_authentication_counter_r;
    fw_auth_done_next = fw_auth_done;
    fw_auth_result_next = fw_auth_result;



    case (state_r)
        AUTHENTICATION: begin
            fw_authentication();
            if (fw_authentication_done_r) begin
                state_next = FINISH; 
                fw_authentication_done_next = 0; 
            end 
        end 
        FINISH : begin
            if (~fw_authentication_trigger) begin
                fw_auth_done_next = 0; 
                fw_auth_result_next = 0; 
                state_next = AUTHENTICATION; 
            end 

        end 

        default : begin
            
        end
    endcase
end

endmodule