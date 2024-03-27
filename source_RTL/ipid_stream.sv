`define IPID_START_BITS 16'h7A7A
`define IPID_STOP_BITS 16'hB9B9

module ipid_stream (
    input                 clk,
    input                 rst,
    input                 go,
    input         [255:0] ipid_in,
    output logic          valid,
    output logic  [15:0]  ipid_chunk
);



typedef enum logic [1:0] {START, ACTIVE, FINISH} state_t;
state_t state_r;

logic [5:0] counter_r; 
logic [15:0][15:0] input_r; 

always @(posedge clk, negedge rst) begin
    if (~rst) begin
        counter_r <= 0; 
        state_r <= START; 
        input_r <= 0; 

        valid <= 0;
        ipid_chunk <= 0; 
    end 
    else begin
        case (state_r) 
            START : begin
                if (go) begin
                    input_r[15] <= ipid_in[255:240]; 
                    input_r[14] <= ipid_in[239:224];
                    input_r[13] <= ipid_in[223:208];
                    input_r[12] <= ipid_in[207:192];
                    input_r[11] <= ipid_in[191:176];
                    input_r[10] <= ipid_in[175:160];
                    input_r[9] <= ipid_in[159:144];
                    input_r[8] <= ipid_in[143:128];
                    input_r[7] <= ipid_in[127:112];
                    input_r[6] <= ipid_in[111:96]; 
                    input_r[5] <= ipid_in[95:80];
                    input_r[4] <= ipid_in[79:64];
                    input_r[3] <= ipid_in[63:48];
                    input_r[2] <= ipid_in[47:32];
                    input_r[1] <= ipid_in[31:16];
                    input_r[0] <= ipid_in[15:0];
                    state_r <= ACTIVE;
                    counter_r <= 0; 
                end 
            end 
            ACTIVE : begin
                valid <= 1; 
                if (counter_r == 0) begin
                    ipid_chunk <= `IPID_START_BITS; 
                    counter_r <= counter_r + 1; 
                end 
                else if ( counter_r < 17) begin
                    ipid_chunk <= input_r[counter_r-1];
                    counter_r <= counter_r + 1;
                end 
                else if (counter_r == 17) begin
                    ipid_chunk <= `IPID_STOP_BITS; 
                    counter_r <= counter_r + 1; 
                end 
                else begin
                    state_r <= FINISH;
                    valid <= 0; 
                    ipid_chunk <= 0;
                end 
            end
            FINISH : begin
                if (~go) begin
                    state_r <= START;
                end 
            end  
        endcase 
    end 
end 

endmodule 