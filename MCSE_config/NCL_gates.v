// Verilog model for NCL gates
// Verilog model for MTNCL gates
// Gate list -- th12b_a th12_a th13_a th14_a th22_a th22d_a th22db_a th22n_a th22nb_a th23_a th23w2_a th24_a th24w2_a th24w22_a  th24comp_a
//              th33_a th33d_a th33n_a th33w2_a th34_a th34w2_a th34w22_a th34w3_a th34w32_a
//              th44_a th44w2_a th44w22_a th44w3_a th44w322_a th54w22_a th54w32_a th54w322_a thand0_a thxor0_a
// UDP list --  udp_rslat_out udp_rslat_rst_out udp_rslat_rstn_out
// date                version         description
// 4-29-2022            1.0             original
// 6-11-2022            1.1             add th22db_a th22nb_a remove inv_a 
// 2-14-2023            2.0             define UDP udp_th22 udp_th22n udp_th22d udp_th33 udp_th33d udp_th33n 
//                                      and replace the RS-latch based udp
`ifndef NCL_GATE
`define NCL_GATE
`define NCL_DP  			#0.010



/////////////////////////////////////
//th12b_a
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module th12b_a (a, b, z);
output z;
input a, b;
  or  I1(a_or_b, a, b);
  not `NCL_DP I2(z, a_or_b);
endmodule // th12b_a
`endcelldefine

/////////////////////////////////////
//th12_a
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module th12_a (a, b, z);
output z;
input a, b;
 or  `NCL_DP I2(z, a, b);
endmodule // th12_a
`endcelldefine

/////////////////////////////////////
//th13_a
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module th13_a (a, b, c, z);
output z;
input a, b, c;
  or  `NCL_DP I1(z, a, b, c);
endmodule // th13_a
`endcelldefine

/////////////////////////////////////
//th14_a
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module th14_a (a, b, c, d, z);
output z;
input a, b, c, d;
  or  `NCL_DP I1(z, a, b, c, d);
endmodule // th14_a
`endcelldefine


/////////////////////////////////////
//th22_a
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module th22_a (a, b, z);
output z;
input a, b;
  udp_th22 I0(z_int, a, b);
  //udp_rslat_out I0(z_int, R, S, NOTIFIER);
  buf `NCL_DP I1(z, z_int);
  //and  I2(S, a, b);
  //nor  I3(R, a, b); 
endmodule // th22_a
`endcelldefine


///////////////////////////////////////
////th22d_a
//////////////////////////////////////
//`timescale 1ns/1ps
//`celldefine
//module th22d_a (a, b, rst, z);
//output z;
//input a, b, rst;
//  udp_th22d I0(z_int, a, b, rst);
//  //udp_rslat_rst_1_out I0(z_int, R, S, rst);
//  buf `NCL_DP I1(z, z_int);
//  //buf I1(z, z_int);
//  //and  I2(a_and_b, a, b);
//  //or   I3(a_or_b, a, b);
//  //not  I4(not_a_or_b, a_or_b);
//  //not  I5(not_rst, rst);
//  //or   I6(S, a_and_b, rst);
//  //and  I7(R, not_a_or_b, not_rst);
//endmodule // th22d_a
//`endcelldefine

/////////////////////////////////////
//th22db_a
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module th22db_a (a, b, rst, z);
output z;
input a, b, rst;
  udp_th22d I0(z_int, a, b, rst);
  //udp_rslat_rst_1_out I0(z_int, R, S, rst);
  not `NCL_DP I1(z, z_int);
  //and  I2(a_and_b, a, b);
  //or   I3(a_or_b, a, b);
  //not  I4(not_a_or_b, a_or_b);
  //not  I5(not_rst, rst);
  //or   I6(S, a_and_b, rst);
  //and  I7(R, not_a_or_b, not_rst);
endmodule // th22db_a
`endcelldefine

