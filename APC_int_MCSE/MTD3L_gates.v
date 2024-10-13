// Verilog model for MTD3L gates
// Gate list -- buffermtd3l_a th12mtd3l_a  th12dmtd3l_a th12nmtd3l_a  th22mtd3l_a th13mtd3l_a th23mtd3l_a th33mtd3l_a 
// 			    th23w2mtd3l_a th33w2mtd3l_a th14mtd3l_a th24mtd3l_a th34mtd3l_a th44mtd3l_a th24w2mtd3l_a th34w2mtd3l_a
//				th44w2mtd3l_a th34w3mtd3l_a th44w3mtd3l_a th24w22mtd3l_a th34w22mtd3l_a th44w22mtd3l_a th54w22mtd3l_a
//				th34w32mtd3l_a th54w32mtd3l_a th44w322mtd3l_a th54w322mtd3l_a
//				thxor0mtd3l_a thand0mtd3l_a  th24compmtd3l_a 
//              regdmtd3l regnmtd3l
//				spkpmtd3l
//				spacer regazsmtd3l regaosmtd3l 
// date                version         description
// 8-15-2022            1.0             original
// 10-11-2022           1.1             add spacer use only udp_rslat_out, add regazsmtd3l, regaosmtd3l
// 11-29-2022           1.2             change port name "ds" to "zd" in regazsmtd3l, regaosmtd3l
// 2-14-2023            1.3             correct th22mtd3l_a th23mtd3l_a typo

`ifndef MTD3L_GATE
`define MTD3L_GATE
`define MTD3L_DP  			#0.010
`define MTD3L_LOOP          #0.005

/////////////////////////////////////
//buffermtd3l_a
////////////////////////////////////
// `timescale 1ns/1ps
// `celldefine
// module buffermtd3l_a (a, s0, ns1, z);
// output z;
// input a, s0, ns1;
//   not I1(ns0, s0);
//   not I2(s1, ns1);
//   or  I3(z_int, a, s1);				  //if ns1=0 (s1=1), then z_int=1; else if ns1=1 (s1=0), then z_int=a.
//   and `MTD3L_DP I4(z, z_int, ns0);    //if s0=1 (ns0=0), then z=0; else if s0=0 (ns0=1), then z=z_int. 
// endmodule // buffermtd3l_a
// `endcelldefine

/////////////////////////////////////
//th12mtd3l_a
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module th12mtd3l_a (a, b, s0, ns1, z);
output z;
input a, b, s0, ns1;
  not I1(ns0, s0);
  not I2(s1, ns1);
  or  I3(a_or_b, a, b);
  or  I4(z_int, a_or_b, s1);		  //if ns1=0 (s1=1), then z_int=1; else if ns1=1 (s1=0), then z_int=a_or_b.
  and `MTD3L_DP I5(z, z_int, ns0);    //if s0=1 (ns0=0), then z=0; else if s0=0 (ns0=1), then z=z_int. 
endmodule // th12mtd3l_a
`endcelldefine

/////////////////////////////////////
//th12dmtd3l_a
////////////////////////////////////
//`timescale 1ns/1ps
//`celldefine
//module th12dmtd3l_a (a, b, rst, s0, ns1, z);
//output z;
//input a, b, rst, s0, ns1;
//  not I1(ns0, s0);
//  not I2(s1, ns1);
//  or  I3(a_or_b, a, b);
//  or  I4(z_int, a_or_b, s1);		  //if ns1=0 (s1=1), then z_int=1; else if ns1=1 (s1=0), then z_int=a_or_b.
//  and I5(z_r, z_int, ns0);    		  //if s0=1 (ns0=0), then z=0; else if s0=0 (ns0=1), then z=z_int. 
//  or  `MTD3L_DP I6(z, z_r, rst);
//endmodule // th12dmtd3l_a
//`endcelldefine
//
///////////////////////////////////////
////th12nmtd3l_a
//////////////////////////////////////
//`timescale 1ns/1ps
//`celldefine
//module th12nmtd3l_a (a, b, rst, s0, ns1, z);
//output z;
//input a, b, rst, s0, ns1;
//  not I1(ns0, s0);
//  not I2(s1, ns1);
//  or  I3(a_or_b, a, b);
//  or  I4(z_int, a_or_b, s1);		  //if ns1=0 (s1=1), then z_int=1; else if ns1=1 (s1=0), then z_int=a_or_b.
//  and I5(z_r, z_int, ns0);    		  //if s0=1 (ns0=0), then z=0; else if s0=0 (ns0=1), then z=z_int. 
//  not I6(not_rst, rst);
//  and `MTD3L_DP I7(z, z_r, not_rst);
//endmodule // th12nmtd3l_a
//`endcelldefine


