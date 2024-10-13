//file name "MTD3L_completion.sv"
//module list: compmtd3l, compdmtd3l, compinmtd3l, compmtd3l_clk
//MTD3L completion blocks 
//compmtd3l:  resets ko(high)
//compdmtd3l: resets ko(low)
//compinmtd3l: resets ko (high), used only for synchronous to MTD3L input interface
//compmtd3l_clk: compm with internal clock output pin for input interface fo sync-to-MTD3L
//compnmtd3l_sr: resets ko(high)

//Instance list: th22n_a XOR2_A inv_a NOR2_A OR2_A andtreem
// DATE        Version           Description
//8-16-2022      1.0              Original
//10-18-2022     2.0              add compnmtd3l_sr

//`include "NCL_signals.pkg.sv"   -- dual_rail_logic
//`include "NCL_gates.v"          -- th22n_a 
//`include "BOOLEAN_gates.v"      -- XOR2_A inv_a NOR2_A OR2_A
//`include "MTNCL_treecomps.sv"   -- andtreem

//------------------------------------------------//
//------------module compmtd3l--------------------//
//------------------------------------------------//
//reset ko to high --request for DATA
//work with MTD3L register: genregmtd3l, genregdmtd3l, genregnmtd3l
//instances list: andtreem, th22n_a, inv_a, XOR2_A, NOR2_A, OR2_A, BUFFER_A
module compmtd3l #(parameter width = 4) (a, ki, rst, sleep, ps, not_ps, ko, s0, ns1);

  // inport package into module scope	
	import NCL_signals::*; 
	
  input dual_rail_logic [width-1:0] a;
  input logic ki, rst, sleep, ps, not_ps;
  output logic ko, s0, ns1;
  
  wire logic [width-1:0] XOR_outputs; 
  wire logic comp_signal;
  wire logic not_ko;
  wire logic temp_ko_1, temp_ko_2;
  

//First stage --- DATA/SPACER detection 
  genvar i;
  generate
    for (i=0; i<width; i++)  begin
	  XOR2_A u_xor (.A(a[i].rail1), .B(a[i].rail0), .Z(XOR_outputs[i])); 
	end
  endgenerate
  
//Second stage --- AND tree with MTNCL th44m_a, th33m_a, th22m_a
     andtreem  #(.width(width)) u_completion_tree (.a(XOR_outputs), .sleep(sleep), .ko(comp_signal));
 
//Third stage --- Synchronization with next stage ki and invertion
  //Synchronize with th22n_a reset ttko to 1'b0
  th22n_a u_not_ko (.a(comp_signal), .b(ki), .rst(rst), .z(not_ko));
  //Invertion with inv_a
  inv_a u_inv_ko (.a(not_ko), .z(ko));
  //Generate s0
  NOR2_A u_nor_s0 (.A(not_ko), .B(not_ps), .Z(s0));				//not_ko="1", DATA in register inputs, s0=0.   ="0", SPACER in register inputs, s0=not(not_ps)
  //Generate ns1
  OR2_A u_or_ns1 (.A(not_ko), .B(ps), .Z(ns1));  				//not_ko="1", DATA in register intpus, ns1=1.  ="0", SPACER in register inputs, ns1=ps
endmodule //compmtd3l
//------------------------------------------------//  
//------------module compdmtd3l-------------------//
//------------------------------------------------//
//reset ko to low  --request for SPACER
//work with MTD3L register: genregmtd3l, genregdmtd3l, genregnmtd3l
//instances list: andtreem, th22d_a, inv_a, XOR2_A, NOR2_A, OR2_A, BUFFER_A
module compdmtd3l #(parameter width = 4) (a, ki, rst, sleep, ps, not_ps, ko, s0, ns1);

  // inport package into module scope	
	import NCL_signals::*; 
	
  input dual_rail_logic [width-1:0] a;
  input logic ki, rst, sleep, ps, not_ps;
  output logic ko, s0, ns1;
  
  wire logic [width-1:0] XOR_outputs; 
  wire logic comp_signal;
  wire logic not_ko;
  wire logic temp_ko_1, temp_ko_2;
  

//First stage --- DATA/SPACER detection 
  genvar i;
  generate
    for (i=0; i<width; i++)  begin
	  XOR2_A u_xor (.A(a[i].rail1), .B(a[i].rail0), .Z(XOR_outputs[i])); 
	end
  endgenerate
  
//Second stage --- AND tree with MTNCL th44m_a, th33m_a, th22m_a
     andtreem  #(.width(width)) u_completion_tree (.a(XOR_outputs), .sleep(sleep), .ko(comp_signal));
 
//Third stage --- Synchronization with next stage ki and invertion
  //Synchronize with th22d_a reset ttko to 1'b1
  th22d_a u_not_ko (.a(comp_signal), .b(ki), .rst(rst), .z(not_ko));
  //Invertion with inv_a
  inv_a u_inv_ko (.a(not_ko), .z(ko));
  //Generate s0
  NOR2_A u_nor_s0(.A(not_ko), .B(not_ps), .Z(s0));
  //Generate ns1
  OR2_A u_or_ns1 (.A(not_ko), .B(ps), .Z(ns1));  