///////////////////////////////////////
////th22n_a
//////////////////////////////////////
//`timescale 1ns/1ps
//`celldefine
//module th22n_a (a, b, rst, z);
//output z;
//input a, b, rst;
//  udp_th22n I0(z_int, a, b, rst);
//  //udp_rslat_rst_0_out I0(z_int, R, S, rst);
//  buf `NCL_DP I1(z, z_int);
//  //buf I1(z, z_int);
//  //and  I2(a_and_b, a, b);
//  //or   I3(a_or_b, a, b);
//  //not  I4(not_a_or_b, a_or_b);
//  //not  I5(not_rst, rst);
//  //and  I6(S, a_and_b, not_rst);
//  //or   I7(R, not_a_or_b, rst);
//endmodule // th22n_a
//`endcelldefine

/////////////////////////////////////
//th22nb_a
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module th22nb_a (a, b, rst, z);
output z;
input a, b, rst;
  udp_th22n I0(z_int, a, b, rst);  
  //udp_rslat_rst_0_out I0(z_int, R, S, rst);
  not `NCL_DP I1(z, z_int);
  //and  I2(a_and_b, a, b);
  //or   I3(a_or_b, a, b);
  //not  I4(not_a_or_b, a_or_b);
  //not  I5(not_rst, rst);
  //and  I6(S, a_and_b, not_rst);
  //or   I7(R, not_a_or_b, rst);
endmodule // th22nb_a
`endcelldefine

/////////////////////////////////////
//th23_a
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module th23_a (a, b, c, z);
output z;
input a, b, c;
  udp_rslat_out I0(z_int, R, S, NOTIFIER);
  buf `NCL_DP I1(z, z_int);
  and I2(a_and_b, a, b);
  and I3(a_and_c, a, c);
  and I4(b_and_c, b, c);
  or  I5(S, a_and_b, a_and_c, b_and_c);
  nor I6(R, a, b, c); 
endmodule // th23_a
`endcelldefine

/////////////////////////////////////
//th23w2_a
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module th23w2_a (a, b, c, z);
output z;
input a, b, c;
  udp_rslat_out I0(z_int, R, S, NOTIFIER);
  buf `NCL_DP I1(z, z_int);
  and I2(b_and_c, b, c);
  or  I3(S, a, b_and_c);
  nor I5(R, a, b, c);   
endmodule // th23w2_a
`endcelldefine


/////////////////////////////////////
//th24_a
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module th24_a (a, b, c, d, z);
output z;
input a, b, c, d;
  udp_rslat_out I0(z_int, R, S, NOTIFIER);
  buf `NCL_DP I1(z, z_int);
  and I2(a_and_b, a, b);
  and I3(a_and_c, a, c);
  and I4(a_and_d, a, d);
  and I5(b_and_c, b, c);
  and I6(b_and_d, b, d);
  and I7(c_and_d, c, d);
  or  I8(S, a_and_b, a_and_c, a_and_d, b_and_c, b_and_d, c_and_d);
  nor I9(R, a, b, c, d);   
endmodule // th24_a
`endcelldefine


/////////////////////////////////////
//th24w2_a
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module th24w2_a (a, b, c, d, z);
output z;
input a, b, c, d;
  udp_rslat_out I0(z_int, R, S, NOTIFIER);
  buf `NCL_DP I1(z, z_int);
  and I2(b_and_c, b, c);
  and I3(b_and_d, b, d);
  and I4(c_and_d, c, d);
  or  I5(S, a, b_and_c, b_and_d, c_and_d);
  nor I6(R, a, b, c, d);     
endmodule // th24w2_a
`endcelldefine


/////////////////////////////////////
//th24w22_a
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module th24w22_a (a, b, c, d, z);
output z;
input a, b, c, d;
  udp_rslat_out I0(z_int, R, S, NOTIFIER);
  buf `NCL_DP I1(z, z_int);
  and I2(c_and_d, c, d);
  or  I3(S, a, b, c_and_d);
  nor I4(R, a, b, c, d);      
endmodule // th24w22_a
`endcelldefine

