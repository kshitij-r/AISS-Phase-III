

`include "mcse_def.svh"


module secure_boot_control # (

    parameter gpio_N                = 32,
    parameter gpio_AW               = 32,
    parameter gpio_PW               = 2*gpio_AW+40,
    parameter memory_width          = 512,
    parameter memory_length         = 6
)
(
    input                                       clk,
    input                                       rst_n,
    input                                       init_config_n, 

    // Camellia to Boot Control
    input [127:0]                               cam_data_out,
    input                                       cam_data_acq,
    input                                       cam_key_acq,
    input                                       cam_output_rdy,
    input [255:0]                               cam_puf_out,

    // SHA to Boot Control
    input [255:0]                               sha_digest,
    input                                       sha_ready,
    input                                       sha_digest_valid,
    input [255:0]                               sha_puf_out,


    // GPIO to Boot Control
    input [gpio_N-1:0]                          gpio_reg_rdata,
    input [gpio_N-1:0]                          gpio_en,
    input                                       gpio_irq,
    input [gpio_N-1:0]                          gpio_ilat,  



    // LC Protection to Boot Control
    input                                       lc_success,
    input                                       lc_done, 
    input [2:0]                                 lc_state,

    // Seucre memory to Boot Control
    input [memory_width-1:0]                    rdData,
    input                                       rdData_valid,

    // *** To Boot Control
    input  [511:0]                              lc_transition_id,
    input                                       lc_transition_request_in,
    input  [511:0]                              lc_authentication_id,
    input                                       lc_authentication_valid, 



    // Boot control to Camellia 
    output logic [127:0]                        cam_data_in,
    output logic [255:0]                        cam_key,
    output logic [1:0]                          cam_k_len,
    output logic                                cam_enc_dec,
    output logic                                cam_data_rdy,
    output logic                                cam_key_rdy,

    // Boot control to SHA
    output logic [511:0]                        sha_block,
    output logic                                sha_init,
    output logic                                sha_next,
    output logic                                sha_sel,


    // Boot Control to GPIO 
    output logic                                gpio_reg_access,
    output logic [gpio_PW-1:0]                  gpio_reg_packet,    


    // Boot control to LC Protection
    output logic                                lc_transition_request,
    output logic [511:0]                        lc_identifier,


    // Boot Control to Secure Memory 
    output logic                                rd_en,
    output logic                                wr_en,
    output logic [$clog2(memory_length)-1:0]    addr,
    output logic [memory_width/2-1:0]             wrData

);


reg [255:0] encryption_output_r, encryption_output_next; 
reg half_r, half_next; 
reg encryption_done_r, encryption_done_next;

typedef enum logic [3:0] {MCSE_INIT, RESET_SOC, LC_AUTH_POLL, LC_AUTH, CHIPID_GEN, CHALLENGE_CHIPID, LC_POLL, LC_TRANSITION, RESET_SOC2, 
LC_FW_POLL, FW_AUTH, NORM_OP_RELEASE, ABORT } state_t;

state_t state_r, state_next;

logic [127:0]                    cam_data_in_next;
logic [255:0]                    cam_key_next;
logic [1:0]                      cam_k_len_next;
logic                           cam_enc_dec_next;
logic                           cam_data_rdy_next;
logic                           cam_key_rdy_next;

logic rd_en_next;
logic wr_en_next;
logic [$clog2(memory_length)-1:0] addr_next;
logic [memory_width/2-1:0] wrData_next; 



function void encryption(input bit [255:0] data_input, input bit [255:0] key_input);
    
    cam_enc_dec_next = 1;
    cam_k_len_next = 2'b10; 
    cam_key_next = key_input; 
    cam_key_rdy_next = 1; 

    case (half_r)
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
        default : begin
            cam_data_in_next = 0;
            cam_data_rdy_next = 0;
            cam_key_rdy_next = 0;
            encryption_done_next = 0; 
        end 
    endcase  
endfunction

 
logic [gpio_N-1:0] gpio_wrData_r, gpio_wrData_next; 
logic [5:0] gpio_data_type_r, gpio_data_type_next; 
logic gpio_RW_r, gpio_RW_next;
logic gpio_reg_access_next; 
assign gpio_reg_packet = {14'h0, gpio_wrData_r, 1'b0, 3'b000, 20'b0,  gpio_data_type_r, 2'b0, 7'b0, gpio_RW_r};



logic [1:0] bus_wakeup_counter_r, bus_wakeup_counter_next; 
logic bus_wakeup_handshake_done_r, bus_wakeup_handshake_done_next; 

function void bus_wakeup_handshake(); 
    if (~bus_wakeup_handshake_done_r) begin
        case (bus_wakeup_counter_r)
            2'b00 : begin // bus wake up
                gpio_wrData_next = `SYS_BUS_WAKEUP;
                gpio_RW_next = 1'b1;
                gpio_data_type_next = `GPIO_ODATA;
                gpio_reg_access_next = 1; 
                bus_wakeup_counter_next = bus_wakeup_counter_r + 1; 
            end 
            2'b01 : begin // wait for bus wake up ack
                gpio_data_type_next = `GPIO_IDATA; 
                gpio_RW_next = 0;
                if (gpio_reg_rdata[7]) begin
                    bus_wakeup_counter_next = bus_wakeup_counter_r + 1; 
                end 
            end  
            2'b10 : begin
                gpio_wrData_next = 0;
                gpio_RW_next = 1'b1;
                gpio_data_type_next = `GPIO_ODATA;
                gpio_reg_access_next = 1; 
                bus_wakeup_counter_next = 0;
                bus_wakeup_handshake_done_next = 1;                  
            end 
        endcase       
    end 
endfunction 



logic [511:0] rdData_r, rdData_next;  
logic memory_read_done_r, memory_read_done_next; 

function void memory_read(input bit [$clog2(memory_length)-1:0] rdAddress);
    if (~memory_read_done_r) begin
        rd_en_next = 1;
        addr_next = rdAddress; 
        
        if (rdData_valid) begin
            rdData_next = rdData; 
            rd_en_next = 0;
            addr_next = 0; 
            memory_read_done_next = 1;
        end
    end 
 
endfunction 

logic memory_write_done_r, memory_write_done_next; 
logic memory_write_counter_r, memory_write_counter_next; 

function void memory_write(input bit [$clog2(memory_length-1):0] writeAddress, input bit [memory_width/2-1:0] writeData);
    if (~memory_write_done_r) begin
        case (memory_write_counter_r) 
            1'b0 : begin
                wr_en_next = 1; 
                addr_next = writeAddress;
                wrData_next = writeData;
                
                memory_write_counter_next = 1; 
            end 
            1'b1 : begin
                wr_en_next = 0; 
                addr_next = 0; 
                memory_write_done_next = 1;
                memory_write_counter_next = 0; 
            end 
        endcase 

    end 
endfunction 

logic [255:0] mcse_id_r, mcse_id_next;
logic [1:0] mcse_id_generation_counter_r, mcse_id_generation_counter_next; 
logic mcse_id_done_r, mcse_id_done_next; 

function void mcse_id_generation();
    if (~mcse_id_done_r) begin
        mcse_id_next = cam_puf_out ^ sha_puf_out;
        mcse_id_done_next = 1; 
    end 
endfunction





logic [1:0] chip_id_generation_counter_r, chip_id_generation_counter_next; 
logic chip_id_generation_done_r, chip_id_generation_done_next;
logic [255:0] chip_id_r, chip_id_next; 

function void chip_id_generation(); 
    if (~chip_id_generation_done_r) begin
        case (chip_id_generation_counter_r) 
            2'b00 : begin
                mcse_id_generation(); 
                if (mcse_id_done_r) begin
                    chip_id_generation_counter_next = 1; 
                    mcse_id_done_next = 0;
                end 
            end 
            2'b01 : begin
                bus_wakeup_handshake(); 
                if (bus_wakeup_handshake_done_r) begin
                    bus_wakeup_handshake_done_next = 0;
                    chip_id_generation_counter_next = chip_id_generation_counter_r + 1; 
                end 
            end 
            2'b10 : begin
                chip_id_next = mcse_id_r;
                chip_id_generation_counter_next = 0;
                chip_id_generation_done_next = 1; 
            end 
            2'b11 : begin

            end 
        endcase 
    end 
endfunction 

logic [1:0] chip_id_challenge_counter_r, chip_id_challenge_counter_next; 
logic authentic_chip_id_r, authentic_chip_id_next;
logic chip_id_challenge_done_r, chip_id_challenge_done_next; 

function void chip_id_challenge();
    if (~chip_id_challenge_done_r) begin
        case (chip_id_challenge_counter_r)
            2'b00 : begin
                chip_id_generation();
                if (chip_id_generation_done_r) begin
                    chip_id_challenge_counter_next = 1; 
                    chip_id_generation_done_next = 0;
                end 
            end 
            2'b01 : begin
                memory_read(`SECURE_COMMUNICATION_KEY_ADDR);
                if (memory_read_done_r) begin
                    encryption(chip_id_r, rdData_r); 
                    if (encryption_done_r) begin
                        chip_id_challenge_counter_next = chip_id_challenge_counter_r + 1; 
                        memory_read_done_next = 0; 
                        encryption_done_next = 0; 
                        rdData_next = 0; 
                    end 
                end 
            end 
            2'b10 : begin
                memory_read(`CHIP_ID_ADDR);
                if (memory_read_done_r) begin
                    if (encryption_output_r == rdData_r) begin
                        authentic_chip_id_next = 1;
                        rdData_next = 0; 
                    end
                    else begin
                        authentic_chip_id_next = 0;
                        rdData_next = 0;  
                    end  
                    chip_id_challenge_done_next = 1; 
                    chip_id_challenge_counter_next = 0; 
                    memory_read_done_next = 0; 
                end  
            end 
        endcase 
    end 

endfunction 

logic lc_transition_request_next;
logic [511:0] lc_identifier_next; 
logic lc_transition_counter_r, lc_transition_counter_next; 
logic lc_transition_done_r, lc_transition_done_next; 
logic lc_transition_success_r, lc_transition_success_next; 

function void lifecycle_transition(input bit [511:0] id);
    if (~lc_transition_done_r) begin
        case (lc_transition_counter_r)
            1'b0 : begin
                lc_transition_request_next = 1;
                lc_identifier_next = id;
                lc_transition_counter_next = lc_transition_counter_r + 1; 
            end
            1'b1 : begin
                lc_transition_request_next = 0;
                lc_identifier_next = 0; 
                if (lc_done) begin
                    lc_transition_counter_next = 0; 
                    lc_transition_done_next = 1; 
                    if (lc_success) begin
                        lc_transition_success_next = 1;
                    end
                    else begin
                        lc_transition_success_next = 0; 
                    end  
                end 
            end 
        endcase 
    end
endfunction 

logic lifecycle_authentication_done_r, lifecycle_authentication_done_next; 
logic lifecycle_authentication_value_r, lifecycle_authentication_value_next; 

function void lifecycle_authentication(input bit [511:0] id); 
    if (~lifecycle_authentication_done_r) begin
        memory_read(`LC_AUTHENTICATION_ID_ADDR_START + lc_state); 
        if (memory_read_done_r) begin
            if (rdData_r == id) begin
                lifecycle_authentication_value_next = 1;
                rdData_next = 0;
            end 
            else begin
                lifecycle_authentication_value_next = 0;
                rdData_next = 0; 
            end 
            lifecycle_authentication_done_next = 1;
            memory_read_done_next = 0; 
        end 
    end 