endmodule //compdmtd3l 

//------------------------------------------------//
//------------module compinmtd3l------------------//
//------------------------------------------------//
//reset ko to high --request for DATA
//work with MTD3L register: genregmtd3l, genregdmtd3l, genregnmtd3l
//instances list: th22d_a, inv_a, XOR2_A, NOR2_A, OR2_A
module compinmtd3l ( ki, rst, sleep, ps, not_ps, ko, s0, ns1);
  input logic ki, rst, sleep, ps, not_ps;
  output logic ko, s0, ns1;
  
  wire logic comp_signal;
  wire logic not_ko;
  wire logic temp_ko_1, temp_ko_2;
  
  assign comp_signal = sleep;	 //sleep="1"--SPACER, sleep='0'--DATA
 
//Third stage --- Synchronization with next stage ki and invertion
  //Synchronize with th22n_a reset ttko to 1'b0
  th22n_a u_not_ko (.a(comp_signal), .b(ki), .rst(rst), .z(not_ko));
  //Invertion with inv_a
  inv_a u_inv_ko (.a(not_ko), .z(ko));
  //Generate s0
  NOR2_A u_nor_s0 (.A(not_ko), .B(not_ps), .Z(s0));				//not_ko="1", DATA in register inputs, s0=0.   ="0", SPACER in register inputs, s0=not(not_ps)
  //Generate ns1
  OR2_A u_or_ns1 (.A(not_ko), .B(ps), .Z(ns1));  				//not_ko="1", DATA in register intpus, ns1=1.  ="0", SPACER in register inputs, ns1=ps
endmodule //compinmtd3l


//------------------------------------------------//
//------------module compmtd3l_clk------------------//
//------------------------------------------------//
//reset ko to high --request for DATA
//work with MTD3L register: genregmtd3l, genregdmtd3l, genregnmtd3l
//instances list: andtreem, th22n_a, inv_a, XOR2_A, NOR2_A, OR2_A, BUFFER_A
module compmtd3l_clk #(parameter width = 4) (a, ki, rst, sleep, ko, clk);

  // inport package into module scope	
	import NCL_signals::*; 
	
  input dual_rail_logic [width-1:0] a;
  input logic ki, rst, sleep;
  output logic ko, clk;
  
  wire logic [width-1:0] XOR_outputs; 
  wire logic comp_signal;
  wire logic not_ko;
  

//First stage --- DATA/SPACER detection 
  genvar i;
  generate
    for (i=0; i<width; i++)  begin
	  XOR2_A u_xor (.A(a[i].rail1), .B(a[i].rail0), .Z(XOR_outputs[i])); 
	end
  endgenerate
  
//Second stage --- AND tree with MTNCL th44m_a, th33m_a, th22m_a
     andtreem  #(.width(width)) u_completion_tree (.a(XOR_outputs), .sleep(sleep), .ko(comp_signal));
 
//Third stage --- Synchronization with next stage ki and invertion
  //Synchronize with th22n_a reset ttko to 1'b0
  th22n_a u_not_ko (.a(comp_signal), .b(ki), .rst(rst), .z(not_ko));
  //Invertion with inv_a
  inv_a u_inv_ko (.a(not_ko), .z(ko));
  
//Generate clock for data capture
  assign clk = comp_signal;
  
endmodule //compmtd3l_clk

//------------------------------------------------//
//------------module compnmtd3l_sr--------------------//
//------------------------------------------------//
//reset ko to high --request for DATA
//work with MTD3L register: genregmtd3l, genregdmtd3l, genregnmtd3l
//instances list: andtreem, th22n_a, inv_a, XOR2_A, NOR2_A, OR2_A, BUFFER_A
module compnmtd3l_sr #(parameter width = 4) (zd, ki, rst, sleep, zr1, zr0, ko, ko_c, s0, ns1);

  // inport package into module scope	
	import NCL_signals::*; 
	
  input logic [width-1:0] zd;
  input logic ki, rst, sleep, zr1, zr0;
  output logic ko, ko_c, s0, ns1;
  
  wire logic ds;
  wire logic not_ko;
  wire logic temp_ko_1, temp_ko_2;
  

//First stage --- DATA/SPACER detection //moved to MTD3L registers
  
//Second stage --- AND tree with MTNCL th44m_a, th33m_a, th22m_a
     andtreem  #(.width(width)) u_completion_tree (.a(zd), .sleep(sleep), .ko(ds));
 
//Third stage --- Synchronization with next stage ki and invertion
	spacer u_spacer (.ds(ds), .ki(ki), .zr1(zr1), .zr0(zr0), .rst(rst), .ko(ko), .s0(s0), .ns1(ns1), .ko_c(ko_c));
	
endmodule //compnmtd3l_sr