/////////////////////////////////////
//th24comp_a
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module th24comp_a (a, b, c, d, z);
output z;
input a, b, c, d;
  udp_rslat_out I0(z_int, R, S, NOTIFIER);
  buf `NCL_DP I1(z, z_int);
  or  I2(a_or_b, a, b);
  or  I3(c_or_d, c, d);
  and I4(S, a_or_b, c_or_d);
  nor I5(R, a, b, c, d); 
endmodule // th24comp_a
`endcelldefine

/////////////////////////////////////
//th33_a
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module th33_a (a, b, c, z);
output z;
input a, b, c;
  udp_th33 I0(z_int, a, b, c);
  //udp_rslat_out I0(z_int, R, S, NOTIFIER);
  buf `NCL_DP I1(z, z_int);
  //and  I2(S, a, b, c);
  //nor I3(R, a, b, c);
endmodule // th33_a
`endcelldefine

/////////////////////////////////////
//th33d_a
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module th33d_a (a, b, c, rst, z);
output z;
input a, b, c, rst;
  udp_th33d I0(z_int, a, b, c, rst);
  //udp_rslat_rst_1_out I0(z_int, R, S, rst);
  buf `NCL_DP I1(z, z_int);
  //and  I2(a_and_b_and_c, a, b, c);
  //or   I3(a_or_b_or_c, a, b, c);
  //not  I4(not_a_or_b_or_c, a_or_b_or_c);
  //not  I5(not_rst, rst);
  //or   I6(S, a_and_b_and_c, rst);
  //and  I7(R, not_a_or_b_or_c, not_rst);
endmodule // th33d_a
`endcelldefine

/////////////////////////////////////
//th33n_a
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module th33n_a (a, b, c, rst, z);
output z;
input a, b, c, rst;
  udp_th33n I0(z_int, a, b, c, rst);
  //udp_rslat_rst_0_out I0(z_int, R, S, rst);
  buf `NCL_DP I1(z, z_int);
  //and  I2(a_and_b_and_c, a, b, c);
  //or   I3(a_or_b_or_c, a, b, c);
  //not  I4(not_a_or_b_or_c, a_or_b_or_c);
  //not  I5(not_rst, rst);
  //and  I6(S, a_and_b_and_c, not_rst);
  //or   I7(R, not_a_or_b_or_c, rst);
endmodule // th33n_a
`endcelldefine

/////////////////////////////////////
//th33w2_a
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module th33w2_a (a, b, c, z);
output z;
input a, b, c;
  udp_rslat_out I0(z_int, R, S, NOTIFIER);
  buf `NCL_DP I1(z, z_int);
  and I2(a_and_b, a, b);
  and I3(a_and_c, a, c);
  or  I4(S, a_and_b, a_and_c);
  nor I5(R, a, b, c);
endmodule // th33w2_a
`endcelldefine

/////////////////////////////////////
//th34_a
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module th34_a (a, b, c, d, z);
output z;
input a, b, c, d;
  udp_rslat_out I0(z_int, R, S, NOTIFIER);
  buf `NCL_DP I1(z, z_int);
  and  I2(a_and_b_and_c, a, b, c);
  and  I3(a_and_c_and_d, a, c, d);
  and  I4(a_and_b_and_d, a, b, d);
  and  I5(b_and_c_and_d, b, c, d); 
  or   I6(S, a_and_b_and_c, a_and_c_and_d, a_and_b_and_d, b_and_c_and_d);
  nor  I7(R, a, b, c, d);
endmodule // th34_a
`endcelldefine

/////////////////////////////////////
//th34w2_a
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module th34w2_a (a, b, c, d, z);
output z;
input a, b, c, d;
  udp_rslat_out I0(z_int, R, S, NOTIFIER);
  buf `NCL_DP I1(z, z_int);
  and I2(a_and_b, a, b);
  and I3(a_and_c, a, c);
  and I4(a_and_d, a, d);
  and I5(b_and_c_and_d, b, c, d);
  or  I6(S, a_and_b, a_and_c, a_and_d, b_and_c_and_d);
  nor I7(R, a, b, c, d);
endmodule // th34w2_a
`endcelldefine

