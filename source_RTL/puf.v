module puf(testval, control, Q, DIN);
input testval, DIN, control;
output Q;

wire w1, w2;

mux mux2(
	.a(testval),
	.b(DIN),
	.sel(control),
	.out(Q));
	

endmodule


module mux(a, b, sel, out);
	input a, b, sel;
	output out;
	assign out = (sel == 0)? b: a;
endmodule