/////////////////////////////////////
//th22mtd3l_a
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module th22mtd3l_a (a, b, s0, ns1, z);
output z;
input a, b, s0, ns1;
  not I1(ns0, s0);
  not I2(s1, ns1);
  and I3(a_and_b, a, b);
  or  I4(z_int, a_and_b, s1);		  //if ns1=0 (s1=1), then z_int=1; else if ns1=1 (s1=0), then z_int=a_and_b.
  and `MTD3L_DP I5(z, z_int, ns0);    //if s0=1 (ns0=0), then z=0; else if s0=0 (ns0=1), then z=z_int.   
endmodule // th22mtd3l_a
`endcelldefine

/////////////////////////////////////
//th13mtd3l_a
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module th13mtd3l_a (a, b, c, s0, ns1, z);
output z;
input a, b, c, s0, ns1;
  not I1(ns0, s0);
  not I2(s1, ns1);
  or  I3(a_or_b_or_c, a, b, c);
  or  I4(z_int, a_or_b_or_c, s1);		  //if ns1=0 (s1=1), then z_int=1; else if ns1=1 (s1=0), then z_int=a_or_b_or_c.
  and `MTD3L_DP I5(z, z_int, ns0);    //if s0=1 (ns0=0), then z=0; else if s0=0 (ns0=1), then z=z_int.   
endmodule // th13mtd3l_a
`endcelldefine

/////////////////////////////////////
//th23mtd3l_a
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module th23mtd3l_a (a, b, c, s0, ns1, z);
output z;
input a, b, c, s0, ns1;
  not I1(ns0, s0);
  not I2(s1, ns1);
  and I3(a_and_b, a, b);
  and I4(a_and_c, a, c);
  and I5(b_and_c, b, c);
  or  I6(ab_or_ac_or_bc, a_and_b, a_and_c, b_and_c);
  or  I7(z_int, ab_or_ac_or_bc, s1);		  //if ns1=0 (s1=1), then z_int=1; else if ns1=1 (s1=0), then z_int=ab_or_ac_or_bc.
  and `MTD3L_DP I8(z, z_int, ns0);    //if s0=1 (ns0=0), then z=0; else if s0=0 (ns0=1), then z=z_int.   
endmodule // th23mtd3l_a
`endcelldefine

/////////////////////////////////////
//th23w2mtd3l_a
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module th23w2mtd3l_a (a, b, c, s0, ns1, z);
output z;
input a, b, c, s0, ns1;
  not I1(ns0, s0);
  not I2(s1, ns1);
  and I3(b_and_c, b, c);
  or  I4(a_or_bc, a, b_and_c);
  or  I5(z_int, a_or_bc, s1);		  	  //if ns1=0 (s1=1), then z_int=1; else if ns1=1 (s1=0), then z_int=a_or_bc.
  and `MTD3L_DP I6(z, z_int, ns0);    	  //if s0=1 (ns0=0), then z=0; else if s0=0 (ns0=1), then z=z_int.  
endmodule // th23w2mtd3l_a
`endcelldefine

/////////////////////////////////////
//th33mtd3l_a
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module th33mtd3l_a (a, b, c, s0, ns1, z);
output z;
input a, b, c, s0, ns1;
  not I1(ns0, s0);
  not I2(s1, ns1);
  and I3(a_and_b_and_c, a, b, c);
  or  I4(z_int, a_and_b_and_c, s1);		  //if ns1=0 (s1=1), then z_int=1; else if ns1=1 (s1=0), then z_int=a_and_b_and_c.
  and `MTD3L_DP I5(z, z_int, ns0);    	  //if s0=1 (ns0=0), then z=0; else if s0=0 (ns0=1), then z=z_int.  
endmodule // th33mtd3l_a
`endcelldefine

/////////////////////////////////////
//th33w2mtd3l_a
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module th33w2mtd3l_a (a, b, c, s0, ns1, z);
output z;
input a, b, c, s0, ns1;
  not I1(ns0, s0);
  not I2(s1, ns1);
  and I3(a_and_b, a, b);
  and I4(a_and_c, a, c);
  or  I5(ab_or_ac, a_and_b, a_and_c);
  or  I6(z_int, ab_or_ac, s1);		  	  //if ns1=0 (s1=1), then z_int=1; else if ns1=1 (s1=0), then z_int=ab_or_ac.
  and `MTD3L_DP I7(z, z_int, ns0);    	  //if s0=1 (ns0=0), then z=0; else if s0=0 (ns0=1), then z=z_int.  
endmodule // th33w2mtd3l_a
`endcelldefine

/////////////////////////////////////
//th14mtd3l_a
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module th14mtd3l_a (a, b, c, d, s0, ns1, z);
output z;
input a, b, c, d, s0, ns1;
  not I1(ns0, s0);
  not I2(s1, ns1);
  or  I3(a_or_b_or_c_or_d, a, b, c, d);
  or  I4(z_int, a_or_b_or_c_or_d, s1);		  //if ns1=0 (s1=1), then z_int=1; else if ns1=1 (s1=0), then z_int=a_or_b_or_c_or_d.
  and `MTD3L_DP I5(z, z_int, ns0);        	  //if s0=1 (ns0=0), then z=0; else if s0=0 (ns0=1), then z=z_int.     
endmodule // th14mtd3l_a
`endcelldefine