/////////////////////////////////////
//th34w22_a
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module th34w22_a (a, b, c, d, z);
output z;
input a, b, c, d;
  udp_rslat_out I0(z_int, R, S, NOTIFIER);
  buf `NCL_DP I1(z, z_int);
  and I2(a_and_b, a, b);
  and I3(a_and_c, a, c);
  and I4(a_and_d, a, d);
  and I5(b_and_c, b, c);
  and I6(b_and_d, b, d);
  or  I7(S, a_and_b, a_and_c, a_and_d, b_and_c, b_and_d);
  nor I8(R, a, b, c, d);
endmodule // th34w22_a
`endcelldefine

/////////////////////////////////////
//th34w3_a
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module th34w3_a (a, b, c, d, z);
output z;
input a, b, c, d;
  udp_rslat_out I0(z_int, R, S, NOTIFIER);
  buf `NCL_DP I1(z, z_int);
  and I2(b_and_c_and_d, b, c, d);
  or  I3(S, a, b_and_c_and_d);
  nor I4(R, a, b, c, d);
endmodule // th34w3_a
`endcelldefine

/////////////////////////////////////
//th34w32_a
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module th34w32_a (a, b, c, d, z);
output z;
input a, b, c, d;
  udp_rslat_out I0(z_int, R, S, NOTIFIER);
  buf `NCL_DP I1(z, z_int);
  and I2(b_and_c, b, c);
  and I3(b_and_d, b, d);
  or  I4(S, a, b_and_c, b_and_d);
  nor I5(R, a, b, c, d);
endmodule // th34w32_a
`endcelldefine


/////////////////////////////////////
//th44_a
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module th44_a (a, b, c, d, z);
output z;
input a, b, c, d;
  udp_rslat_out I0(z_int, R, S, NOTIFIER);
  buf `NCL_DP I1(z, z_int);
  and  I2(S, a, b, c, d);
  nor  I3(R, a, b, c, d);
endmodule // th44_a
`endcelldefine

/////////////////////////////////////
//th44w2_a
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module th44w2_a (a, b, c, d, z);
output z;
input a, b, c, d;
  udp_rslat_out I0(z_int, R, S, NOTIFIER);
  buf `NCL_DP I1(z, z_int);
  and  I2(a_and_b_and_c, a, b, c);
  and  I3(a_and_b_and_d, a, b, d);
  and  I4(a_and_c_and_d, a, c, d);
  or   I5(S, a_and_b_and_c, a_and_b_and_d, a_and_c_and_d);
  nor  I6(R, a, b, c, d);
endmodule // th44w2_a
`endcelldefine

/////////////////////////////////////
//th44w22_a
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module th44w22_a (a, b, c, d, z);
output z;
input a, b, c, d;
  udp_rslat_out I0(z_int, R, S, NOTIFIER);
  buf `NCL_DP I1(z, z_int);
  and  I2(a_and_b, a, b);
  and  I3(a_and_c_and_d, a, c, d);
  and  I4(b_and_c_and_d, b, c, d);
  or   I5(S, a_and_b, a_and_c_and_d, b_and_c_and_d);
  nor  I6(R, a, b, c, d);
endmodule // th44w22_a
`endcelldefine

/////////////////////////////////////
//th44w3_a
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module th44w3_a (a, b, c, d, z);
output z;
input a, b, c, d;
  udp_rslat_out I0(z_int, R, S, NOTIFIER);
  buf `NCL_DP I1(z, z_int);
  and I2(a_and_b, a, b);
  and I3(a_and_c, a, c);
  and I4(a_and_d, a, d);
  or  I5(S, a_and_b, a_and_c, a_and_d);
  nor  I6(R, a, b, c, d);
endmodule // th44w3_a
`endcelldefine

/////////////////////////////////////
//th44w322_a
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module th44w322_a (a, b, c, d, z);
output z;
input a, b, c, d;
  udp_rslat_out I0(z_int, R, S, NOTIFIER);
  buf `NCL_DP I1(z, z_int);
  and I2(a_and_b, a, b);
  and I3(a_and_c, a, c);
  and I4(a_and_d, a, d);
  and I5(b_and_c, b, c);
  or  I6(S, a_and_b, a_and_c, a_and_d, b_and_c);
  nor I7(R, a, b, c, d);
endmodule // th44w322_a
`endcelldefine