endfunction 

logic reset_routine_done_r, reset_routine_done_next;
logic [1:0] reset_handshake_counter_r, reset_handshake_counter_next;

function void reset_request();
    if (~reset_routine_done_r) begin
        case (reset_handshake_counter_r)
            2'b00 : begin // send reset
                gpio_wrData_next = `RST_Request;
                gpio_RW_next = 1'b1;
                gpio_data_type_next = `GPIO_ODATA;
                gpio_reg_access_next = 1; 
                reset_handshake_counter_next = reset_handshake_counter_r + 1; 
            end 
            2'b01 : begin // wait for host ack
                gpio_data_type_next = `GPIO_IDATA; 
                gpio_RW_next = 0;
                gpio_reg_access_next = 1;
                if (gpio_reg_rdata[1]) begin
                    reset_routine_done_next = 1;
                    reset_handshake_counter_next = 0;
                end 
            end
            default : begin

            end 
        endcase
    end
endfunction

logic operation_release_done_r, operation_release_done_next;
logic [1:0] operation_release_counter_r, operation_release_counter_next;

function void operation_release_request();
    if (~operation_release_done_r) begin
        case (operation_release_counter_r)
            2'b00 : begin 
                gpio_wrData_next = `Operation_Release_to_Host;
                gpio_RW_next = 1'b1;
                gpio_data_type_next = `GPIO_ODATA;
                gpio_reg_access_next = 1; 
                operation_release_counter_next = operation_release_counter_r + 1; 
            end 
            2'b01 : begin 
                gpio_data_type_next = `GPIO_IDATA; 
                gpio_RW_next = 0;
                if (gpio_reg_rdata[5]) begin
                    operation_release_done_next = 1;
                    operation_release_counter_next =0;
                end 
            end
            default : begin

            end 
        endcase
    end