/////////////////////////////////////
//th24mtd3l_a
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module th24mtd3l_a (a, b, c, d, s0, ns1, z);
output z;
input a, b, c, d, s0, ns1;
  not I1(ns0, s0);
  not I2(s1, ns1);
  and I3(a_and_b, a, b);
  and I4(a_and_c, a, c);
  and I5(a_and_d, a, d);
  and I6(b_and_c, b, c);
  and I7(b_and_d, b, d);
  and I8(c_and_d, c, d);
  or  I9(ab_or_ac_or_ad_or_bc_or_bd_or_cd, a_and_b, a_and_c, a_and_d, b_and_c, b_and_d, c_and_d);
  or  I10(z_int, ab_or_ac_or_ad_or_bc_or_bd_or_cd, s1);		  //if ns1=0 (s1=1), then z_int=1; else if ns1=1 (s1=0), then z_int=ab_or_ac_or_ad_or_bc_or_bd_or_cd.
  and `MTD3L_DP I11(z, z_int, ns0);        	  //if s0=1 (ns0=0), then z=0; else if s0=0 (ns0=1), then z=z_int.   
endmodule // th24mtd3l_a
`endcelldefine

/////////////////////////////////////
//th24w2mtd3l_a
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module th24w2mtd3l_a (a, b, c, d, s0, ns1, z);
output z;
input a, b, c, d, s0, ns1;
  not I1(ns0, s0);
  not I2(s1, ns1);
  and I3(b_and_c, b, c);
  and I4(b_and_d, b, d);
  and I5(c_and_d, c, d);
  or  I6(a_or_bc_or_bd_or_cd, a, b_and_c, b_and_d, c_and_d);
  or  I7(z_int, a_or_bc_or_bd_or_cd, s1);		  //if ns1=0 (s1=1), then z_int=1; else if ns1=1 (s1=0), then z_int=a_or_bc_or_bd_or_cd.
  and `MTD3L_DP I8(z, z_int, ns0);        	  	  //if s0=1 (ns0=0), then z=0; else if s0=0 (ns0=1), then z=z_int.   
endmodule // th24w2mtd3l_a
`endcelldefine

/////////////////////////////////////
//th24w22mtd3l_a
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module th24w22mtd3l_a (a, b, c, d, s0, ns1, z);
output z;
input a, b, c, d, s0, ns1;
  not I1(ns0, s0);
  not I2(s1, ns1);
  and I3(c_and_d, c, d);
  or  I4(a_or_b_or_cd, a, b, c_and_d);
  or  I5(z_int, a_or_b_or_cd, s1);		  //if ns1=0 (s1=1), then z_int=1; else if ns1=1 (s1=0), then z_int=a_or_b_or_cd.
  and `MTD3L_DP I6(z, z_int, ns0);        	  	  //if s0=1 (ns0=0), then z=0; else if s0=0 (ns0=1), then z=z_int.    
endmodule // th24w22mtd3l_a
`endcelldefine

/////////////////////////////////////
//th24compmtd3l_a
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module th24compmtd3l_a (a, b, c, d, s0, ns1, z);
output z;
input a, b, c, d, s0, ns1;
  not I1(ns0, s0);
  not I2(s1, ns1);
  or  I3(a_or_b, a, b);
  or  I4(c_or_d, c, d);
  and I5(a_or_b__and__c_or_d, a_or_b, c_or_d);
  or  I6(z_int, a_or_b__and__c_or_d, s1);		  //if ns1=0 (s1=1), then z_int=1; else if ns1=1 (s1=0), then z_int=a_or_b__and__c_or_d.
  and `MTD3L_DP I7(z, z_int, ns0);        	  	  //if s0=1 (ns0=0), then z=0; else if s0=0 (ns0=1), then z=z_int.     
endmodule // th24compmtd3l_a
`endcelldefine


/////////////////////////////////////
//th34mtd3l_a
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module th34mtd3l_a (a, b, c, d, s0, ns1, z);
output z;
input a, b, c, d, s0, ns1;
  not I1(ns0, s0);
  not I2(s1, ns1);
  and I3(a_and_b_and_c, a, b, c);
  and I4(a_and_c_and_d, a, c, d);
  and I5(a_and_b_and_d, a, b, d);
  and I6(b_and_c_and_d, b, c, d); 
  or  I7(abc_or_acd_or_abd_or_bcd, a_and_b_and_c, a_and_c_and_d, a_and_b_and_d, b_and_c_and_d);
  or  I8(z_int, abc_or_acd_or_abd_or_bcd, s1);		  //if ns1=0 (s1=1), then z_int=1; else if ns1=1 (s1=0), then z_int=abc_or_acd_or_abd_or_bcd.
  and `MTD3L_DP I9(z, z_int, ns0);        	  				  //if s0=1 (ns0=0), then z=0; else if s0=0 (ns0=1), then z=z_int.   
endmodule // th34mtd3l_a
`endcelldefine

