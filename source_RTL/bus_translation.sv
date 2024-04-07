`define         AHB_DATA_WIDTH_BITS                 32

module bus_translation # (
    parameter   pAHB_ADDR_WIDTH                     = 32,
    parameter   pAHB_DATA_WIDTH                     = `AHB_DATA_WIDTH_BITS,
    parameter   pPAYLOAD_SIZE_BITS                  = 128
)
(
    input  wire                           clk,
    input  wire                           rst_n,
    input  wire [pPAYLOAD_SIZE_BITS-1:0]  O_int_rdata,
    input  wire                           O_int_rdata_valid,
    input  wire                           O_done, 

    input  wire                           bootControl_bus_go,
    input  wire [pAHB_ADDR_WIDTH-1:0]     bootControl_bus_addr,
    input  wire [pPAYLOAD_SIZE_BITS-1:0]  bootControl_bus_write,
    input  wire                           bootControl_bus_RW,      



    output logic [pAHB_ADDR_WIDTH-1:0]    I_int_addr,
    output logic [pPAYLOAD_SIZE_BITS-1:0] I_int_wdata,
    output logic                          I_int_write,
    output logic                          I_go,

    output logic                          bootControl_bus_done,
    output logic [pPAYLOAD_SIZE_BITS-1:0] bootControl_bus_rdData 
);

typedef enum logic [1:0] {START, WRITE, READ} state_t;
state_t state_r;

logic [3:0] counter; 

always @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
        I_int_addr <= 0;
        I_int_wdata <= 0;
        I_int_write <= 0;
        I_go <= 0;
        bootControl_bus_done <= 0; 
        bootControl_bus_rdData <= 0; 
        state_r <= START; 
        counter <= 0; 
    end 
    else begin
        case (state_r)
            START : begin
                bootControl_bus_done <= 0; 
                if (bootControl_bus_go) begin
                    
                    if (bootControl_bus_RW) begin
                        I_go <= bootControl_bus_go; 
                        I_int_addr <= bootControl_bus_addr;
                        I_int_wdata <= bootControl_bus_write;
                        I_int_write <= bootControl_bus_RW;
                        state_r <= WRITE; 
                    end 
                    else begin
                        I_go <= bootControl_bus_go;
                        I_int_addr <= bootControl_bus_addr;
                        I_int_write <= bootControl_bus_RW; 
                        state_r <= READ; 
                    end 
                end 
            end 
            WRITE : begin
                I_go <= 0; 
                if (O_done) begin
                    I_int_addr <= 0;
                    I_int_wdata <= 0;
                    I_int_write <= 0;
                    bootControl_bus_done <= 1;
                    state_r <= START;
                end 
            end 
            READ : begin
                I_go <= 0;
                if (counter < 10 ) begin
                    counter <= counter + 1; 
                end 
                else begin 
                    if (O_int_rdata_valid) begin
                        I_int_addr <= 0;
                        I_int_wdata <= 0;
                        I_int_write <= 0;
                        bootControl_bus_rdData <= O_int_rdata;
                        bootControl_bus_done <= 1; 
                        state_r <= START; 
                        counter <= 0; 
                    end 
                end 
            end
        endcase 
    end 
end 

endmodule 