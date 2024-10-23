//Todo---error correction on camellia and sha puf out

`include "mcse_def.svh"

module error_correction # (
    parameter puf_sig_length     = `IPID_WIDTH,
    parameter ipid_N             = `IPID_N
)
(
    input                                clk,
    input                                rst_n,
    input        [1:0]                   pcm_instruction,
    input        [puf_sig_length-1:0]    pcm_puf_in,
    input                                pcm_puf_in_valid,
    input        [$clog2(ipid_N)-1:0]    pcm_ipid_number,

    output logic [puf_sig_length-1:0]    pcm_puf_out,
    output logic                         pcm_puf_out_valid,
    output logic                         pcm_S_c // storage complete 
);  

typedef enum logic [1:0] {IDLE, PROVISION_ID, CORRECT_SIG} state_t;
state_t state_r; 

logic [(6*(puf_sig_length/16))-1:0] parity_bits [0:ipid_N-1];
wire [puf_sig_length-1:0] temp_corrected_out; 

`define IDLE 2'b00
`define PROVISION 2'b01 
`define CORRECT_SIGNATURE 2'b10

genvar j;
generate
    for (j =0; j < puf_sig_length/16; j++) begin
        error_module errorX (.data(pcm_puf_in[((j+1)*16)-1:j*16]), .parity(parity_bits[pcm_ipid_number][((j+1)*6)-1:j*6]), .corrected_out(temp_corrected_out[((j+1)*16)-1:j*16]));
    end 
endgenerate 


always @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
        state_r <= IDLE; 
        //parity_bits = '{default:'0}; 
        pcm_puf_out_valid <= 0;
        pcm_puf_out <= 0; 
        pcm_S_c <= 0; 
    end 
    else begin
        case (state_r) 
            IDLE : begin
                pcm_S_c <= 0; 
                pcm_puf_out_valid <= 0;
                pcm_puf_out_valid <= 0;
                if (pcm_instruction == `PROVISION) begin
                    state_r <= PROVISION_ID; 
                end 
                else if (pcm_instruction == `CORRECT_SIGNATURE) begin
                    state_r <= CORRECT_SIG; 
                end 
            end 
            PROVISION_ID : begin // using a version of hamming code SECDED - single error correcting double error detecting code
                // 16 bits of data will have 6 bits of parity
                if (pcm_puf_in_valid) begin 
                    for (int i = 0; i < puf_sig_length/16; i++) begin
                        parity_bits[pcm_ipid_number][0+(6*i)] <= pcm_puf_in[2+(16*i)] ^ pcm_puf_in[5+(16*i)] ^ pcm_puf_in[7+(16*i)] ^ pcm_puf_in[9+(16*i)] ^ pcm_puf_in[11+(16*i)] ^ pcm_puf_in[14+(16*i)];
                        parity_bits[pcm_ipid_number][1+(6*i)] <= pcm_puf_in[1+(16*i)] ^ pcm_puf_in[4+(16*i)] ^ pcm_puf_in[7+(16*i)] ^ pcm_puf_in[8+(16*i)] ^ pcm_puf_in[10+(16*i)] ^ pcm_puf_in[13+(16*i)] ^ pcm_puf_in[14+(16*i)] ^ pcm_puf_in[15+(16*i)];
                        parity_bits[pcm_ipid_number][2+(6*i)] <= pcm_puf_in[0+(16*i)] ^ pcm_puf_in[4+(16*i)] ^ pcm_puf_in[5+(16*i)] ^ pcm_puf_in[6+(16*i)] ^ pcm_puf_in[9+(16*i)] ^ pcm_puf_in[10+(16*i)] ^ pcm_puf_in[11+(16*i)] ^ pcm_puf_in[12+(16*i)] ^ pcm_puf_in[14+(16*i)] ^ pcm_puf_in[15+(16*i)];
                        parity_bits[pcm_ipid_number][3+(6*i)] <= pcm_puf_in[0+(16*i)] ^ pcm_puf_in[1+(16*i)] ^ pcm_puf_in[2+(16*i)] ^ pcm_puf_in[3+(16*i)] ^ pcm_puf_in[4+(16*i)] ^ pcm_puf_in[9+(16*i)] ^ pcm_puf_in[10+(16*i)] ^ pcm_puf_in[11+(16*i)] ^ pcm_puf_in[12+(16*i)] ^ pcm_puf_in[13+(16*i)] ^ pcm_puf_in[14+(16*i)] ^ pcm_puf_in[15+(16*i)];
                        parity_bits[pcm_ipid_number][4+(6*i)] <= pcm_puf_in[3+(16*i)] ^ pcm_puf_in[6+(16*i)] ^ pcm_puf_in[8+(16*i)] ^ pcm_puf_in[9+(16*i)] ^ pcm_puf_in[12+(16*i)]  ^ pcm_puf_in[13+(16*i)] ^ pcm_puf_in[15+(16*i)];
                        parity_bits[pcm_ipid_number][5+(6*i)] <= pcm_puf_in[0+(16*i)] ^ pcm_puf_in[1+(16*i)] ^ pcm_puf_in[2+(16*i)] ^ pcm_puf_in[3+(16*i)] ^ pcm_puf_in[4+(16*i)] ^ pcm_puf_in[5+(16*i)] ^ pcm_puf_in[6+(16*i)] ^ pcm_puf_in[7+(16*i)] ^ pcm_puf_in[8+(16*i)] ^ pcm_puf_in[9+(16*i)] ^ pcm_puf_in[14+(16*i)] ^ pcm_puf_in[15+(16*i)];                 
                    end 
                    pcm_S_c <= 1; 
                    if (pcm_instruction == `IDLE) begin 
                        state_r <= IDLE; 
                        pcm_S_c <= 0; 
                    end 
                end 
                
            end 
            CORRECT_SIG : begin
                pcm_puf_out <= temp_corrected_out; 
                pcm_puf_out_valid <= 1;
                if (pcm_instruction == `IDLE) begin
                    state_r <= IDLE; 
                end 
            end 
        endcase 
    end 
end 




endmodule 

module error_module (
    input   [15:0]  data, 
    input   [5:0]   parity, 
    output logic [15:0]  corrected_out
    );
	
	wire ContG = 1'b1;
	wire ContH = 1'b0;
	wire ContB = 1'b0;
	wire ContE = 1'b0;
	wire ContF = 1'b1;
	wire ContK = 1'b1;
	wire ContL = 1'b1;
    wire ByteParLo1, ByteParHi1;
	wire UncorrError1;
    wire [5 :0] OutSynCheckBits;
	
	c1908 error_correction_1 (.InDataBus(data), .InCheckBits(parity), .InExtSynBits(4'b0000), 
	.ContE(ContE), .ContB(ContB), .ContF(ContF), .ContG(ContG), .ContH(ContH), .ContK(ContK), .ContL(ContL),
	.OutDataBus(corrected_out), .ByteParLo(ByteParLo1), .ByteParHi(ByteParHi1), .UncorrError(UncorrError1),
	.OutSynCheckBits(OutSynCheckBits));
	
endmodule