/////////////////////////////////////
//th34w2mtd3l_a
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module th34w2mtd3l_a (a, b, c, d, s0, ns1, z);
output z;
input a, b, c, d, s0, ns1;
  not I1(ns0, s0);
  not I2(s1, ns1);
  and I3(a_and_b, a, b);
  and I4(a_and_c, a, c);
  and I5(a_and_d, a, d);
  and I6(b_and_c_and_d, b, c, d);
  or  I7(ab_or_ac_or_ad_or_bcd, a_and_b, a_and_c, a_and_d, b_and_c_and_d);
  or  I8(z_int, ab_or_ac_or_ad_or_bcd, s1);		  //if ns1=0 (s1=1), then z_int=1; else if ns1=1 (s1=0), then z_int=ab_or_ac_or_ad_or_bcd.
  and `MTD3L_DP I9(z, z_int, ns0);        	  	  //if s0=1 (ns0=0), then z=0; else if s0=0 (ns0=1), then z=z_int.    
endmodule // th34w2mtd3l_a
`endcelldefine

/////////////////////////////////////
//th34w22mtd3l_a
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module th34w22mtd3l_a (a, b, c, d, s0, ns1, z);
output z;
input a, b, c, d, s0, ns1;
  not I1(ns0, s0);
  not I2(s1, ns1);
  and I3(a_and_b, a, b);
  and I4(a_and_c, a, c);
  and I5(a_and_d, a, d);
  and I6(b_and_c, b, c);
  and I7(b_and_d, b, d);
  or  I8(ab_or_ac_or_ad_or_bc_or_bd, a_and_b, a_and_c, a_and_d, b_and_c, b_and_d);
  or  I9(z_int, ab_or_ac_or_ad_or_bc_or_bd, s1);		  //if ns1=0 (s1=1), then z_int=1; else if ns1=1 (s1=0), then z_int=ab_or_ac_or_ad_or_bc_or_bd.
  and `MTD3L_DP I10(z, z_int, ns0);        	  	  //if s0=1 (ns0=0), then z=0; else if s0=0 (ns0=1), then z=z_int.    
endmodule // th34w22mtd3l_a
`endcelldefine

/////////////////////////////////////
//th34w3mtd3l_a
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module th34w3mtd3l_a (a, b, c, d, s0, ns1, z);
output z;
input a, b, c, d, s0, ns1;
  not I1(ns0, s0);
  not I2(s1, ns1);
  and I3(b_and_c_and_d, b, c, d);
  or  I4(a_or_bcd, a, b_and_c_and_d);
  or  I5(z_int, a_or_bcd, s1);		  //if ns1=0 (s1=1), then z_int=1; else if ns1=1 (s1=0), then z_int=a_or_bcd.
  and `MTD3L_DP I6(z, z_int, ns0);        	  	  //if s0=1 (ns0=0), then z=0; else if s0=0 (ns0=1), then z=z_int.    
endmodule // th34w3mtd3l_a
`endcelldefine

/////////////////////////////////////
//th34w32mtd3l_a
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module th34w32mtd3l_a (a, b, c, d, s0, ns1, z);
output z;
input a, b, c, d, s0, ns1;
  not I1(ns0, s0);
  not I2(s1, ns1);
  and I3(b_and_c, b, c);
  and I4(b_and_d, b, d);
  or  I5(ab_or_bc_or_bd, a, b_and_c, b_and_d);
  or  I6(z_int, ab_or_bc_or_bd, s1);		  //if ns1=0 (s1=1), then z_int=1; else if ns1=1 (s1=0), then z_int=ab_or_bc_or_bd.
  and `MTD3L_DP I7(z, z_int, ns0);        	  	  //if s0=1 (ns0=0), then z=0; else if s0=0 (ns0=1), then z=z_int.   
endmodule // th34w32mtd3l_a
`endcelldefine

/////////////////////////////////////
//th44mtd3l_a
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module th44mtd3l_a (a, b, c, d, s0, ns1, z);
output z;
input a, b, c, d, s0, ns1;
  not I1(ns0, s0);
  not I2(s1, ns1);
  and I3(a_and_b_and_c_and_d, a, b, c, d);
  or  I4(z_int, a_and_b_and_c_and_d, s1);		  //if ns1=0 (s1=1), then z_int=1; else if ns1=1 (s1=0), then z_int=a_and_b_and_c_and_d.
  and `MTD3L_DP I5(z, z_int, ns0);    	  //if s0=1 (ns0=0), then z=0; else if s0=0 (ns0=1), then z=z_int.    
endmodule // th44mtd3l_a
`endcelldefine


