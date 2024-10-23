
`ifndef VERILOG_GATE
`define VERILOG_GATE

///////////////////////////////////////
//th22n_a
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module th22n_a (a, b, rst, z);
output z;
input a, b, rst;
reg z;
always @ (a or b or rst) begin
	if (rst == 1)
		#0.01 z <= 0;
	else if ((a == 1) & (b == 1)) 
		#0.01 z <= 1;
	else if ((a == 0) & (b == 0)) 
		 #0.01 z <= 0;
end
endmodule // th22n_a
`endcelldefine

///////////////////////////////////////
//th22d_a
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module th22d_a (a, b, rst, z);
output z;
input a, b, rst;
reg z;
always @ (a or b or rst) begin
	if (rst == 1)
		#0.01 z <= 1;
	else if ((a == 1) & (b == 1)) 
		#0.01 z <= 1;
	else if ((a == 0) & (b == 0)) 
		#0.01 z <= 0;
end
endmodule // th22d_a
`endcelldefine

`endif