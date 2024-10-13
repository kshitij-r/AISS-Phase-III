// Verilog model for MTNCL gates
// Gate list -- bufferm_a th12m_a  th12dm_a th12nm_a th13m_a th14m_a th22m_a th23m_a th23w2m_a th24m_a th24w2m_a th24w22m_a th24compm_a
//              th33m_a th33w2m_a th34m_a th34w2m_a th34w22m_a th34w3m_a th34w32m_a th44m_a th44w2m_a th44w22m_a th44w3m_a th44w322m_a
//              th54w22m_a th54w32m_a  th54w322m_a thand0m_a thxor0m_a thregdm_a thregnm_a
// date                version         description
// 4-29-2022            1.0             original
// 6-7-2022             1.1             add regdm_a regnullm_a 

`ifndef MTNCL_GATE
`define MTNCL_GATE
//`define MTNCL_DP  			#0.001
`define MTNCL_DP  			#0.010

/////////////////////////////////////
//bufferm_a
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module bufferm_a (a, s, z);
output z;
input a, s;
  not I1(not_s, s);
  and `MTNCL_DP I2(z, a, not_s);
endmodule // bufferm_a
`endcelldefine

/////////////////////////////////////
//th12m_a
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module th12m_a (a, b, s, z);
output z;
input a, b, s;
  not I1(not_s, s);
  or  I2(a_or_b, a, b);
  and `MTNCL_DP I3(z, a_or_b, not_s);
endmodule // th12m_a
`endcelldefine

/////////////////////////////////////
//th12dm_a
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module th12dm_a (a, b, rst, s, z);
output z;
input a, b, rst, s;
  not I1(not_s, s);
  or  I2(a_or_b, a, b);
  and I3(z_int, a_or_b, not_s);
  or `MTNCL_DP I4(z, z_int, rst);
endmodule // th12dm_a
`endcelldefine

/////////////////////////////////////
//th12nm_a
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module th12nm_a (a, b, rst, s, z);
output z;
input a, b, rst, s;
  not I1(not_s, s);
  or  I2(a_or_b, a, b);
  and I3(z_int, a_or_b, not_s);
  not I4(not_rst, rst);
  and `MTNCL_DP I5(z, z_int, not_rst);
endmodule // th12nm_a
`endcelldefine

/////////////////////////////////////
//th13m_a
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module th13m_a (a, b, c, s, z);
output z;
input a, b, c, s;
  not I1(not_s, s);
  or  I2(a_or_b, a, b, c);
  and `MTNCL_DP I3(z, a_or_b, not_s);
endmodule // th13m_a
`endcelldefine

/////////////////////////////////////
//th14m_a
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module th14m_a (a, b, c, d, s, z);
output z;
input a, b, c, d, s;
  not I1(not_s, s);
  or  I2(a_or_b, a, b, c, d);
  and `MTNCL_DP I3(z, a_or_b, not_s);
endmodule // th14m_a
`endcelldefine

/////////////////////////////////////
//th22m_a
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module th22m_a (a, b, s, z);
output z;
input a, b, s;
  not I1(not_s, s);
  and  I2(a_and_b, a, b);
  and `MTNCL_DP I3(z, a_and_b, not_s);
endmodule // th22m_a
`endcelldefine

/////////////////////////////////////
//th23m_a
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module th23m_a (a, b, c, s, z);
output z;
input a, b, c, s;
  not I1(not_s, s);
  and I2(a_and_b, a, b);
  and I3(a_and_c, a, c);
  and I4(b_and_c, b, c);
  or  I5(ab_or_ac_or_bc, a_and_b, a_and_c, b_and_c);
  and `MTNCL_DP I6(z, ab_or_ac_or_bc, not_s);
endmodule // th23m_a
`endcelldefine

/////////////////////////////////////
//th23w2m_a
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module th23w2m_a (a, b, c, s, z);
output z;
input a, b, c, s;
  not I1(not_s, s);
  and I2(b_and_c, b, c);
  or  I3(a_or_bc, a, b_and_c);
  and `MTNCL_DP I4(z, a_or_bc, not_s);
endmodule // th23w2m_a
`endcelldefine


/////////////////////////////////////
//th24m_a
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module th24m_a (a, b, c, d, s, z);
output z;
input a, b, c, d, s;
  not I1(not_s, s);
  and I2(a_and_b, a, b);
  and I3(a_and_c, a, c);
  and I4(a_and_d, a, d);
  and I5(b_and_c, b, c);
  and I6(b_and_d, b, d);
  and I7(c_and_d, c, d);
  or  I8(ab_or_ac_or_ad_or_bc_or_bd_or_cd, a_and_b, a_and_c, a_and_d, b_and_c, b_and_d, c_and_d);
  and `MTNCL_DP I9(z, ab_or_ac_or_ad_or_bc_or_bd_or_cd, not_s);