/////////////////////////////////////
//th44w2mtd3l_a
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module th44w2mtd3l_a (a, b, c, d, s0, ns1, z);
output z;
input a, b, c, d, s0, ns1;
  not I1(ns0, s0);
  not I2(s1, ns1);
  and I3(a_and_b_and_c, a, b, c);
  and I4(a_and_b_and_d, a, b, d);
  and I5(a_and_c_and_d, a, c, d);
  or  I6(abc_or_abd_or_acd, a_and_b_and_c, a_and_b_and_d, a_and_c_and_d);
  or  I7(z_int, abc_or_abd_or_acd, s1);		  //if ns1=0 (s1=1), then z_int=1; else if ns1=1 (s1=0), then z_int=abc_or_abd_or_acd.
  and `MTD3L_DP I8(z, z_int, ns0);        	  	  //if s0=1 (ns0=0), then z=0; else if s0=0 (ns0=1), then z=z_int.   
endmodule // th44w2mtd3l_a
`endcelldefine

/////////////////////////////////////
//th44w22mtd3l_a
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module th44w22mtd3l_a (a, b, c, d, s0, ns1, z);
output z;
input a, b, c, d, s0, ns1;
  not I1(ns0, s0);
  not I2(s1, ns1);
  and I3(a_and_b, a, b);
  and I4(a_and_c_and_d, a, c, d);
  and I5(b_and_c_and_d, b, c, d);
  or  I6(ab_or_acd_or_bcd, a_and_b, a_and_c_and_d, b_and_c_and_d);
  or  I7(z_int, ab_or_acd_or_bcd, s1);		  //if ns1=0 (s1=1), then z_int=1; else if ns1=1 (s1=0), then z_int=ab_or_acd_or_bcd.
  and `MTD3L_DP I8(z, z_int, ns0);        	  	  //if s0=1 (ns0=0), then z=0; else if s0=0 (ns0=1), then z=z_int.   
endmodule // th44w22mtd3l_a
`endcelldefine

/////////////////////////////////////
//th44w3mtd3l_a
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module th44w3mtd3l_a (a, b, c, d, s0, ns1, z);
output z;
input a, b, c, d, s0, ns1;
  not I1(ns0, s0);
  not I2(s1, ns1);
  and I3(a_and_b, a, b);
  and I4(a_and_c, a, c);
  and I5(a_and_d, a, d);
  or  I6(ab_or_ac_or_ad, a_and_b, a_and_c, a_and_d);
  or  I7(z_int, ab_or_ac_or_ad, s1);		  //if ns1=0 (s1=1), then z_int=1; else if ns1=1 (s1=0), then z_int=ab_or_ac_or_ad.
  and `MTD3L_DP I8(z, z_int, ns0);        	  	  //if s0=1 (ns0=0), then z=0; else if s0=0 (ns0=1), then z=z_int.   
endmodule // th44w3mtd3l_a
`endcelldefine

/////////////////////////////////////
//th54w22mtd3l_a
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module th54w22mtd3l_a (a, b, c, d, s0, ns1, z);
output z;
input a, b, c, d, s0, ns1;
  not I1(ns0, s0);
  not I2(s1, ns1);
  and I3(a_and_b_and_c, a, b, c);
  and I4(a_and_b_and_d, a, b, d);
  or  I5(abc_or_abd, a_and_b_and_c, a_and_b_and_d);
  or  I6(z_int, abc_or_abd, s1);		  //if ns1=0 (s1=1), then z_int=1; else if ns1=1 (s1=0), then z_int=abc_or_abd.
  and `MTD3L_DP I7(z, z_int, ns0);        	  	  //if s0=1 (ns0=0), then z=0; else if s0=0 (ns0=1), then z=z_int.  
endmodule // th54w22mtd3l_a
`endcelldefine

/////////////////////////////////////
//th54w32mtd3l_a
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module th54w32mtd3l_a (a, b, c, d, s0, ns1, z);
output z;
input a, b, c, d, s0, ns1;
  not I1(ns0, s0);
  not I2(s1, ns1);
  and I3(a_and_b, a, b);
  and I4(a_and_c_and_d, a, c, d);
  or  I5(ab_or_acd, a_and_b, a_and_c_and_d);
  or  I6(z_int, ab_or_acd, s1);		  //if ns1=0 (s1=1), then z_int=1; else if ns1=1 (s1=0), then z_int=ab_or_acd.
  and `MTD3L_DP I7(z, z_int, ns0);        	  	  //if s0=1 (ns0=0), then z=0; else if s0=0 (ns0=1), then z=z_int.    
endmodule // th54w32mtd3l_a
`endcelldefine

