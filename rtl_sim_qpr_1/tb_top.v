`timescale 1ns/1ns
`include "gpio_regmap.v"
module min_security_module_tb;
    // Define parameters for the testbench
    localparam data_width = 32;
    localparam addr_width = 32;
    localparam puf_sig_length = 256;
    localparam valid_byte_offset = 16;
    localparam parity_bits_width = 48;
    localparam N = 24;
    localparam AW = 32;
    localparam PW = 2*AW+40;
    localparam ID = 0;

    reg clk; 
    reg rst;
    
    /*
    IO interface for AES256 inside the minimum security module
    */
    reg [127:0]   aes_state;
    reg [255:0]   aes_key;
    reg           aes_start;
    reg           aes_sel;
    wire [127:0]  aes_out;
    wire          aes_out_valid;
    wire [255:0]  aes_pufout;

    /*
    IO interface for SHA256 inside the minimum security module
    */
    reg [511:0]   sha_block;
    reg           sha_init;
    reg           sha_next;
    reg           sha_sel;
    wire [255:0]  sha_digest;
    wire          sha_ready;
    wire          sha_digest_valid;
    wire [255:0]  sha_pufout;

    /*
    IO interface for PUF Control Module (PCM) inside the minimum security module
    */
    reg [puf_sig_length-1 : 0]   sig_in;
    reg [data_width-1 : 0]       IP_ID_in;
	reg [2:0]                    Instruction_in;
	reg                          sig_valid;
    wire [data_width-1 : 0]  control_out;
	wire [data_width-1 : 0]  status;
    wire                     comp_out;
    wire                     S_c;
	wire                     A_c;

    /*
    IO interface for Boot Control (GPIO) inside the minimum security module
    */
  //  reg           nreset;      
    reg 	        reg_access;
    reg  [N-1:0]  gpio_in;
    reg [PW-1:0]  reg_packet;
    wire [31:0]   reg_rdata;   
    wire [N-1:0]  gpio_out;   
    wire [N-1:0]  gpio_en;   
    wire 	        gpio_irq; 
    wire [31:0]   gpio_ilat;

//reg [255:0] rand;

min_security_module  #(
        .data_width(data_width),
        .addr_width(addr_width),
        .puf_sig_length(puf_sig_length),
        .valid_byte_offset(valid_byte_offset),
        .parity_bits_width(parity_bits_width),
        .N(N),
        .AW(AW),
        .PW(PW),
        .ID(ID)
    ) dut (
            .clk(clk),
        .rst(rst),
        .aes_state(aes_state),
        .aes_key(aes_key),
        .aes_start(aes_start),
        .aes_sel(aes_sel),
        .aes_out(aes_out),
        .aes_out_valid(aes_out_valid),
        .aes_pufout(aes_pufout),
        .sha_block(sha_block),
        .sha_init(sha_init),
        .sha_next(sha_next),
        .sha_sel(sha_sel),
        .sha_digest(sha_digest),
        .sha_ready(sha_ready),
        .sha_digest_valid(sha_digest_valid),
        .sha_pufout(sha_pufout),
        .sig_in(sig_in),
        .IP_ID_in(IP_ID_in),
        .Instruction_in(Instruction_in),
        .sig_valid(sig_valid),
        .control_out(control_out),
        .status(status),
        .comp_out(comp_out),
        .S_c(S_c),
        .A_c(A_c),
      //  .nreset(nreset),
        .reg_access(reg_access),
        .gpio_in(gpio_in),
        .reg_packet(reg_packet),
        .reg_rdata(reg_rdata),
        . gpio_out ( gpio_out), 
         .gpio_en ( gpio_en),
         .gpio_irq ( gpio_irq),
         .gpio_ilat ( gpio_ilat)
  
  
    );
integer i, j;
reg control;
initial begin
    rst = 1;
    reg_access = 0;
    clk = 1;
    control = 1;
    reg_packet = {2*32+40-1{1'b0}};
    gpio_in = {24{1'b0}};
    i=0;
    j=0;
   
    #10 rst = 0;
    reg_access = 1;
    i =0;
    j=0;

       // Pass 10 random 256-bit hexadecimal numbers through to gpio_in[23:8]
 while (j<10) begin
     
       $display("Passing %d th signature in slices", j);
      
    for (i = 0; i < 32; i =i+1) begin
   //    @(posedge clk);
        //control pin controls the wr/rd. if 1, it writes else reads.
        if (control) begin
        // Generate random number
        // Drive gpio_in with random number
            gpio_in[23:8] = $urandom_range(0,65536);
             $display("Writing random signature slices: %h", dut.boot_control.idata_reg[23:8]);
            end
            
          else begin

              $display("Reading back  signature slices: %h", reg_rdata[23:8]);
        end  
           
               $display("value of i : %d", i);
            // Enable write in specific address to allow read data back
            reg_packet = {6'h0,  32'd0, 1'b0,  3'b000, 16'b0, 24'b0, `GPIO_IDATA, 2'b0, 7'b0, control};
    
       #10;
 
       end
       j = j+1;
    end
    
    // End test bench
    #10 rst = 1;
    reg_access = 0;
 //   $dumpfile("gpio_tb.vcd");
  //$dumpvars(0, gpio_tb);
    #10 $finish;
    
end

always begin
     #5 clk = ~clk;
  
end
always begin
      #10 control = ~control;
end
endmodule