/////////////////////////////////////
//th54w22_a
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module th54w22_a (a, b, c, d, z);
output z;
input a, b, c, d;
  udp_rslat_out I0(z_int, R, S, NOTIFIER);
  buf `NCL_DP I1(z, z_int);
  and  I2(a_and_b_and_c, a, b, c);
  and  I3(a_and_b_and_d, a, b, d);
  or   I4(S, a_and_b_and_c, a_and_b_and_d);
  nor  I5(R, a, b, c, d);
endmodule // th54w22_a
`endcelldefine

/////////////////////////////////////
//th54w32_a
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module th54w32_a (a, b, c, d, z);
output z;
input a, b, c, d;
  udp_rslat_out I0(z_int, R, S, NOTIFIER);
  buf `NCL_DP I1(z, z_int);
  and  I2(a_and_b, a, b);
  and  I3(a_and_c_and_d, a, c, d);
  or   I4(S, a_and_b, a_and_c_and_d);
  nor  I5(R, a, b, c, d);
endmodule // th54w32_a
`endcelldefine


/////////////////////////////////////
//th54w322_a
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module th54w322_a (a, b, c, d, z);
output z;
input a, b, c, d;
  udp_rslat_out I0(z_int, R, S, NOTIFIER);
  buf `NCL_DP I1(z, z_int);
  and  I2(a_and_b, a, b);
  and  I3(a_and_c, a, c);
  and  I4(b_and_c_and_d, b, c, d);
  or   I5(S, a_and_b, a_and_c, b_and_c_and_d);
  nor  I6(R, a, b, c, d);
endmodule // th54w322_a
`endcelldefine

/////////////////////////////////////
//thand0_a
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module thand0_a (a, b, c, d, z);
output z;
input a, b, c, d;
  udp_rslat_out I0(z_int, R, S, NOTIFIER);
  buf `NCL_DP I1(z, z_int);
  and I2(a_and_b, a, b);
  and I3(b_and_c, b, c);
  and I4(a_and_d, a, d);
  or  I5(S, a_and_b, b_and_c, a_and_d);
  nor I6(R, a, b, c, d);
endmodule // thand0_a
`endcelldefine

/////////////////////////////////////
//thxor0_a
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module thxor0_a (a, b, c, d, z);
output z;
input a, b, c, d;
  udp_rslat_out I0(z_int, R, S, NOTIFIER);
  buf `NCL_DP I1(z, z_int);
  and I2(a_and_b, a, b);
  and I3(c_and_d, c, d);
  or  I4(S, a_and_b, c_and_d);
  nor  I5(R, a, b, c, d);
endmodule // thxor0_a
`endcelldefine

`endif


////////////////////////////////////////////
//udp_rslat_out
///////////////////////////////////////////
`ifdef udp_rslat_out_READ
`else
primitive udp_rslat_out (out, r, s, NOTIFIER);
   output out;  
   input  r, s, NOTIFIER;
   reg    out;

   table

// r   s   NOT : Qt : Qt+1
// 
  (?0) 0   ?   : ?  :  -  ; // no change                  //?--don't care  (?0)--to 0 transition
   0  (?0) ?   : ?  :  -  ; // no change
   1   ?   ?   : ?  :  0  ; // reset
  (?0) 1   ?   : ?  :  1  ; // set
   0  (?1) ?   : ?  :  1  ; // set						  // (?1)-- to 1 transition
  (?0) x   ?   : 1  :  1  ; // reduced pessimism
   0  (?x) ?   : 1  :  1  ; // reduced pessimism          // (?x) -- to x transition
  (?x) 0   ?   : 0  :  0  ; // reduced pessimism
   x  (?0) ?   : 0  :  0  ; // reduced pessimism
   ?   ?   *   : ?  :  x  ; // any notifier changed

   endtable
endprimitive // udp_rslat_out
`endif