/////////////////////////////////////
//th44w322mtd3l_a
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module th44w322mtd3l_a (a, b, c, d, s0, ns1, z);
output z;
input a, b, c, d, s0, ns1;
  not I1(ns0, s0);
  not I2(s1, ns1);
  and I3(a_and_b, a, b);
  and I4(a_and_c, a, c);
  and I5(a_and_d, a, d);
  and I6(b_and_c, b, c);
  or  I7(ab_or_ac_or_ad_or_bc, a_and_b, a_and_c, a_and_d, b_and_c);
  or  I8(z_int, ab_or_ac_or_ad_or_bc, s1);		  //if ns1=0 (s1=1), then z_int=1; else if ns1=1 (s1=0), then z_int=ab_or_ac_or_ad_or_bc.
  and `MTD3L_DP I9(z, z_int, ns0);        	  	  //if s0=1 (ns0=0), then z=0; else if s0=0 (ns0=1), then z=z_int.   
endmodule // th44w322mtd3l_a
`endcelldefine

/////////////////////////////////////
//th54w322mtd3l_a
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module th54w322mtd3l_a (a, b, c, d, s0, ns1, z);
output z;
input a, b, c, d, s0, ns1;
  not I1(ns0, s0);
  not I2(s1, ns1);
  and I3(a_and_b, a, b);
  and I4(a_and_c, a, c);
  and I5(b_and_c_and_d, b, c, d);
  or  I6(ab_or_ac_or_bcd, a_and_b, a_and_c, b_and_c_and_d);
  or  I7(z_int, ab_or_ac_or_bcd, s1);		  //if ns1=0 (s1=1), then z_int=1; else if ns1=1 (s1=0), then z_int=ab_or_ac_or_bcd.
  and `MTD3L_DP I8(z, z_int, ns0);        	  	  //if s0=1 (ns0=0), then z=0; else if s0=0 (ns0=1), then z=z_int.     
endmodule // th54w322mtd3l_a
`endcelldefine

/////////////////////////////////////
//thxor0mtd3l_a
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module thxor0mtd3l_a (a, b, c, d, s0, ns1, z);
output z;
input a, b, c, d, s0, ns1;
  not I1(ns0, s0);
  not I2(s1, ns1);
  and I3(a_and_b, a, b);
  and I4(c_and_d, c, d);
  or  I5(ab_or_cd, a_and_b, c_and_d);
  or  I6(z_int, ab_or_cd, s1);		  //if ns1=0 (s1=1), then z_int=1; else if ns1=1 (s1=0), then z_int=ab_or_cd.
  and `MTD3L_DP I7(z, z_int, ns0);        	  	  //if s0=1 (ns0=0), then z=0; else if s0=0 (ns0=1), then z=z_int.   
endmodule // thxor0mtd3l_a
`endcelldefine

/////////////////////////////////////
//thand0mtd3l_a
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module thand0mtd3l_a (a, b, c, d, s0, ns1, z);
output z;
input a, b, c, d, s0, ns1;
  not I1(ns0, s0);
  not I2(s1, ns1);
  and I3(a_and_b, a, b);
  and I4(b_and_c, b, c);
  and I5(a_and_d, a, d);
  or  I6(ab_or_bc_or_ad, a_and_b, b_and_c, a_and_d);
  or  I7(z_int, ab_or_bc_or_ad, s1);		  //if ns1=0 (s1=1), then z_int=1; else if ns1=1 (s1=0), then z_int=ab_or_bc_or_ad.
  and `MTD3L_DP I8(z, z_int, ns0);        	  	  //if s0=1 (ns0=0), then z=0; else if s0=0 (ns0=1), then z=z_int.   
endmodule // thand0mtd3l_a
`endcelldefine



/////////////////////////////////////
//regmtd3l
////////////////////////////////////
`timescale 1ns/1ps
`celldefine

module regmtd3l (a, s0, ns1, ko, z);
output z;
input a, s0, ns1, ko;
  not I0(nko,ko);
  nand I1(not__s0_and_ns1, s0, ns1);		 //AZS: if s0_and_ns1 z=0;
  or  I2(s0_or_ns1, s0, ns1);                //AOS: if not_s0_or_ns1, z=1;
  buf I3(clr_, not__s0_and_ns1);              // reset z=0;
  buf I5(set_, s0_or_ns1);				      // set   z=1;
  udp_dff_set_prior I6(zo, a, nko, clr_, set_, NOTIFIER);
  buf `MTD3L_DP I7(z,zo);
endmodule // regmtd3l 
`endcelldefine

/////////////////////////////////////
//regdmtd3l
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module regdmtd3l (a, rst, s0, ns1, ko, z);
output z;
input a, rst, s0, ns1, ko;
  not I0(nko,ko);
  nand I1(not__s0_and_ns1, s0, ns1);		 //AZS: if s0_and_ns1 z=0;
  or  I2(s0_or_ns1, s0, ns1);               //AOS: if not_s0_or_ns1, z=1;
  buf I3(clr_, not__s0_and_ns1);              // reset z=0;
  not I4(nrst, rst);
  and I5(set_, s0_or_ns1, nrst);				  // set   z=1;
  udp_dff_set_prior I6(zo, a, nko, clr_, set_, NOTIFIER);
  buf `MTD3L_DP I7(z,zo);
endmodule // regdmtd3l 
`endcelldefine

