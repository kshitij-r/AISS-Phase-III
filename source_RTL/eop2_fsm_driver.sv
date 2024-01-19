`include "min_security_module.sv"
`define GPIO_IDATA 6'h5
module eop2_fsm_driver(
input clk,
input rst,
input [127:0]   cam_data_in,
input [255:0]   cam_key,
input [511:0]   sha_block,
input           sha_init,
input           sha_next,
input           sha_sel,
input  [24-1:0] gpio_in,
output [24-1:0] gpio_out,
output [24-1:0] gpio_en,
output 	        gpio_irq,    
output [31:0]   gpio_ilat

//output [255:0] mem_out[0:2]
);
reg [24-1:0] gpio_out;
reg [24-1:0] gpio_en;   
reg 	        gpio_irq;    
reg [31:0]   gpio_ilat;
wire [255:0] sha_puf_out;
wire [255:0] cam_puf_out;
wire [127:0] aes_out;
wire [255:0] sha_dig;
wire  sha_dig_v;
wire sha_rd;
reg aes_out_val;
reg ctr_rst;
reg [127:0] aes_st;
reg  aes_strt;
reg  aes_select;
reg [511:0] sha_blk;
reg sha_int;
reg sha_nxt;
reg sha_slt;
reg proc_part;
reg [127:0] chip_man_id;
reg [256:0] store_chip_man_id_hash;
reg [127:0] sys_int_id;
reg [256:0] store_sys_int_id_hash;
reg reg_access;
reg [104-1:0]reg_packet;
reg [31:0]   reg_rdata;
reg store_val;

reg [1:0] counter;
reg counter1;
reg counter2;
reg [3:0] counter3;
reg [3:0] counter4;
reg [3:0] counter5;
reg [3:0] counter6;
reg [3:0] counter7;
reg completed_state7;
reg [1:0] counter8;

parameter STATE1 = 2'b00;
parameter STATE2 = 2'b01;
parameter STATE3 = 2'b10;
parameter STATE4 = 3'b011;
parameter STATE5 = 3'b100;
parameter STATE6 = 3'b101;
parameter STATE7 = 3'b110;

reg [2:0] current_state;
reg [2:0] next_state;
reg [255:0] mem1 ;
reg [255:0] mem2 ;
reg [255:0] mem3 ;
reg [255:0] mem4 ;
reg [255:0] mem_out;
reg [255:0] key;
reg [0:9][255:0] store ;
reg [0:9][255:0] store_enc ;
reg enc;
reg [3:0] current_state1;
reg do_sha;
reg execute_sha;
reg end_storing;
reg [255:0] compare_hash;
reg flag;
reg [255:0] hard_coded_hash;
reg end_sha;
reg [255:0] store_aes;
reg begin_state_6;
reg one;
reg [2:0] choose_out;
reg two;
reg [3:0] sha_enc_i;
reg [255:0] fsm_enc_out;
reg end_state_3;
reg end_state_4;

reg [127:0] data_in;
reg [0:1] k_len;
reg enc_dec;
reg data_rdy;
reg key_rdy;
reg [127:0] data_out;
reg data_acq;
reg key_acq;
reg output_rdy;

min_security_module #(32,32,256,16,48,24,32,2*32+40,0) m1(.clk(clk),.rst(ctr_rst),.data_in(data_in),
    .key(key),
    .k_len(k_len),
    .enc_dec(enc_dec),
    .data_rdy(data_rdy),
    .key_rdy(key_rdy),
    .data_out(data_out),
    .data_acq(data_acq),
    .key_acq(key_acq),
    .output_rdy(output_rdy),
    .cam_pufout(cam_puf_out),.sha_block(sha_blk),
.sha_init(sha_int),.sha_next(sha_nxt),.sha_sel(sha_slt),.sha_digest(sha_dig),.sha_ready(sha_rd),.sha_digest_valid(sha_dig_v),.sha_pufout(sha_puf_out),
.sig_in(),.IP_ID_in(),.Instruction_in(),.sig_valid(),.control_out(),.status(),.comp_out(),
.S_c(),.A_c(), .reg_access(reg_access),.gpio_in(gpio_in),.reg_packet(reg_packet),.reg_rdata(reg_rdata),.gpio_out(gpio_out),.gpio_en(gpio_en),.gpio_irq(gpio_irq),.gpio_ilat(gpio_ilat));

always @( posedge clk) begin
    if(rst) begin
        current_state <= STATE1;
        
    end
    else begin
        current_state<=next_state;
    
    end
    
end