endmodule // th24m_a
`endcelldefine


/////////////////////////////////////
//th24w2m_a
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module th24w2m_a (a, b, c, d, s, z);
output z;
input a, b, c, d, s;
  not I1(not_s, s);
  and I2(b_and_c, b, c);
  and I3(b_and_d, b, d);
  and I4(c_and_d, c, d);
  or  I5(a_or_bc_or_bd_or_cd, a, b_and_c, b_and_d, c_and_d);
  and `MTNCL_DP I6(z, a_or_bc_or_bd_or_cd, not_s);
endmodule // th24w2m_a
`endcelldefine


/////////////////////////////////////
//th24w22m_a
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module th24w22m_a (a, b, c, d, s, z);
output z;
input a, b, c, d, s;
  not I1(not_s, s);
  and I2(c_and_d, c, d);
  or  I3(a_or_b_or_cd, a, b, c_and_d);
  and `MTNCL_DP I4(z, a_or_b_or_cd, not_s);
endmodule // th24w22m_a
`endcelldefine

/////////////////////////////////////
//th24compm_a
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module th24compm_a (a, b, c, d, s, z);
output z;
input a, b, c, d, s;
  not I1(not_s, s);
  or  I2(a_or_b, a, b);
  or  I3(c_or_d, c, d);
  and I4(a_or_b__and__c_or_d, a_or_b, c_or_d);
  and `MTNCL_DP I5(z, a_or_b__and__c_or_d, not_s);
endmodule // th24compm_a
`endcelldefine

/////////////////////////////////////
//th33m_a
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module th33m_a (a, b, c, s, z);
output z;
input a, b, c, s;
  not I1(not_s, s);
  and  I2(a_and_b_and_c, a, b, c);
  and `MTNCL_DP I3(z, a_and_b_and_c, not_s);
endmodule // th33m_a
`endcelldefine

/////////////////////////////////////
//th33w2m_a
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module th33w2m_a (a, b, c, s, z);
output z;
input a, b, c, s;
  not I1(not_s, s);
  and I2(a_and_b, a, b);
  and I3(a_and_c, a, c);
  or  I4(ab_or_ac, a_and_b, a_and_c);
  and `MTNCL_DP I6(z, ab_or_ac, not_s);
endmodule // th33w2m_a
`endcelldefine

/////////////////////////////////////
//th34m_a
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module th34m_a (a, b, c, d, s, z);
output z;
input a, b, c, d, s;
  not I1(not_s, s);
  and  I2(a_and_b_and_c, a, b, c);
  and  I3(a_and_c_and_d, a, c, d);
  and  I4(a_and_b_and_d, a, b, d);
  and  I5(b_and_c_and_d, b, c, d); 
  or   I6(abc_or_acd_or_abd_or_bcd, a_and_b_and_c, a_and_c_and_d, a_and_b_and_d, b_and_c_and_d);
  and `MTNCL_DP I7(z, abc_or_acd_or_abd_or_bcd, not_s);
endmodule // th34m_a
`endcelldefine

/////////////////////////////////////
//th34w2m_a
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module th34w2m_a (a, b, c, d, s, z);
output z;
input a, b, c, d, s;
  not I1(not_s, s);
  and I2(a_and_b, a, b);
  and I3(a_and_c, a, c);
  and I4(a_and_d, a, d);
  and I5(b_and_c_and_d, b, c, d);
  or  I6(ab_or_ac_or_ad_or_bcd, a_and_b, a_and_c, a_and_d, b_and_c_and_d);
  and `MTNCL_DP I7(z, ab_or_ac_or_ad_or_bcd, not_s);
endmodule // th34w2m_a
`endcelldefine

/////////////////////////////////////
//th34w22m_a
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module th34w22m_a (a, b, c, d, s, z);
output z;
input a, b, c, d, s;
  not I1(not_s, s);
  and I2(a_and_b, a, b);
  and I3(a_and_c, a, c);
  and I4(a_and_d, a, d);
  and I5(b_and_c, b, c);
  and I6(b_and_d, b, d);
  or  I7(ab_or_ac_or_ad_or_bc_or_bd, a_and_b, a_and_c, a_and_d, b_and_c, b_and_d);
  and `MTNCL_DP I8(z, ab_or_ac_or_ad_or_bc_or_bd, not_s);