/////////////////////////////////////
//regnmtd3l
////////////////////////////////////
`timescale 1ns/1ps
`celldefine

module regnmtd3l (a, rst, s0, ns1, ko, z);
output z;
input a, rst, s0, ns1, ko;
  not I0(nko,ko);
  and I1(s0_and_ns1, s0, ns1);				  //AZS: if s0_and_ns1 z=0;
  or  I2(s0_or_ns1, s0, ns1);               //AOS: if not_s0_or_ns1, z=1;
  nor I3(clr_, s0_and_ns1, rst);              // reset z=0;
  buf I4(set_, s0_or_ns1);				  // set   z=1;
  udp_dff_clr_prior I12(zo, a, nko, clr_, set_, NOTIFIER);
  buf `MTD3L_DP I13(z,zo);
endmodule // regnmtd3l  
`endcelldefine

/////////////////////////////////////
//spkpmtd3l
////////////////////////////////////
`timescale 1ns/1ps
`celldefine

module spkpmtd3l (a, b, ko, rst, ps, not_ps);
output ps, not_ps;
input a, b, ko, rst;
supply1 xCLR, xSET;

  //th22_a u_new_spacer (.a(a), .b(b), .z(new_spacer));
  udp_rslat_out I0_th22(new_spacer, R0, S0, NOTIFIER);
  //buf  I4_th22(new_spacer, new_spacer_s);
  and  I2_th22(S0, a, b);
  nor  I3_th22(R0, a, b); 

  //previous spacer storage 
  not I1_store(nrst, rst);
  //not I3_store(nko, ko);
   udp_tlat I2_store(ps_wire, new_spacer, ko, xCLR, nrst, NOTIFIER);
   
  //inv_a u_inv_not_ps (.a(ps_wire), .z(not_ps_wire));
  not  I1_inv(not_ps_wire, ps_wire);
  buf `MTD3L_DP I2_buf(not_ps, not_ps_wire); 
  buf `MTD3L_DP I1_buf(ps, ps_wire);  
   
endmodule // spkpmtd3l

`endcelldefine

/////////////////////////////////////
//spacer
////////////////////////////////////
`timescale 1ns/1ps
`celldefine

module spacer (ds, ki, zr1, zr0, rst, ko, s0, ns1, ko_c);
output ko, s0, ns1, ko_c;
input ds, ki, zr1,zr0, rst;

//th22n_a u_syn (.a(ds), .b(ki), .rst(rst), .z(not_ko))        //synchronization

    udp_rslat_out I0_syn(not_ko, R_syn, S_syn, NOTIFIER);   
  and  I2_syn(ds_and_ki, ds, ki);
  or   I3_syn(ds_or_ki, ds, ki);
  not  I4_syn(not_ds_or_ki, ds_or_ki);
  not  I5_syn(not_rst_syn, rst);
  and  I6_syn(S_syn, ds_and_ki, not_rst_syn);
  or   I7_syn(R_syn, not_ds_or_ki, rst);

//th22n_a u_new_spacer (.a(zr1), .b(zr0), .rst(rst), .z(new_spacer)) 	//new spacer  
    udp_rslat_out I0_new(new_spacer, R_new, S_new, NOTIFIER);
  and  I2_new(zr1_and_zr0, zr1, zr0);
  or   I3_new(zr1_or_zr0, zr1, zr0);
  not  I4_new(not_zr1_or_zr0, zr1_or_zr0);
  not  I5_new(not_rst_new, rst);
  and  I6_new(S_new, zr1_and_zr0, not_rst_new);
  or   I7_new(R_new, not_zr1_or_zr0, rst);
  
//Previous spacer flag storage and update loop:  update trigger(new_spacer, ko), 
//									             storage/update loop: ps --> not_ps --> ko_xor --> ps  
//th22d_a u_previous_spacer (.a(new_spacer), .b(ko_xor), .rst(rst), .z(ps))     //previous spacer  
	udp_rslat_out I0_pre(ps, R_pre, S_pre, NOTIFIER);  
  and  I2_pre(new_spacer_and_ko_xor, new_spacer, ko_xor);
  or   I3_pre(new_spacer_or_ko_xor, new_spacer, ko_xor);
  not  I4_pre(not_new_spacer_or_ko_xor, new_spacer_or_ko_xor);
  not  I5_pre(not_rst_pre, rst);
  or   I6_pre(S_pre, new_spacer_and_ko_xor, rst);
  and  I7_pre(R_pre, not_new_spacer_or_ko_xor, not_rst_pre);  
//not_ps
  not  I_not_ps(not_ps, ps);
//ko_xor
  not  I_ko_int(ko_int, not_ko);
  xor  `MTD3L_LOOP I_ko_xor(ko_xor, ko_int, not_ps);