////////////////////////////////////////////
//udp_rslat_rst_out
///////////////////////////////////////////
`ifdef udp_rslat_rst_out_READ
`else
primitive udp_rslat_rst_1_out (out, r, s, rst);
   output out;  
   input  r, s, rst;
   reg    out;

   table

// r   s   rst : Qt : Qt+1
// 
  (?0) 0   0   : ?  :  -  ; // no change                  //?--don't care  (?0)--to 0 transition
   0  (?0) 0   : ?  :  -  ; // no change
   1   ?   0   : ?  :  0  ; // reset
  (?0) 1   0   : ?  :  1  ; // set
   0  (?1) 0   : ?  :  1  ; // set						  // (?1)-- to 1 transition
  (?0) x   0   : 1  :  1  ; // reduced pessimism
   0  (?x) 0   : 1  :  1  ; // reduced pessimism          // (?x) -- to x transition
  (?x) 0   0   : 0  :  0  ; // reduced pessimism
   x  (?0) 0   : 0  :  0  ; // reduced pessimism
   ?   ?   1   : ?  :  1  ; // any notifier changed

   endtable
endprimitive // udp_rslat_rst_out
`endif

////////////////////////////////////////////
//udp_rslat_rstn_out
///////////////////////////////////////////
`ifdef udp_rslat_rstn_out_READ
`else
primitive udp_rslat_rst_0_out (out, r, s, rst);
   output out;  
   input  r, s, rst;
   reg    out;

   table

// r   s   rst : Qt : Qt+1
// 
  (?0) 0   0   : ?  :  -  ; // no change                  //?--don't care  (?0)--to 0 transition
   0  (?0) 0   : ?  :  -  ; // no change
   1   ?   0   : ?  :  0  ; // reset
  (?0) 1   0   : ?  :  1  ; // set
   0  (?1) 0   : ?  :  1  ; // set						  // (?1)-- to 1 transition
  (?0) x   0   : 1  :  1  ; // reduced pessimism
   0  (?x) 0   : 1  :  1  ; // reduced pessimism          // (?x) -- to x transition
  (?x) 0   0   : 0  :  0  ; // reduced pessimism
   x  (?0) 0   : 0  :  0  ; // reduced pessimism
   ?   ?   1   : ?  :  0  ; // any notifier changed

   endtable
endprimitive // udp_rslat_rstn_out
`endif

////////////////////////////////////////////
//udp_th22
///////////////////////////////////////////
`ifdef udp_th22_READ
`else
primitive udp_th22 (out, a, b);
   output out;  
   input  a,b;
   reg    out;

   table

// a   b    :out : out+1
//         
   0   0    : ?  :  0  ; // Zero
   0   1  	: ?  :  -  ; // Keep
   0   x    : ?  :  x  ; // 
   1   0    : ?  :  -  ; // Keep
   1   1  	: ?  :  1  ; // Set to 1
   1   x    : ?  :  x  ; // 
   x   0    : ?  :  x  ; // 
   x   1  	: ?  :  x  ; // 
   x   x    : ?  :  x  ; //    

   endtable
endprimitive // udp_th22
`endif

////////////////////////////////////////////
//udp_th22n
///////////////////////////////////////////
`ifdef udp_th22n_READ
`else
primitive udp_th22n (out, a, b, rst);
   output out;  
   input  a,b,rst;
   reg    out;

   table

// a   b   rst 	:out : out+1
//             
   ?   ?   x  	: ?  :  x  ; // 
   ?   ?   1 	: ?  :  0  ; // Reset to 0   
   0   0   0  	: ?  :  0  ; // Zero
   0   1   0 	: ?  :  -  ; // Keep
   0   x   0    : ?  :  x  ; // 
   1   0   0    : ?  :  -  ; // Keep
   1   1   0  	: ?  :  1  ; // Set to 1
   1   x   0    : ?  :  x  ; // 
   x   0   0    : ?  :  x  ; // 
   x   1   0  	: ?  :  x  ; // 
   x   x   0    : ?  :  x  ; //    
   endtable
endprimitive // udp_th22n
`endif

