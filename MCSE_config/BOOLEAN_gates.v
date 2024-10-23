// Verilog model for BOOLEAN gates 
// Gate list -- inv_a  and2_a or2_a xor2_a xnor2_a BUFFER_A MUX21_A LATNQ DFFRPQ DFFRPQB DFFRPQN PREICG SDFFRPQ
// UDP list -- udp_mux2 udp_mux udp_dff udp_tlat 
// date                version         description
// May-25-2022          1.0               Change cell names to cooresponds to OA library
// JUN-3-2022           1.1             add PREICG SDFFRPQ udp_mux 
// JUN-4-2022           1.2             add DFFRPQN
// AUG-16-2022          2.0             Change name to CAPITAL 
`define BOOL_DP  			#0.010
`define BUF_A_DP			#0.010

/////////////////////////////////////
//inv_a
////////////////////////////////////
`timescale 1ns/10ps
`celldefine
module inv_a (a, z);
output z;
input a;
  not `BOOL_DP I1(z, a);
endmodule // inv_a
`endcelldefine

/////////////////////////////////////
//and2_a
////////////////////////////////////
`timescale 1ns/10ps
`celldefine
module and2_a (a, b, z);
output z;
input a, b;
  and `BOOL_DP I1(z, a, b);
endmodule // and2_a
`endcelldefine

/////////////////////////////////////
//OR2_A
////////////////////////////////////
`timescale 1ns/10ps
`celldefine
module OR2_A (A, B, Z);
output Z;
input A, B;
  or `BOOL_DP I1(Z, A, B);
endmodule // OR2_A
`endcelldefine

/////////////////////////////////////
//NOR2_A
////////////////////////////////////
`timescale 1ns/10ps
`celldefine
module NOR2_A (A, B, Z);
output Z;
input A, B;
  nor `BOOL_DP I1(Z, A, B);
endmodule // NOR2_A
`endcelldefine

/////////////////////////////////////
//XOR2_A
////////////////////////////////////
`timescale 1ns/10ps
`celldefine
module XOR2_A (A, B, Z);
output Z;
input A, B;
  xor `BOOL_DP I1(Z, A, B);
endmodule // XOR2_A
`endcelldefine

/////////////////////////////////////
//XNOR2_A
////////////////////////////////////
`timescale 1ns/10ps
`celldefine
module XNOR2_A (a, b, z);
output z;
input a, b;
  xnor `BOOL_DP I1(z, a, b);
endmodule // XNOR2_A
`endcelldefine

/////////////////////////////////////
//BUFFER_A
////////////////////////////////////
`timescale 1ns/10ps
`celldefine
module BUFFER_A (A, Z);
output Z;
input A;
  buf `BUF_A_DP I1(Z, A); 
  //buf `BOOL_DP I1(Z, A);  
endmodule // BUFFER_A
`endcelldefine

/////////////////////////////////////
//BUFFER_B
////////////////////////////////////
`timescale 1ns/10ps
`celldefine
module BUFFER_B (A, Z);
output Z;
input A;
  buf `BOOL_DP I1(Z, A);
endmodule // BUFFER_B
`endcelldefine

/////////////////////////////////////
//BUFFER_C
////////////////////////////////////
`timescale 1ns/10ps
`celldefine
module BUFFER_C (A, Z);
output Z;
input A;
  buf `BOOL_DP I1(Z, A);
endmodule // BUFFER_C
`endcelldefine

/////////////////////////////////////
//BUFFER_D
////////////////////////////////////
`timescale 1ns/10ps
`celldefine
module BUFFER_D (A, Z);
output Z;
input A;
  buf `BOOL_DP I1(Z, A);
endmodule // BUFFER_D
`endcelldefine

/////////////////////////////////////
//BUFFER_E
////////////////////////////////////
`timescale 1ns/10ps
`celldefine
module BUFFER_E (A, Z);
output Z;
input A;
  buf `BOOL_DP I1(Z, A);
endmodule // BUFFER_E
`endcelldefine

/////////////////////////////////////
//MUX21_A
////////////////////////////////////
`timescale 1ns/10ps
`celldefine
module MUX21_A (z, a, b, s);
output z;
input a, b, s;

  udp_mux2 u0(z_int, a, b, s);
  buf `BOOL_DP I1(z, z_int);
endmodule
`endcelldefine

/////////////////////////////////////
//LATNQ
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module LATNQ (Q, D, GN);
output  Q;
input  D, GN;
reg NOTIFIER;
supply1 xRN, xSN;

udp_tlat I0 (n0, D, clk, xRN, xSN, NOTIFIER);
buf   `BOOL_DP   I1 (Q, n0);
buf      I3 (clk, GN);
endmodule //LATNQ_X3M_A12TR
`endcelldefine

/////////////////////////////////////
//DFFRPQ
////////////////////////////////////
`timescale 1ns/10ps
`celldefine
module DFFRPQ (Q, CK, D, R);
output Q;
input  D, CK, R;
reg NOTIFIER;
supply1 xSN;

  not   XX0 (xRN, R);
  buf   IC (clk, CK);
  udp_dff I0 (n0, D, clk, xRN, xSN, NOTIFIER);
  buf    `BOOL_DP I1 (Q, n0);
endmodule
`endcelldefine

/////////////////////////////////////
//DFFRPQB
////////////////////////////////////
`timescale 1ns/10ps
`celldefine
module DFFRPQB (QB, CK, D, R);
output QB;
input  D, CK, R;
reg NOTIFIER;
supply1 xSN;

  not   XX0 (xRN, R);
  buf   IC (clk, CK);
  udp_dff I0 (n0, D, clk, xRN, xSN, NOTIFIER);
  not    `BOOL_DP I1 (QB, n0);