//s0 ns1
  nor `MTD3L_DP I_s0(s0, not_ko, not_ps);
  or  `MTD3L_DP I_ns1(ns1, not_ko, ps);

//ko ko_c
  not `MTD3L_DP I_ko(ko, not_ko);
  not `MTD3L_DP I_ko_c(ko_c, not_ko);

endmodule // spacer
`endcelldefine


/////////////////////////////////////
//regazsmtd3l
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module regazsmtd3l (a1, a0, rst, s0, ns1, ko, z1, z0, ds);
output z1, z0, ds;
input a1, a0, rst, s0, ns1, ko;
supply1 xCLR, xSET;
//local control signals
  not I0(nko,ko);
  not I1(nrst,rst);
//functions  
  //a1-->z1 
  udp_dff_clr_prior I_z1(z1_int, a1, nko, nrst, xSET, NOTIFIER);
  //a0-->z0 
  udp_dff_clr_prior I_z0(z0_int, a0, nko, nrst, xSET, NOTIFIER);  
  //zd=a1xora0
  xor I_zd(zd_int, a1, a0);  
//outputs control
  nand I_c1(not__s0_and_ns1, s0, ns1);			  //AZS: if s0=ns1=1 z=0;
  nor  I_c2(not__s0_or_ns1, s0, ns1);             //AOS: if s0=ns1=0, z=1;
  //z1
  and I_z1_o1(z1_o0, z1_int, not__s0_and_ns1, nrst);// reset z=0;
  or  I_z1_o2(z1_o1, z1_o0, not__s0_or_ns1); 				// set   z=1;
  buf `MTD3L_DP I_z1_o(z1,z1_o1);
  //z0
  and I_z0_o1(z0_o0, z0_int, not__s0_and_ns1, nrst);// reset z=0;
  or  I_z0_o2(z0_o1, z0_o0, not__s0_or_ns1) ;			// set   z=1;
  buf `MTD3L_DP I_z0_o(z0,z0_o1);
  //zd
  buf `MTD3L_DP I_ds_o(ds,zd_int);  
endmodule // regazsmtd3l 
`endcelldefine



/////////////////////////////////////
//regaosmtd3l
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module regaosmtd3l (a1, a0, rst, s0, ns1, ko, z1, z0, ds);
output z1, z0, ds;
input a1, a0, rst, s0, ns1, ko;
//local control signals
  not I0(nko,ko);
  nand I1(not__s0_and_ns1, s0, ns1);		 //AZS: if s0_and_ns1 z=0;
  or  I2(s0_or_ns1, s0, ns1);               //AOS: if not_s0_or_ns1, z=1;
  buf I3(clr_, not__s0_and_ns1);              // reset z=0;
  not I4(nrst, rst);
  and I5(set_, s0_or_ns1, nrst);				  // set   z=1;
//a1-->z1 
  udp_dff_set_prior I_z1(z1_int, a1, nko, clr_, set_, NOTIFIER);
//a0-->z0 
  udp_dff_set_prior I_z0(z0_int, a0, nko, clr_, set_, NOTIFIER);  
//zd
  xor I_zd(zd_int, a1, a0);  
//outputs  
  buf `MTD3L_DP I_z1_o(z1,z1_int);
  buf `MTD3L_DP I_z0_o(z0,z0_int);
  buf `MTD3L_DP I_zd_o(ds,zd_int);  
endmodule // regaosmtd3l 
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


/////////////////////////////////////
//udp_dff_clr_prior
////////////////////////////////////
`ifdef udp_dff_clr_prior_READ
`else
primitive udp_dff_clr_prior (out, in, clk, clr_, set_, NOTIFIER);
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
   ?  ?   1   0   ?   : ?  :  1  ; // set output
   ?  b   1   *   ?   : 1  :  1  ; // cover all transistions on set_
   1  x   1   *   ?   : 1  :  1  ; // cover all transistions on set_
   ?  ?   0   ?   ?   : ?  :  0  ; // reset output
   ?  b   *   1   ?   : 0  :  0  ; // cover all transistions on clr_
   0  x   *   1   ?   : 0  :  0  ; // cover all transistions on clr_
   ?  ?   ?   ?   *   : ?  :  x  ; // any notifier changed

   endtable
endprimitive // udp_dff_clr_prior
`endif

/////////////////////////////////////
//udp_dff_set_prior
////////////////////////////////////
`ifdef udp_dff_set_prior_READ
`else
primitive udp_dff_set_prior (out, in, clk, clr_, set_, NOTIFIER);
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
endprimitive // udp_dff_set_prior
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

`define udp_rslat_out_READ
`define udp_dff_clr_prior_READ
`define udp_dff_set_prior_READ
`define udp_tlat_READ