`timescale 1ns/1ps  // Set timescale for simulation accuracy

// Include necessary files
`include "ResetHostSoC.sv"


module tb_func;

   parameter  N      = 24;      // number of gpio pins
   parameter  AW     = 32;      // address width
   parameter  PW     = 2*AW+40; // packet width   
   parameter  ID     = 0;       // block id to match to, bits [10:8]

   // Signals
   reg nreset, clk, reg_access;
   reg [PW-1:0] reg_packet;
   reg [N-1:0] gpio_in;
   wire [31:0] reg_rdata;
   wire [N-1:0] gpio_out, gpio_en;
   wire gpio_irq;
   wire [31:0] gpio_ilat;
   reg interrupt;

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

   // Clock generation
   initial begin
      clk = 0;
      forever #5 clk = ~clk; 
   end

initial begin

    gpio_in[1] = 1;
    ResetRoutine();
end

endmodule