endmodule // th34w22m_a
`endcelldefine

/////////////////////////////////////
//th34w3m_a
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module th34w3m_a (a, b, c, d, s, z);
output z;
input a, b, c, d, s;
  not I1(not_s, s);
  and I2(b_and_c_and_d, b, c, d);
  or  I3(a_or_bcd, a, b_and_c_and_d);
  and `MTNCL_DP I4(z, a_or_bcd, not_s);
endmodule // th34w3m_a
`endcelldefine

/////////////////////////////////////
//th34w32m_a
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module th34w32m_a (a, b, c, d, s, z);
output z;
input a, b, c, d, s;
  not I1(not_s, s);
  and I2(b_and_c, b, c);
  and I3(b_and_d, b, d);
  or  I4(ab_or_bc_or_bd, a, b_and_c, b_and_d);
  and `MTNCL_DP I5(z, ab_or_bc_or_bd, not_s);
endmodule // th34w32m_a
`endcelldefine


/////////////////////////////////////
//th44m_a
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module th44m_a (a, b, c, d, s, z);
output z;
input a, b, c, d, s;
  not I1(not_s, s);
  and  I2(a_and_b_and_c_and_d, a, b, c, d);
  and `MTNCL_DP I3(z, a_and_b_and_c_and_d, not_s);
endmodule // th44m_a
`endcelldefine

/////////////////////////////////////
//th44w2m_a
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module th44w2m_a (a, b, c, d, s, z);
output z;
input a, b, c, d, s;
  not I1(not_s, s);
  and  I2(a_and_b_and_c, a, b, c);
  and  I3(a_and_b_and_d, a, b, d);
  and  I4(a_and_c_and_d, a, c, d);
  or   I5(abc_or_abd_or_acd, a_and_b_and_c, a_and_b_and_d, a_and_c_and_d);
  and `MTNCL_DP I6(z, abc_or_abd_or_acd, not_s);
endmodule // th44w2m_a
`endcelldefine

/////////////////////////////////////
//th44w22m_a
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module th44w22m_a (a, b, c, d, s, z);
output z;
input a, b, c, d, s;
  not I1(not_s, s);
  and  I2(a_and_b, a, b);
  and  I3(a_and_c_and_d, a, c, d);
  and  I4(b_and_c_and_d, b, c, d);
  or   I5(ab_or_acd_or_bcd, a_and_b, a_and_c_and_d, b_and_c_and_d);
  and `MTNCL_DP I6(z, ab_or_acd_or_bcd, not_s);
endmodule // th44w22m_a
`endcelldefine

/////////////////////////////////////
//th44w3m_a
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module th44w3m_a (a, b, c, d, s, z);
output z;
input a, b, c, d, s;
  not I1(not_s, s);
  and I2(a_and_b, a, b);
  and I3(a_and_c, a, c);
  and I4(a_and_d, a, d);
  or  I5(ab_or_ac_or_ad, a_and_b, a_and_c, a_and_d);
  and `MTNCL_DP I6(z, ab_or_ac_or_ad, not_s);
endmodule // th44w3m_a
`endcelldefine

/////////////////////////////////////
//th44w322m_a
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module th44w322m_a (a, b, c, d, s, z);
output z;
input a, b, c, d, s;
  not I1(not_s, s);
  and I2(a_and_b, a, b);
  and I3(a_and_c, a, c);
  and I4(a_and_d, a, d);
  and I5(b_and_c, b, c);
  or  I6(ab_or_ac_or_ad_or_bc, a_and_b, a_and_c, a_and_d, b_and_c);
  and `MTNCL_DP I7(z, ab_or_ac_or_ad_or_bc, not_s);
endmodule // th44w322m_a
`endcelldefine

/////////////////////////////////////
//th54w22m_a
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module th54w22m_a (a, b, c, d, s, z);
output z;
input a, b, c, d, s;
  not I1(not_s, s);
  and  I2(a_and_b_and_c, a, b, c);
  and  I3(a_and_b_and_d, a, b, d);
  or   I4(abc_or_abd, a_and_b_and_c, a_and_b_and_d);
  and `MTNCL_DP I5(z, abc_or_abd, not_s);
endmodule // th54w22m_a
`endcelldefine

/////////////////////////////////////
//th54w32m_a
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module th54w32m_a (a, b, c, d, s, z);
output z;
input a, b, c, d, s;
  not I1(not_s, s);
  and  I2(a_and_b, a, b);
  and  I3(a_and_c_and_d, a, c, d);
  or   I4(ab_or_acd, a_and_b, a_and_c_and_d);
  and `MTNCL_DP I5(z, ab_or_acd, not_s);
