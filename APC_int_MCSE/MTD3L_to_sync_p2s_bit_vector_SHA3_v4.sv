//file name: MTD3L_to_sync_p2s_bit_vector.sv
//module name: MTD3L_to_sync_p2s_bit_vector
//instance list -- compnmtd3l_sr, XOR2_A, DFFRPQ, DFFRPQN, PREICG, SDFFRPQ ,LATNQ, INV_A
//`include "NCL_signals.pkg.sv"     //dual_rail_logic
//`include "BOOLEAN_gates.v"        //LATNQ, XOR2_A, DFFRPQ, DFFRPQN, SDFFRPQ, INV_A 
//`include "MTD3L_completion.sv"  //compnmtd3l_sr
//`include "MTD3L_gate.v"         //regazsmtd3l spacer

// DATE        Version           Description
//8-22-2022      1.0              original
//10-22-2022     2.0              add divide counter width parameter
//11-22-2022     4.0              Change the output register DFFRPQ into regazsmtd3l
//                                Change compmtd3l_clk into compnmtd3l_sr
//                                Add ki_b input port and connect with data_valid outside to ease testing
//11-29-2022     4.1              Change port "ds" of regazsmtd3l into "zd"
//                                Change inv_a to INV_A
//1-18-2023      4.2              Change inv_a from clk_out_gated to clk, using falling edge of clk to trigger PREICG
module MTD3L_to_sync_p2s_bit_vector_SHA3 #(parameter width = 512, div_width = 512)
                    (data_in, sleep_in, ko, clk, reset, ki_b, data_valid, data_out);
	// inport package into module scope	
	import NCL_signals::*; 	
	
    //global signal
    input reset;
	//MTD3L interface
    input logic [2*width-1:0]	data_in;
	input logic sleep_in;
	output logic ko;
    //Synchrous interface
	input logic clk;
	input logic ki_b;		
	output logic data_out; 
	output logic data_valid;

///////////////////////////////
//bit vector to dual rail
//////////////////////////////	
  wire dual_rail_logic [width-1:0] data_in_dr;
  genvar n;
  generate
    for (n=0; n<width; n++) begin
		assign data_in_dr[n].rail1 = data_in[2*n+1];
		assign data_in_dr[n].rail0 = data_in[2*n];	
    end
  endgenerate	
	
	
//////////////////////////////////////////////////////////////////////
//MTD3L stage --- ////
/////////////////////////////////////////////////////////////////////
  wire logic clk_capture_r;
  wire logic [width-1:0] data_captured; //single rail data
  wire logic [width-1:0] data_captured_r0; //rail0 of the data
//MTD3L Registers /// --reset to AZS
  wire logic [width-1:0] zd;
  wire s0, ns1;
  wire ki;
  genvar i;
  generate
	for (i=0; i<width; i++) begin  //reset to "00" or AZS
		regazsmtd3l u_reg (.a1(data_in_dr[i].rail1), .a0(data_in_dr[i].rail0), .rst(reset), .s0(s0), .ns1(ns1), .ko(clk_capture_r), .z1(data_captured[i]), .z0(data_captured_r0[i]), .ds(zd[i]));
	end
  endgenerate
  
//Completion stage -- Spacer and data genration control//
  compnmtd3l_sr #(.width(width)) u_compout (.zd(zd), .ki(ki), .rst(reset), .sleep(sleep_in), .zr1(data_captured[0]), .zr0(data_captured_r0[0]), .ko(clk_capture_r), .ko_c(), .s0(s0), .ns1(ns1));

//invertion of ki_b input to get normal ki  
  inv_a  u_ki_inv   (.a(ki_b), .z(ki));           //added inverter to match data_valid(ki_b) and ki

//output ko
   assign ko = clk_capture_r;

//////////////////////////////////////////////////////////////////////
//MTD3L  to Synchronous stage --- ////
/////////////////////////////////////////////////////////////////////
	
	//generate clk_capture to trigger LINK with rising edge 
	wire logic clk_capture;
    inv_a  u_clk_cap   (.a(clk_capture_r), .z(clk_capture));           //added inverter to use clk_capture rising edge 	

    //generate gated clock for clk divider
	wire logic data_valid_int;
	wire logic clk_out_gated;
	wire logic clk_bar;
    inv_a  u_inv_clk (.a(clk), .z(clk_bar)); 
	PREICG u_clk_gate (.CK(clk_bar), .E(data_valid_int), .SE(1'b0), .ECK(clk_out_gated));      //ICG (Integrated latch Clock Gate) for positive edge-trigger flops
	
	//count output data number before generate clk_div for LINK right
	wire logic [$clog2(div_width):0] div;
	assign div[0] = clk_out_gated;
	genvar j;
	generate
	  for (j=0; j<$clog2(div_width); j++) begin
		DFFRPQN u_div (.QN(div[j+1]), .CK(div[j]), .D(div[j+1]), .R(reset));         //Asynchronous couter/division of power of 2
	  end
	endgenerate
     
	//generate token for MTNCL data with a stage of LINK 
	wire logic link_l_q, link_l_q_bar, link_r_q, link_r_q_bar;	
	wire logic link_full;	
	DFFRPQ u_link_l (.Q(link_l_q), .CK(clk_capture), .D(link_l_q_bar), .R(reset));         //LINK left registe:reset high-active, switch at clk_capture rising edge
	inv_a  u_inv_link_l (.a(link_l_q), .z(link_l_q_bar)); 
	DFFRPQ u_link_r (.Q(link_r_q), .CK(div[$clog2(div_width)]), .D(link_r_q_bar), .R(reset));  //LINK right register: reset high-active, switch at div[$clog2(width) falling edge
	inv_a  u_inv_link_r (.a(link_r_q), .z(link_r_q_bar)); 
	XOR2_A u_sleep (.A(link_l_q), .B(link_r_q), .Z(link_full));                            //LINK FULL output

///////////////////////////////////////////////////////////////////
// SYNC 
////////////////////////////////////////////////////////////////////
	//register link_full with main output clock
    DFFRPQ u_dff_vld (.Q(data_valid_int), .CK(clk), .D(link_full), .R(reset));         //reset high-active
	
	//output data_valid
    assign data_valid = data_valid_int;
	
	//register output data with main output clock 
	wire logic [width:0] data_q;
	assign data_q[width] = 1'b0;
    genvar k;
	generate
	  for (k=0; k< width; k++) begin
		SDFFRPQ u_dff_out (.Q(data_q[k]), .CK(clk), .D(data_captured[k]), .R(reset), .SE(data_valid_int), .SI(data_q[k+1]));     //if SE=1, Q=SI; if SE=0, Q=D.
	  end
	endgenerate
    assign data_out = data_q[0];
	
	
endmodule  //MTD3L_to_sync_p2s_bit_vector