//////////////////////////////////////////////
////udp_th22n_mod
/////////////////////////////////////////////
//`ifdef udp_th22n_READ
//`else
//primitive udp_th22n (out, a, b, rst);
//   output out;  
//   input  a,b,rst;
//   reg    out;
//
//   table
//
//// a   b   rst 	:out : out+1
////             
//   ?   ?   x  	: ?  :  x  ; // 
//   ?   ?   1 	: ?  :  0  ; // Reset to 0   
//   0   0   0  	: ?  :  0  ; // Zero
//   0   1   0 	: ?  :  0  ; // Keep
//   0   x   0    : ?  :  x  ; // 
//   1   0   0    : ?  :  0  ; // Keep
//   1   1   0  	: ?  :  1  ; // Set to 1
//   1   x   0    : ?  :  x  ; // 
//   x   0   0    : ?  :  x  ; // 
//   x   1   0  	: ?  :  x  ; // 
//   x   x   0    : ?  :  x  ; //    
//   endtable
//endprimitive // udp_th22n
//`endif

////////////////////////////////////////////
//udp_th22d
///////////////////////////////////////////
`ifdef udp_th22d_READ
`else
primitive udp_th22d (out, a, b, rst);
   output out;  
   input  a,b,rst;
   reg    out;

   table

// a   b   rst 	:out : out+1
//             
   ?   ?   x  	: ?  :  x  ; // 
   ?   ?   1 	: ?  :  1  ; // Reset to 1  
   0   0   0  	: ?  :  0  ; // Zero
   0   1   0 	: ?  :  -  ; // Keep
   0   x   0    : ?  :  x  ; // 
   1   0   0    : ?  :  -  ; // Keep
   1   1   0  	: ?  :  1  ; // Set to 1
   1   x   0    : ?  :  x  ; // 
   x   0   0    : ?  :  x  ; // 
   x   1   0  	: ?  :  x  ; // 
   x   x   0    : ?  :  x  ; //    
   endtable
endprimitive // udp_th22d
`endif

//////////////////////////////////////////////
////udp_th22d_mod
/////////////////////////////////////////////
//`ifdef udp_th22d_READ
//`else
//primitive udp_th22d (out, a, b, rst);
//   output out;  
//   input  a,b,rst;
//   reg    out;
//
//   table
//
//// a   b   rst 	:out : out+1
////             
//   ?   ?   x  	: ?  :  x  ; // 
//   ?   ?   1 	: ?  :  1  ; // Reset to 1  
//   0   0   0  	: ?  :  0  ; // Zero
//   0   1   0 	: ?  :  0  ; // Keep
//   0   x   0    : ?  :  x  ; // 
//   1   0   0    : ?  :  0  ; // Keep
//   1   1   0  	: ?  :  1  ; // Set to 1
//   1   x   0    : ?  :  x  ; // 
//   x   0   0    : ?  :  x  ; // 
//   x   1   0  	: ?  :  x  ; // 
//   x   x   0    : ?  :  x  ; //    
//   endtable
//endprimitive // udp_th22d
//`endif

////////////////////////////////////////////
//udp_th33
///////////////////////////////////////////
`ifdef udp_th33_READ
`else
primitive udp_th33 (out, a, b, c);
   output out;  
   input  a,b,c;
   reg    out;

   table

// a   b   c   :out : out+1
//             
   0   0   0   : ?  :  0  ; // Zero
   0   0   1   : ?  :  -  ; // Keep  
   0   0   x   : ?  :  x  ; //      
   0   1   ?   : ?  :  -  ; // Keep
   0   x   0   : ?  :  x  ; // 
   0   x   1   : ?  :  -  ; // Keep 
   0   x   x   : ?  :  x  ; //    
   1   0   ?   : ?  :  -  ; // Keep
   1   1   0   : ?  :  -  ; // Keep   
   1   1   1   : ?  :  1  ; // Set to 1
   1   1   x   : ?  :  x  ; // 
   1   x   0   : ?  :  -  ; // Keep  
   1   x   1   : ?  :  x  ; //    
   1   x   x   : ?  :  x  ; // 
   x   0   0   : ?  :  x  ; // 
   x   0   1   : ?  :  -  ; // Keep  
   x   0   x   : ?  :  x  ; // 
   x   1   0   : ?  :  -  ; // Keep   
   x   1   1   : ?  :  x  ; // 
   x   1   x   : ?  :  x  ; // 
   x   x   ?   : ?  :  x  ; //    
   endtable
