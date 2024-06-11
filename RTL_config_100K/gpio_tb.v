`timescale 1ns/1ps  // Set timescale for simulation accuracy

// Include necessary files
`include "gpio_regmap.v"
`include "gpio.v"  
`include "packet2emesh.v"
`include "io.v"
`include "oh_dsync.v"


module tb_gpio;

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

   // Readback functionality

   initial begin
      // Initialize signals
      nreset = 1;
      reg_access = 0;
      reg_packet = 104'b0;
     
   
      // Release reset after a short delay
      #50 nreset = 0;

      // Write to reg_packet and read from gpio_out
      #20 
      reg_access = 1;
      reg_packet = {6'h0,  32'h1, 1'b0,  3'b000, 16'b1, 24'b0, `GPIO_ODATA, 2'b0, 7'b0, 1'b1}; 
      #20
      $display("gpio_out: %b", gpio_out);
      #20

      // #20
      // reg_packet = {6'h0,  28'h1, 4'b1001, 1'b0,  3'b001, 16'b1, 24'b0, `GPIO_ODATA, 2'b0, 7'b0, 1'b1}; 
      // #20
      // $display("gpio_out: %b", gpio_out);

      // #20
      // reg_packet = {6'h0,  28'h1, 4'b1011, 1'b0,  3'b001, 16'b1, 24'b0, `GPIO_ODATA, 2'b0, 7'b0, 1'b1}; 
      // #20
      // $display("gpio_out: %b", gpio_out);

      // #20
      // reg_packet = {6'h0,  28'h1, 4'b1111, 1'b0,  3'b001, 16'b1, 24'b0, `GPIO_ODATA, 2'b0, 7'b0, 1'b1}; 
      // #20
      // $display("gpio_out: %b", gpio_out);

      // #20
      // reg_packet = {6'h0,  26'h0, 4'b1111, 6'b0, 4'b0011, 8'b0, 2'b11, 26'b0, `GPIO_ODATA, 7'b0, 1'b1}; 
      // #20
      // $display("gpio_out: %b", gpio_out);
      // #20;

      // write to gpio_in and read from reg_rdata
      //write to gpio_in (`GPIO_IDATA)
      reg_access = 0;
      gpio_in = 24'b10;
      #20
      //reading from reg_rdata
      reg_packet = {14'h0,  24'h0, 1'b0, 3'b000, 20'b0, `GPIO_IDATA, 2'b0, 7'b0, 1'b0};
      #20
      // reg_packet = {14'h0,  24'h0, 1'b0, 3'b000, 20'b0, `GPIO_ILAT, 2'b0, 7'b0, 1'b0};
      // #20
      // reg_packet = {14'h0,  24'h0, 1'b0, 3'b000, 20'b0, `GPIO_ILATAND, 2'b0, 7'b0, 1'b0};
      // 14'h0, gpio_wrData_r, 1'b0, 3'b000, 20'b0,  gpio_data_type_r, 2'b0, 7'b0, gpio_RW_r

      $display("reg_rdata: %b", reg_rdata);
      // $display("gpio_ilat: %b", gpio_ilat);
      // $display("gpio_irq: %b", gpio_irq);
     



      $finish;
   end

endmodule