endmodule // th54w32m_a
`endcelldefine


/////////////////////////////////////
//th54w322m_a
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module th54w322m_a (a, b, c, d, s, z);
output z;
input a, b, c, d, s;
  not I1(not_s, s);
  and  I2(a_and_b, a, b);
  and  I3(a_and_c, a, c);
  and  I4(b_and_c_and_d, b, c, d);
  or   I5(ab_or_ac_or_bcd, a_and_b, a_and_c, b_and_c_and_d);
  and `MTNCL_DP I6(z, ab_or_ac_or_bcd, not_s);
endmodule // th54w322m_a
`endcelldefine

/////////////////////////////////////
//thand0m_a
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module thand0m_a (a, b, c, d, s, z);
output z;
input a, b, c, d, s;
  not I1(not_s, s);
  and I2(a_and_b, a, b);
  and I3(b_and_c, b, c);
  and I4(a_and_d, a, d);
  or  I5(ab_or_bc_or_ad, a_and_b, b_and_c, a_and_d);
  and `MTNCL_DP I6(z, ab_or_bc_or_ad, not_s);
endmodule // thand0m_a
`endcelldefine

/////////////////////////////////////
//thxor0m_a
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module thxor0m_a (a, b, c, d, s, z);
output z;
input a, b, c, d, s;
  not I1(not_s, s);
  and I2(a_and_b, a, b);
  and I3(c_and_d, c, d);
  or  I4(ab_or_cd, a_and_b, c_and_d);
  and `MTNCL_DP I5(z, ab_or_cd, not_s);
endmodule // thxor0m_a
`endcelldefine

/////////////////////////////////////
//thregdm_a
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module thregdm_a (a, rst, s, z);
output z;
input a, rst, s;
  not I1(not_s, s);
  or  I2(a_or_z_int, a, z_int);
  and I3(z_int, a_or_z_int, not_s);
  or `MTNCL_DP I4(z, z_int, rst);
endmodule // thregdm_a
`endcelldefine

/////////////////////////////////////
//thregnm_a
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module thregnm_a (a, rst, s, z);
output z;
input a, rst, s;
  not I1(not_s, s);
  or  I2(a_or_z_int, a, z_int);
  and I3(z_int, a_or_z_int, not_s);
  not I4(not_rst, rst);
  and `MTNCL_DP I5(z, z_int, not_rst);
endmodule // thregnm_a
`endcelldefine


/////////////////////////////////////
//regdm_a
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module regdm_a (a0, a1, rst, sr, z0, z1, sd, zd);
output z0, z1, zd;
input a0, a1, rst, sr, sd;
  //thregdm_a for a1-->z1  rst-->z1=1
  not Id1(not_sr, sr);
  or  Id2(a1_or_z1_int, a1, z1_int);
  and Id3(z1_int, a1_or_z1_int, not_sr);
  or `MTNCL_DP Id4(z1, z1_int, rst);
  //thregnm_a for a0-->z0  rst-->z0=0
  or  In2(a0_or_z0_int, a0, z0_int);
  and In3(z0_int, a0_or_z0_int, not_sr);
  not In4(not_rst, rst);
  and `MTNCL_DP In5(z0, z0_int, not_rst);
  //th12m_a  for complete done detection 
  not I1(not_sd, sd);
  or  I2(a0_or_a1, a0, a1);
  and `MTNCL_DP I3(zd, a0_or_a1, not_sd);
endmodule // regdm_a
`endcelldefine


/////////////////////////////////////
//regnullm_a
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module regnullm_a (a0, a1, rst, sr, z0, z1, sd, zd);
output z0, z1, zd;
input a0, a1, rst, sr, sd;
  //thregnm_a for a1-->z1  rst-->z1=0
  not In11(not_sr, sr);
  or  In12(a1_or_z1_int, a1, z1_int);
  and In13(z1_int, a1_or_z1_int, not_sr);
  not In14(not_rst, rst);
  and `MTNCL_DP I5(z1, z1_int, not_rst);
  //thregnm_a for a0-->z0  rst-->z0=0
  or  In02(a0_or_z0_int, a0, z0_int);
  and In03(z0_int, a0_or_z0_int, not_sr);
  and `MTNCL_DP In05(z0, z0_int, not_rst);
  //th12m_a  for complete done detection 
  not I1(not_sd, sd);
  or  I2(a0_or_a1, a0, a1);
  and `MTNCL_DP I3(zd, a0_or_a1, not_sd);
endmodule // regnullm_a
`endcelldefine



`endif