endprimitive // udp_th33
`endif

////////////////////////////////////////////
//udp_th33n
///////////////////////////////////////////
`ifdef udp_th33n_READ
`else
primitive udp_th33n (out, a, b, c, rst);
   output out;  
   input  a,b,c,rst;
   reg    out;

   table

// a   b   c   rst 	:out : out+1
//                 
   ?   ?   ?   x  	: ?  :  x  ; // 
   ?   ?   ?   1 	: ?  :  0  ; // Reset to 0    
   0   0   0   0  	: ?  :  0  ; // Zero
   0   0   1   0  	: ?  :  -  ; // Keep  
   0   0   x   0  	: ?  :  x  ; //      
   0   1   ?   0 	: ?  :  -  ; // Keep
   0   x   0   0    : ?  :  x  ; // 
   0   x   1   0  	: ?  :  -  ; // Keep 
   0   x   x   0    : ?  :  x  ; //    
   1   0   ?   0    : ?  :  -  ; // Keep
   1   1   0   0    : ?  :  -  ; // Keep   
   1   1   1   0  	: ?  :  1  ; // Set to 1
   1   1   x   0    : ?  :  x  ; // 
   1   x   0   0  	: ?  :  -  ; // Keep  
   1   x   1   0    : ?  :  x  ; //    
   1   x   x   0    : ?  :  x  ; // 
   x   0   0   0    : ?  :  x  ; // 
   x   0   1   0    : ?  :  -  ; // Keep  
   x   0   x   0    : ?  :  x  ; // 
   x   1   0   0  	: ?  :  -  ; // Keep   
   x   1   1   0  	: ?  :  x  ; // 
   x   1   x   0  	: ?  :  x  ; // 
   x   x   ?   0    : ?  :  x  ; //    
   endtable
endprimitive // udp_th33n
`endif


////////////////////////////////////////////
//udp_th33d
///////////////////////////////////////////
`ifdef udp_th33d_READ
`else
primitive udp_th33d (out, a, b, c, rst);
   output out;  
   input  a,b,c,rst;
   reg    out;

   table

// a   b   c   rst 	:out : out+1
//                 
   ?   ?   ?   x  	: ?  :  x  ; // 
   ?   ?   ?   1 	: ?  :  1  ; // Reset to 1    
   0   0   0   0  	: ?  :  0  ; // Zero
   0   0   1   0  	: ?  :  -  ; // Keep  
   0   0   x   0  	: ?  :  x  ; //      
   0   1   ?   0 	: ?  :  -  ; // Keep
   0   x   0   0    : ?  :  x  ; // 
   0   x   1   0  	: ?  :  -  ; // Keep 
   0   x   x   0    : ?  :  x  ; //    
   1   0   ?   0    : ?  :  -  ; // Keep
   1   1   0   0    : ?  :  -  ; // Keep   
   1   1   1   0  	: ?  :  1  ; // Set to 1
   1   1   x   0    : ?  :  x  ; // 
   1   x   0   0  	: ?  :  -  ; // Keep  
   1   x   1   0    : ?  :  x  ; //    
   1   x   x   0    : ?  :  x  ; // 
   x   0   0   0    : ?  :  x  ; // 
   x   0   1   0    : ?  :  -  ; // Keep  
   x   0   x   0    : ?  :  x  ; // 
   x   1   0   0  	: ?  :  -  ; // Keep   
   x   1   1   0  	: ?  :  x  ; // 
   x   1   x   0  	: ?  :  x  ; // 
   x   x   ?   0    : ?  :  x  ; //    
   endtable
endprimitive // udp_th33d
`endif



`define udp_rslat_out_READ
`define udp_rslat_rst_out_READ
`define udp_rslat_rstn_out_READ