always @ (posedge clk) begin
    case (current_state)
        STATE1: begin
            ctr_rst<=1;
            next_state<=STATE2;
            mem4<=256'h0;
            store<=0;
            counter<=0;
            counter1<=0;
            counter2<=0;
            counter3<=0;
            counter4<=0;
            counter5<=0;
            execute_sha<=0;
            do_sha<=0;
            sha_blk<=0;
            sha_nxt<=0;
            flag<=0;
            begin_state_6<=0;
            one<=1;
        end 
        STATE2: begin
            
            data_in<=cam_data_in;
            sha_slt<=1'b1;
            mem1<=cam_puf_out;
            mem2<=sha_puf_out;
            mem3<=mem1 ^ mem2;
            next_state<=STATE3;
            proc_part<=2'b0;
        end
        STATE3: begin
            
            ctr_rst<=0;
            if(proc_part == 0) begin
                
                data_in<=mem3[255:128];
                enc_dec<=1;
                data_rdy<=1;
                key <= cam_key;
                k_len<=2'b10;
                key_rdy<=1;
                if(key_acq==1) begin
                    key_rdy<=0;
                end
                if(output_rdy ==1) begin
                    mem4[255:128]<=data_out;
                    proc_part<=1;
                    ctr_rst<=1;
                end        
            end
            else if(proc_part==1) begin
                ctr_rst<=0;
		        data_in<=mem3[127:0];
                enc_dec<=1;
                data_rdy<=1;
                key <= cam_key;
                k_len<=2'b10;
                key_rdy<=1;
                if(key_acq==1) begin
                    key_rdy<=0;
                end
                if(output_rdy ==1) begin
                    proc_part<=1'bx;
                    mem4[127:0]<=data_out;
			        end_state_3<=1;
                    next_state<=STATE4;
                    key_rdy<=0;
                    data_rdy<=0;
                    ctr_rst<=1;
                    sha_int<=0;
                    store_val<=0;
                    counter<=0;
                    execute_sha<=0;
                    do_sha<=0;
                    end_storing<=0;
                end
            end            
        end
	STATE4: begin
        counter1<=0;
        counter2<=0;
		reg_access<=1;
        reg_packet<= {6'h0,  32'd0, 1'b0,  3'b000, 16'b0, 24'b0, `GPIO_IDATA, 2'b0, 7'b0, 1'b0};
        if(counter5==4'b1010) begin
            end_state_4<=1;
            hard_coded_hash<=256'hb2959f02f8a864225a24d90b1f0180c98eea668dd6404835cfe1eb4666923c6d;
            next_state<=STATE5;
        end
        if(counter==2'b11 && end_storing==0) begin
            store_val<=1;
            counter<=0;    
        end
        else begin
            counter<=counter+1;
        end
        if(counter3==15) begin
            counter3<=0;
            counter4<=counter4+1;
        end
        if(counter4==4'b1010) begin
            store_val<=0;
            end_storing<=1;
            if(execute_sha==1) begin
                do_sha<=0;    
            end
            else begin
                do_sha<=1;
                counter4<=0;
            end 
        end
        if(do_sha==1) begin
            ctr_rst<=0;
            do_sha<=0;
            sha_int<=1;
            sha_blk<=store[counter4];
            execute_sha<=1;
        end
        if(execute_sha==1) begin
            sha_int<=0;
            if(sha_rd==1 && sha_dig_v==1) begin
                store[counter4]<=sha_dig;
                if(counter4==4'b1010) begin
                    end_sha<=1;
                    counter4<=0;
                    do_sha<=0;
                    end_state_4<=1;
                    hard_coded_hash<=256'hb2959f02f8a864225a24d90b1f0180c98eea668dd6404835cfe1eb4666923c6d;
                end
                else begin
                    counter4<=counter4+1;
                    counter5<=counter5+1;
                    do_sha<=1;
                end 
                execute_sha<=0;
                ctr_rst<=1;
            end
        end
        
        if(store_val==1) begin
            case (counter3)
                4'b0000: begin
                    store[counter4][255:240]<=reg_rdata[23:8];
                    counter3<=counter3+1;
                end 
                4'b0001: begin
                    store[counter4][239:224]<=reg_rdata[23:8];
                    counter3<=counter3+1;
                end
                4'b0010: begin
                    store[counter4][223:208]<=reg_rdata[23:8];
                    counter3<=counter3+1;
                end
                4'b0011: begin
                    store[counter4][207:192]<=reg_rdata[23:8];
                    counter3<=counter3+1;
                end
                4'b0100: begin
                    store[counter4][191:176]<=reg_rdata[23:8];
                    counter3<=counter3+1;
                end
                4'b0101: begin
                    store[counter4][175:160]<=reg_rdata[23:8];
                    counter3<=counter3+1;
                end
                4'b0110: begin
                    store[counter4][159:144]<=reg_rdata[23:8];
                    counter3<=counter3+1;
                end
                4'b0111: begin
                    store[counter4][143:128]<=reg_rdata[23:8];
                    counter3<=counter3+1;
                end
                4'b1000: begin
                    store[counter4][127:112]<=reg_rdata[23:8];
                    counter3<=counter3+1;
                end
                4'b1001: begin
                    store[counter4][111:96]<=reg_rdata[23:8];
                    counter3<=counter3+1;
                end
                4'b1010: begin
                    store[counter4][95:80]<=reg_rdata[23:8];
                    counter3<=counter3+1;
                end
                4'b1011: begin
                    store[counter4][79:64]<=reg_rdata[23:8];
                    counter3<=counter3+1;
                end
                4'b1100: begin
                    store[counter4][63:48]<=reg_rdata[23:8];
                    counter3<=counter3+1;
                end
                4'b1101: begin
                    store[counter4][47:32]<=reg_rdata[23:8];
                    counter3<=counter3+1;
                end
                4'b1110: begin
                    store[counter4][31:16]<=reg_rdata[23:8];
                    counter3<=counter3+1;
                end
                4'b1111: begin
                    store[counter4][15:0]<=reg_rdata[23:8];
                    counter3<=counter3+1;
                end
            endcase
        end
    end
    STATE5: begin
        ctr_rst<=1;
        if(compare_hash==hard_coded_hash) begin
            flag<=1;
        end
        else begin
            flag<=0;
        end
        if(begin_state_6==1) begin
            next_state<=STATE6;
            proc_part<=0;
            counter6<=0;
            counter7<=0;
            enc<=1;
            ctr_rst<=1;
            fsm_enc_out<=0;
            two<=0;
            choose_out<=0;
        end
    end
    STATE6: begin
        store_aes<=mem4;
        ctr_rst<=0;
        if(enc==1) begin
            if(proc_part==0) begin
                ctr_rst<=0;
                data_in<=store[counter6][255:128];
                enc_dec<=1;
                data_rdy<=1;
                key <= cam_key;
                k_len<=2'b10;
                key_rdy<=1;
                if(key_acq==1) begin
                    key_rdy<=0;
                end
                if(output_rdy ==1) begin
                    store_enc[counter6][255:128]<=data_out;
                    proc_part<=1;
                    ctr_rst<=1;
                end
            end
            else if(proc_part==1) begin
                ctr_rst<=0;
                data_in<=store[counter6][127:0];
                enc_dec<=1;
                data_rdy<=1;
                key <= cam_key;
                k_len<=2'b10;
                key_rdy<=1;
                if(key_acq==1) begin
                    key_rdy<=0;
                end
                if(output_rdy ==1) begin
                    store_enc[counter6][127:0]<=data_out;
                    proc_part<=0;
                    ctr_rst<=1;
                    if(counter6==4'b1001) begin
                        enc<=0;
                    end
                    counter6<=counter6+1;
                end
            end
        end
        if(counter6==4'b1010) begin
            if(choose_out==1) begin
                fsm_enc_out<=store_aes;
            end
            else if(choose_out==2) begin
                fsm_enc_out<=store_enc[sha_enc_i];
            end
            else if(choose_out==3) begin
                next_state<=STATE7;
                chip_man_id<=128'hB417FBD37F3C94200832CFAC92B60AFF;
                sys_int_id<=128'hBFBD2555F1947E6530FBD82749A7D906;
                ctr_rst<=1;
                do_sha<=1;
                execute_sha<=0;
                counter8<=0;
            end
        end
    end
    STATE7: begin
        if(do_sha==1 && counter8==0) begin
            ctr_rst<=0;
            do_sha<=0;
            sha_int<=1;
            sha_blk<=chip_man_id;
            execute_sha<=1;
        end
        else if(do_sha==1 && counter8==1) begin
            ctr_rst<=0;
            do_sha<=0;
            sha_int<=1;
            sha_blk<=sys_int_id;
            execute_sha<=1;
        end
        if(execute_sha==1 && counter8==0) begin
            sha_int<=0;
            if(sha_rd==1 && sha_dig_v==1) begin
                execute_sha<=0;
                store_chip_man_id_hash<=sha_dig;
                do_sha<=1;
                counter8<=counter8+1;
                ctr_rst<=1;
            end
        end
        else if(execute_sha==1 && counter8==1) begin
            sha_int<=0;
            if(sha_rd==1 && sha_dig_v==1) begin
                store_sys_int_id_hash<=sha_dig;
                
                counter8<=counter8+1;
                execute_sha<=0;
            end
        end
        if(counter8==2) begin
            completed_state7<=1;
        end
    end
    default: 
        next_state<=STATE1;
    endcase
end

endmodule
