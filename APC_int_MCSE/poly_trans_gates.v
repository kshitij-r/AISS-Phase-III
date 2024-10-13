
`ifndef POLY_TRANS_GATE
`define POLY_TRANS_GATE
`define POLY_TRANS_DP  			#0.001

///////////////////////////////////////
//th12m_th22m
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module th12m_th22m (vdd_sel, a, b, s, z);
output z;
input vdd_sel, a, b, s;
reg z;
always @ (vdd_sel or a or b or s) begin
	// th12m (high)
	if (vdd_sel == 1) begin
		if (s == 1)
			z <= 0;
		else if ((a == 1) | (b == 1))
			z <= 1;
		else
			z <= 0;
	end
	// th22m (low)
	else if (vdd_sel == 0) begin
		if (s == 1)
			z <= 0;
		else if ((a == 1) & (b == 1))
			z <= 1;
		else
			z <= 0;
	end
end
endmodule // th12m_th22m
`endcelldefine

/////////////////////////////////////
//th33w2m_th33m
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module th33w2m_th33m (vdd_sel, a, b, c, s, z);
output z;
input vdd_sel, a, b, c, s;
reg z;
always @ (vdd_sel or a or b or c or s) begin
	// th33w2m (high)
	if (vdd_sel == 1) begin
		if (s == 1)
			z <= 0;
		else if ( ((a == 1) & (b == 1)) | ((a == 1) & (c == 1)) )
			z <= 1;
		else
			z <= 0;
	end
	// th33m (low)
	else if (vdd_sel == 0) begin
		if (s == 1)
			z <= 0;
		else if ((a == 1) & (b == 1) & (c == 1))
			z <= 1;
		else 
			z <= 0;
	end
end
endmodule // th33w2m_th33m
`endcelldefine

/////////////////////////////////////
//th24w22m_th24w2m
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module th24w22m_th24w2m (vdd_sel, a, b, c, d, s, z);
output z;
input vdd_sel, a, b, c, d, s;
reg z;
always @ (vdd_sel or a or b or c or d or s) begin
	// th24w22m (high)
	if (vdd_sel == 1) begin
		if (s == 1)
			z <= 0;
		else if ( (a == 1) | (b == 1) | ((c == 1) & (d == 1)) )
			z <= 1;
		else
			z <= 0;
	end
	// th24w2m (low)
	else if (vdd_sel == 0) begin
		if (s == 1)
			z <= 0;
		else if ( (a == 1) | ((b == 1) & (c == 1)) | ((b == 1) & (d == 1)) | ((c == 1) & (d == 1)) )
			z <= 1;
		else 
			z <= 0;
	end
end
endmodule // th24w22m_th24w2m
`endcelldefine

/////////////////////////////////////
//th54w322m_th44w22m
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module th54w322m_th44w22m (vdd_sel, a, b, c, d, s, z);
output z;
input vdd_sel, a, b, c, d, s;
reg z;
always @ (vdd_sel or a or b or c or d or s) begin
	// th54w322m (high)
	if (vdd_sel == 1) begin
		if (s == 1)
			z <= 0;
		else if ( ((a == 1) & (b == 1)) | ((a == 1) & (c == 1)) | ((b == 1) & (c == 1) & (d == 1)) )
			z <= 1;
		else
			z <= 0;
	end
	// th44w22m (low)
	else if (vdd_sel == 0) begin
		if (s == 1)
			z <= 0;
		else if ( ((a == 1) & (b == 1)) | ((a == 1) & (c == 1) & (d == 1)) | ((b == 1) & (c == 1) & (d == 1)) )
			z <= 1;
		else 
			z <= 0;
	end
end
endmodule // th54w322m_th44w22m
`endcelldefine

/////////////////////////////////////
//thxor0mtd3l_th54w32mtd3l
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module thxor0mtd3l_th54w32mtd3l (vdd_sel, a, b, c, d, s0, ns1, z);
output z;
input vdd_sel, a, b, c, d, s0, ns1;
reg z;
always @ (vdd_sel or a or b or c or d or s0 or ns1) begin
	// thxor0mtd3l (high)
	if (vdd_sel == 1) begin
		if (s0 == 1)
			z <= 0;
		else if (ns1 == 0)
			z <= 1;
		else if ( ((a == 1) & (b == 1)) | ((c == 1) & (d == 1)) )
			z <= 1;
		else
			z <= 0;
	end
	// th54w32mtd3l (low)
	else if (vdd_sel == 0) begin
		if (s0 == 1)
			z <= 0;
		else if (ns1 == 0)
			z <= 1;
		else if ( ((a == 1) & (b == 1)) | ((a == 1) & (c == 1) & (d == 1)) )
			z <= 1;
		else 
			z <= 0;
	end
end
endmodule // thxor0mtd3l_th54w32mtd3l
`endcelldefine

/////////////////////////////////////
//transmission_gate
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module transmission_gate (control, a, z);
output z;
input control, a;
reg z;
always @ (control or a) begin
	if (control == 1)
		#5 z <= a;
	else if (control == 0)
		#3 z <= 1'bz;
end
endmodule // transmission_gate
`endcelldefine

/////////////////////////////////////
//buffermtd3l_a
////////////////////////////////////
`timescale 1ns/1ps
`celldefine
module buffermtd3l_a (a, s0, ns1, z);
output z;
input a, s0, ns1;
th12mtd3l_a temp_buffer(.a(a), .b(1'b0), .s0(s0), .ns1(ns1), .z(z));
endmodule // buffermtd3l_a
`endcelldefine

`endif