endfunction

logic [511:0] temp_r, temp_next; 
logic first_boot_flag_r, first_boot_flag_next; 


function void mcse_init(); 
    gpio_RW_next = 1; 
    gpio_wrData_next = 0;
    gpio_data_type_next = `GPIO_ODATA; 
    gpio_reg_access_next = 1;
endfunction

always @(posedge clk, negedge init_config_n) begin
    if (~init_config_n) begin
        first_boot_flag_r <= 1; 
    end 
    else begin
        first_boot_flag_r <= first_boot_flag_next; 
    end 
end 

function void power_off(); 
    gpio_RW_next = 0; 
    gpio_wrData_next = 0;
    gpio_data_type_next = `GPIO_ODATA; 
    gpio_reg_access_next = 0;
endfunction 

always@(posedge clk, negedge rst_n) begin 
    if (~rst_n) begin
        state_r <= MCSE_INIT;

        cam_data_in <= 0;
        cam_key <= 0; 
        cam_k_len <= 2'b10;
        cam_enc_dec <= 1; 
        cam_data_rdy <= 0;
        cam_key_rdy <= 0; 
        encryption_output_r <= 0;
        half_r <= 0; 
        encryption_done_r <= 0; 
        
        gpio_wrData_r <= 0;
        gpio_reg_access <= 0; 
        gpio_RW_r <= 0; 
        gpio_data_type_r <= 0; 
        
        mcse_id_r <= 0; 
        rd_en <= 0;
        wr_en <= 0;
        addr <= 0;
        wrData <= 0; 
        memory_read_done_r <=0;
        rdData_r <= 0; 
        mcse_id_generation_counter_r <= 0; 
        memory_write_done_r <= 0; 
        memory_write_counter_r <= 0;
        mcse_id_done_r <= 0; 
        
        chip_id_generation_counter_r <= 0;
        chip_id_generation_done_r <= 0; 
        chip_id_r <= 0; 
        chip_id_challenge_counter_r <= 0; 
        authentic_chip_id_r <= 0; 
        chip_id_challenge_done_r <= 0;
        lc_transition_request <= 0;
        lc_identifier <= 0; 
        lc_transition_counter_r <= 0;
        lc_transition_done_r <= 0;
         
        temp_r <= 0; 
        lifecycle_authentication_done_r <= 0;
        lifecycle_authentication_value_r <= 0;
        lc_transition_success_r <= 0;
        reset_routine_done_r <= 0; 
        reset_handshake_counter_r <= 0; 
        operation_release_done_r <= 0;
        operation_release_counter_r <= 0; 
        

        bus_wakeup_counter_r <= 0;
        bus_wakeup_handshake_done_r <= 0; 

    end 
    else begin
        state_r <= state_next; 
        
        
        rd_en <= rd_en_next; 
        wr_en <= wr_en_next;
        addr <= addr_next;
        wrData <= wrData_next; 

        cam_data_in <= cam_data_in_next;
        cam_key <= cam_key_next;
        cam_k_len <= cam_k_len_next;
        cam_enc_dec <= cam_enc_dec_next; 
        cam_data_rdy <= cam_data_rdy_next; 
        cam_key_rdy <= cam_key_rdy_next; 
        
        encryption_output_r <= encryption_output_next; 
        half_r <= half_next;
        encryption_done_r <= encryption_done_next; 

        
        gpio_wrData_r <= gpio_wrData_next; 
        gpio_RW_r <= gpio_RW_next; 
        gpio_data_type_r <= gpio_data_type_next; 
        gpio_reg_access <= gpio_reg_access_next; 
        

        mcse_id_r <= mcse_id_next; 
        memory_read_done_r <= memory_read_done_next; 
        rdData_r <= rdData_next; 
        mcse_id_generation_counter_r <= mcse_id_generation_counter_next; 
        memory_write_done_r <= memory_write_done_next; 
        memory_write_counter_r <= memory_write_counter_next; 
        mcse_id_done_r <= mcse_id_done_next; 
         
        chip_id_generation_counter_r <= chip_id_generation_counter_next; 
        chip_id_generation_done_r <= chip_id_generation_done_next; 
        chip_id_r <= chip_id_next;
        chip_id_challenge_counter_r <= chip_id_challenge_counter_next;
        authentic_chip_id_r <= authentic_chip_id_next; 
        chip_id_challenge_done_r <= chip_id_challenge_done_next; 
        lc_transition_request <= lc_transition_request_next;
        lc_identifier <= lc_identifier_next; 
        lc_transition_counter_r <= lc_transition_counter_next; 
        lc_transition_done_r <= lc_transition_done_next; 
       
        temp_r <= temp_next; 
        lifecycle_authentication_done_r <= lifecycle_authentication_done_next; 
        lifecycle_authentication_value_r <= lifecycle_authentication_value_next; 
        lc_transition_success_r <= lc_transition_success_next; 
        reset_routine_done_r <= reset_routine_done_next; 
        reset_handshake_counter_r <= reset_handshake_counter_next; 
        operation_release_done_r <= operation_release_done_next; 
        operation_release_counter_r <= operation_release_counter_next; 

        

        bus_wakeup_counter_r <= bus_wakeup_counter_next; 
        bus_wakeup_handshake_done_r <= bus_wakeup_handshake_done_next; 

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

    
    gpio_wrData_next = gpio_wrData_r; 
    gpio_RW_next = gpio_RW_r; 
    gpio_reg_access_next = gpio_reg_access; 
    gpio_data_type_next = gpio_data_type_next; 
   
    mcse_id_next = mcse_id_r; 
    rd_en_next = rd_en;
    wr_en_next = wr_en; 
    addr_next = addr;
    wrData_next = wrData;
    memory_read_done_next = memory_read_done_r;
    rdData_next = rdData_r;  
    mcse_id_generation_counter_next = mcse_id_generation_counter_r; 
    memory_write_done_next = memory_write_done_r; 
    memory_write_counter_next =  memory_write_counter_r; 
    mcse_id_done_next = mcse_id_done_r; 
    
    chip_id_generation_done_next = chip_id_generation_done_r; 
    chip_id_generation_counter_next = chip_id_generation_counter_r;
    chip_id_next = chip_id_r; 
    chip_id_challenge_counter_next = chip_id_challenge_counter_r; 
    authentic_chip_id_next = authentic_chip_id_r;
    chip_id_challenge_done_next = chip_id_challenge_done_r; 
    lc_transition_request_next = lc_transition_request;
    lc_identifier_next = lc_identifier;
    lc_transition_counter_next = lc_transition_counter_r;
    lc_transition_done_next = lc_transition_done_r;
   
    temp_next = temp_r; 
    lifecycle_authentication_done_next = lifecycle_authentication_done_r;
    lifecycle_authentication_value_next = lifecycle_authentication_value_r; 
    lc_transition_success_next = lc_transition_success_r; 
    reset_routine_done_next = reset_routine_done_r;
    reset_handshake_counter_next = reset_handshake_counter_r; 
    operation_release_done_next = operation_release_done_r;
    operation_release_counter_next =operation_release_counter_r; 
    first_boot_flag_next = first_boot_flag_r; 

    bus_wakeup_counter_next = bus_wakeup_counter_r; 
    bus_wakeup_handshake_done_next = bus_wakeup_handshake_done_r;

    case (state_r) 
        MCSE_INIT : begin
            mcse_init(); 
            state_next = RESET_SOC;
        end 
        RESET_SOC : begin 
            reset_request();
            if (reset_routine_done_r) begin
                reset_routine_done_next = 0; 
                if (first_boot_flag_r) begin
                    if (lc_state == 3'b001) begin
                        state_next = CHIPID_GEN; 
                    end 
                    else begin
                        state_next = LC_AUTH_POLL; 
                    end                 
                end 
                else begin
                    if (lc_state == 3'b001) begin
                        state_next = LC_POLL;
                    end 
                    else if (lc_state == 3'b101) begin
                        state_next = ABORT; 
                    end 
                    else begin
                        state_next = NORM_OP_RELEASE; 
                    end 
                end 
            end 
        end 
        CHIPID_GEN : begin
            chip_id_generation(); 
            if (chip_id_generation_done_r) begin
                memory_read(`SECURE_COMMUNICATION_KEY_ADDR); // fetch secure communication key
                if (memory_read_done_r) begin
                    encryption(chip_id_r, rdData_r); // encrypt chip id with key
                    if (encryption_done_r) begin
                        memory_write(`CHIP_ID_ADDR, encryption_output_r); 
                        if ( memory_write_done_r) begin
                            lc_transition_success_next = 0;
                            lc_transition_done_next = 0; 
                            memory_write_done_next = 0; 
                            chip_id_generation_counter_next = 0;  
                            chip_id_generation_done_next = 0;
                            state_next  = LC_POLL;
                            first_boot_flag_next = 0;  
                            memory_read_done_next = 0; 
                            encryption_done_next = 0; 
                        end 
                    end 
                end 
            end
        end 
        NORM_OP_RELEASE : begin
            operation_release_request(); 
            if (operation_release_done_r) begin
                operation_release_done_next = 0; 
                if (lc_state == 3'b011) begin
                    state_next = LC_POLL;
                end 
                else begin
                    state_next = LC_POLL; 
                end                          
            end 
        end 
        LC_POLL : begin
            if (lc_transition_request_in) begin
                temp_next = lc_transition_id; 
                state_next = LC_TRANSITION;
            end             
        end 
        
        LC_TRANSITION : begin
            lifecycle_transition(temp_r); 
            if (lc_transition_done_r) begin
                if (lc_transition_success_r) begin
                    first_boot_flag_next = 1; 
                    state_next = RESET_SOC2;                
                    lc_transition_done_next = 0;
                end 
                else begin
                    if (lc_state == 3'b010) begin
                        state_next = LC_POLL; 
                    end 
                    else begin
                        state_next = LC_POLL;
                    end 
                end 
            end 
        end 
        LC_AUTH_POLL : begin
            if (lc_authentication_valid) begin
                temp_next = lc_authentication_id;
                state_next = LC_AUTH; 
            end 
        end  
        LC_AUTH : begin
            lifecycle_authentication(temp_r); 
            if (lifecycle_authentication_done_r) begin
                lifecycle_authentication_done_next = 0;
                if (lifecycle_authentication_value_r) begin
                    if (lc_state == 3'b101) begin
                        state_next = ABORT;
                        first_boot_flag_next = 0; 
                    end 
                    else begin
                        state_next = CHALLENGE_CHIPID; 
                    end 
                end 
                else begin
                    state_next = LC_AUTH_POLL;
                end 
            end 
        end  
        CHALLENGE_CHIPID : begin
            chip_id_challenge();
            if (chip_id_challenge_done_r) begin
                encryption_output_next = 0;
                chip_id_challenge_done_next = 0;
                first_boot_flag_next = 0;
                if (authentic_chip_id_r) begin 
                    state_next = NORM_OP_RELEASE; 
                end 
                else begin
                    state_next = ABORT; 
                end 
            end 
        end    
        RESET_SOC2 : begin
            reset_request();
            if (reset_routine_done_r) begin
                 reset_routine_done_next = 0; 
                 state_next = MCSE_INIT; 
            end 
        end     
        ABORT : begin
            power_off(); 
        end 
        default : begin

        end 
    endcase
end 

endmodule