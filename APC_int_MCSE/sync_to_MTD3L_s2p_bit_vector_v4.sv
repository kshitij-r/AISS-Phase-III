//file name: sync_to_MTD3L_s2p_bit_vector.sv
//module name: sync_to_MTD3L_s2p_bit_vector
//instance list -- DFFRPQ,  INV_A, PREICG, XOR2_A, compmtd3l, regnmtd3l, spkpmtd3l, AND2_A, buffermtd3l_a
//`include "NCL_signals.pkg.sv"           //dual_rail_logic  
//`include "BOOLEAN_gates.v"              //DFFRPQ, INV_A, PREICG, XOR2_A, AND2_A
//`include "MTD3L_gates.v"             //regnmtd3l, spkpmtd3l
//`include "MTD3L_completion.sv"       //compmtd3l
//'include "MTD3L_gates.v"             // buffermtd3l_a

// DATE        Version           Description
//8-23-2022      1.0              original (output z is bit vector, rail0-> 2*i, rail1->2*i+1, where 0<=i<width)
//9-1-2022       2.0              add buffermtd3l_a to generate AZS AOS; 
//                                change LINK output FULL to EMPTY (xnor_2)
//10-19-2022     3.0              update the structure with spacer and regazsmtd3l nacros, and compnmtd3l_sr module
//                                change nxor2_a to XOR2_A in LINK
//11-29-2022     4.1              Change port "ds" of regazsmtd3l into "zd"
//                                Change inv_a to INV_A; and2_a to AND2_A
//1-17-2023      4.2              Add s0 ns1 output ports
//1-27-2023			  Change the "zd" back to "ds
//				  Change XOR2_A ports to uppercase
module sync_to_MTD3L_s2p_bit_vector #(parameter width = 612)
                    (data_in, data_in_valid, clk, reset, word_en, data_req, ki, sleep_out, s0, ns1, z);
	// inport package into module scope	
	import NCL_signals::*; 
						
    //Synchrous interface
	input logic clk, reset;
	input logic data_in, data_in_valid, word_en;
	output logic data_req;	
	//MTD3L interface
	input logic ki;
    output logic [2*width-1:0]	z;
	output logic sleep_out, s0, ns1; 

//////////////////////////////////////////////////////////////////////
//Synchronous to MTD3L stage --- ////
/////////////////////////////////////////////////////////////////////
	
	// generate gated clock with word_en for LINK token
	wire logic clk_gated;
	PREICG u_clk_gate (.CK(clk), .E(word_en), .SE(1'b0), .ECK(clk_gated));      //ICG (Integrated latch Clock Gate) for positive edge-trigger flops

	// generate LINK token for MTD3L output
	wire logic  full;
    wire ko, ko_bar;	
	wire logic link_l_q, link_l_q_bar, link_r_q, link_r_q_bar;
	DFFRPQ u_link_l (.Q(link_l_q), .CK(clk_gated), .D(link_l_q_bar), .R(reset));         //LINK left registe:reset high-active, switch at out_en rising edge
	inv_a  u_inv_link_l (.a(link_l_q), .z(link_l_q_bar)); 
	inv_a  u_sleep_out_bar (.a(ko), .z(ko_bar)); 
	DFFRPQ u_link_r (.Q(link_r_q), .CK(ko_bar), .D(link_r_q_bar), .R(reset));  //LINK right register: reset high-active, switch at ko falling edge
	inv_a  u_inv_link_r (.a(link_r_q), .z(link_r_q_bar)); 
	XOR2_A u_sleep (.A(link_l_q), .B(link_r_q), .Z(full));                        //LINK FULL output
	
	//generate gated clock with data_in_valid for data register
	wire logic clk_d_gated;
	PREICG u_clk_d_gate (.CK(clk), .E(data_in_valid), .SE(1'b0), .ECK(clk_d_gated));      //ICG (Integrated latch Clock Gate) for positive edge-trigger flops
	
	// register data and SDC 
	wire dual_rail_logic [width-1:0] d_int, dr_int;
	wire logic s0_c, ns1_c;
	wire logic [width:0] q;
    assign q[width] = data_in;
	genvar i;
	generate
		for (i=0; i<width; i++) begin
			//data capture and rail1 data
			DFFRPQ u_dff_capt (.Q(q[i]), .CK(clk_d_gated), .D(q[i+1]), .R(reset));     //rst high-active
			assign d_int[i].rail1 = q[i];
			buffermtd3l_a u_buf_mtd3l_r1(.a(d_int[i].rail1), .s0(s0_c), .ns1(ns1_c), .z(dr_int[i].rail1));			
			//rail0 data
			inv_a  u_inv_capt (.a(q[i]), .z(d_int[i].rail0));  
			buffermtd3l_a u_buf_mtd3l_r0(.a(d_int[i].rail0), .s0(s0_c), .ns1(ns1_c), .z(dr_int[i].rail0));			
		end		
    endgenerate	 	

//Input Spacer s0_c/ns1_c generator //
	wire logic ko_in, ko_c_in;
	spacer u_spacer (.ds(full), .ki(ko), .zr1(dr_int[0].rail1), .zr0(dr_int[0].rail0), .rst(reset), .ko(ko_in), .s0(s0_c), .ns1(ns1_c), .ko_c(ko_c_in));

//////////////////////////////////////////////////////////////////////
//MTD3L Stage --- ////
/////////////////////////////////////////////////////////////////////

//MTD3L Registers /// --reset to AZS
  wire dual_rail_logic [width-1:0] z_int;
  wire logic [width-1:0] ds_reg;
  wire s0_reg, ns1_reg;
  genvar j;
  generate
	for (j=0; j<width; j++) begin  //reset to "00" or AZS
		regazsmtd3l u_reg (.a1(dr_int[j].rail1), .a0(dr_int[j].rail0), .rst(reset), .s0(s0_reg), .ns1(ns1_reg), .ko(ko), .z1(z_int[j].rail1), .z0(z_int[j].rail0), .ds(ds_reg[j]));
		assign z[2*j+1] = z_int[j].rail1;
		assign z[2*j]   = z_int[j].rail0;
	end
  endgenerate
  
//Spacer and data genration control//
  compnmtd3l_sr #(.width(width)) u_compin (.zd(ds_reg), .ki(ki), .rst(reset), .sleep(ko_c_in), .zr1(z_int[0].rail1), .zr0(z_int[0].rail0), .ko(ko), .ko_c(sleep_out), .s0(s0_reg), .ns1(ns1_reg));
  assign s0 = s0_reg;
  assign ns1= ns1_reg;
  
//Output data_reqest (to sync) 
  and2_a u_data_request (.a(ki), .b(ko), .z(data_req));

endmodule  //sync_to_MTD3L_s2p_bit_vector