endmodule
`endcelldefine

/////////////////////////////////////
//DFFRPQN
////////////////////////////////////
`timescale 1ns/10ps
`celldefine
module DFFRPQN (QN, CK, D, R);
output QN;
input  D, CK, R;
reg NOTIFIER;
supply1 xSN;

  not   XX0 (xRN, R);
  buf   IC (clk, CK);
  udp_dff I0 (n0, D, clk, xRN, xSN, NOTIFIER);
  not    `BOOL_DP I1 (QN, n0);
endmodule //DFFRPQN
`endcelldefine

/////////////////////////////////////
//PREICG
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module PREICG (ECK, CK, E, SE);
output ECK;
input  E, SE, CK;
reg NOTIFIER;

supply1 R, S;

  or       I0 (n1, SE, E);
  udp_tlat I1 (n0, n1, CK, R, S, NOTIFIER);
  and     `BOOL_DP   I2 (ECK, n0, CK);
endmodule //PREICG
`endcelldefine

/////////////////////////////////////
//SDFFRPQ
////////////////////////////////////
`timescale 1ns/10ps
`celldefine
module SDFFRPQ (Q, CK, D, R, SE, SI);
output Q;
input D, SI, SE, CK, R;
reg NOTIFIER;
supply1 xSN;

  not   XX0 (xRN, R); 
  buf    IC (clk, CK);
  udp_dff I0 (n0, n1, clk, xRN, xSN, NOTIFIER);
  udp_mux I1 (n1, D, SI, SE);
  buf   `BOOL_DP  I2 (Q, n0);
endmodule //SDFFRPQ
`endcelldefine


/////////////////////////////////////
//udp_mux2
////////////////////////////////////
`ifdef udp_mux2_READ
`else
primitive udp_mux2 (out, in0, in1, sel);
   output out;  
   input  in0, in1, sel;

   table

// in0 in1  sel :  out
//
   1  ?   0  :  1 ;
   0  ?   0  :  0 ;
   ?  1   1  :  1 ;
   ?  0   1  :  0 ;
   0  0   x  :  0 ;
   1  1   x  :  1 ;

   endtable
endprimitive // udp_mux2
`endif

/////////////////////////////////////
//udp_mux
////////////////////////////////////
`ifdef udp_mux_READ
`else
primitive udp_mux (out, in, s_in, s_sel);
   output out;  
   input  in, s_in, s_sel;

   table

// in  s_in  s_sel :  out
//
   1  ?   0  :  1 ;
   0  ?   0  :  0 ;
   ?  1   1  :  1 ;
   ?  0   1  :  0 ;
   0  0   x  :  0 ;
   1  1   x  :  1 ;

   endtable
endprimitive // udp_mux
`endif

/////////////////////////////////////
//udp_dff
////////////////////////////////////
`ifdef udp_dff_READ
`else
primitive udp_dff (out, in, clk, clr_, set_, NOTIFIER);
   output out;  
   input  in, clk, clr_, set_, NOTIFIER;
   reg    out;

   table

// in  clk  clr_   set_  NOT  : Qt : Qt+1
//
   0  r   ?   1   ?   : ?  :  0  ; // clock in 0
   1  r   1   ?   ?   : ?  :  1  ; // clock in 1
   1  *   1   ?   ?   : 1  :  1  ; // reduce pessimism
   0  *   ?   1   ?   : 0  :  0  ; // reduce pessimism
   ?  f   ?   ?   ?   : ?  :  -  ; // no changes on negedge clk
   *  b   ?   ?   ?   : ?  :  -  ; // no changes when in switches
   ?  ?   ?   0   ?   : ?  :  1  ; // set output
   ?  b   1   *   ?   : 1  :  1  ; // cover all transistions on set_
   1  x   1   *   ?   : 1  :  1  ; // cover all transistions on set_
   ?  ?   0   1   ?   : ?  :  0  ; // reset output
   ?  b   *   1   ?   : 0  :  0  ; // cover all transistions on clr_
   0  x   *   1   ?   : 0  :  0  ; // cover all transistions on clr_
   ?  ?   ?   ?   *   : ?  :  x  ; // any notifier changed

   endtable
endprimitive // udp_dff
`endif

/////////////////////////////////////
//udp_tlat
////////////////////////////////////
`ifdef udp_tlat_READ
`else
primitive udp_tlat (out, in, hold, clr_, set_, NOTIFIER);
   output out;  
   input  in, hold, clr_, set_, NOTIFIER;
   reg    out;

   table

// in  hold  clr_   set_  NOT  : Qt : Qt+1
//
   1  0   1   ?   ?   : ?  :  1  ; // 
   0  0   ?   1   ?   : ?  :  0  ; // 
   1  *   1   ?   ?   : 1  :  1  ; // reduce pessimism
   0  *   ?   1   ?   : 0  :  0  ; // reduce pessimism
   *  1   ?   ?   ?   : ?  :  -  ; // no changes when in switches
   ?  ?   ?   0   ?   : ?  :  1  ; // set output
   ?  1   1   *   ?   : 1  :  1  ; // cover all transistions on set_
   1  ?   1   *   ?   : 1  :  1  ; // cover all transistions on set_
   ?  ?   0   1   ?   : ?  :  0  ; // reset output
   ?  1   *   1   ?   : 0  :  0  ; // cover all transistions on clr_
   0  ?   *   1   ?   : 0  :  0  ; // cover all transistions on clr_
   ?  ?   ?   ?   *   : ?  :  x  ; // any notifier changed

   endtable
endprimitive // udp_tlat
`endif

`define udp_mux2_READ
`define udp_mux_READ
`define udp_dff_READ
`define udp_tlat_READ
