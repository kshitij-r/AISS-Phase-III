
// Include necessary files
`include "gpio_regmap.v"
`include "gpio.v"  
`include "packet2emesh.v"
`include "io.v"
`include "oh_dsync.v"

module HandofftoHost(
    // Outputs
   reg_rdata, gpio_out, gpio_en, gpio_irq, gpio_ilat,
   // Inputs
   nreset, clk, reg_access, reg_packet, gpio_in
   );

   parameter  N      = 24;      // number of gpio pins
   parameter  AW     = 32;      // address width
   parameter  PW     = 2*AW+40; // packet width   
   parameter  ID     = 0;       // block id to match to, bits [10:8]
      
   //clk, reset
   input           nreset;      // asynchronous active low reset
   input 	   clk;         // clock

   //register access interface
   input 	   reg_access;  // register access (read only)
   input [PW-1:0]  reg_packet;  // data/address
   output [31:0]   reg_rdata;   // readback data

   //IO signals
   output [N-1:0]  gpio_out;    // data to drive to IO pins
   output [N-1:0]  gpio_en;     // tristate enables for IO pins
   input  [N-1:0]  gpio_in;     // data from IO pins
   
   //global interrupt   
   output 	   gpio_irq;    // or of all interrupts
   output [31:0]   gpio_ilat;   // individual interrupt outputs

   // Instantiate the GPIO module
   gpio gpio_inst (
      .nreset(nreset),
      .clk(clk),
      .reg_access(reg_access),
      .reg_packet(reg_packet),
      .gpio_in(gpio_in),
      .reg_rdata(reg_rdata),
      .gpio_out(gpio_out),
      .gpio_en(gpio_en),
      .gpio_irq(gpio_irq),
      .gpio_ilat(gpio_ilat)
   );

   

function automatic void HandoffRoutine();
    
    reg reg_access;
    reg [PW-1:0] reg_packet;

    reg_access = 1;
    // release normal operation to Host through this packet; indicating gpio_out[4] should read 1
    reg_packet = {32'hx,  27'b0, 1'b1, 4'b0, 23'b0, `GPIO_ODATA, 3'b0, 7'b0, 1'b1};
    //give read access to reg_rdata so that gpio_in can be monitored
    reg_packet = {6'h0,  32'b0000, 1'b0,  3'b000, 20'b0, `GPIO_IDATA, 2'b0, 7'b0, 1'b0};
    if (gpio_out[4] & reg_rdata[5]) begin // wait for ack by monitoring reg_radat[1]
        // as soon as reg_rdata[5] reads high, release the handoff pin i.e. send another packet to make gpio_out[4]=0 
        reg_packet = {32'hx,  27'b0, 1'b1, 4'b0, 23'b0, `GPIO_ODATA, 3'b0, 7'b0, 1'b1}; 
    end
endfunction


endmodule