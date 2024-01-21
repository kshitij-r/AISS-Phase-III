module	inv (A, Y);

   input A;
   output Y;
   
   not u1 (Y,A);
   
endmodule 

//AND

module	and2 (A, B, Y);

   input A, B;
   output Y;
   
   and u1 (Y,A,B);
   
endmodule 

module	and3 (A, B, C, Y);

   input A, B,C;
   output Y;
   
   and u1 (Y,A,B,C);
   
endmodule 

module	and4 (A,B,C,D, Y);

   input A,B,C,D;
   output Y;
   
   and u1 (Y,A,B,C,D);
   
endmodule 

module	and5 (A,B,C,D,E, Y);

   input A,B,C,D,E;
   output Y;
   
   and u1 (Y,A,B,C,D,E);
   
endmodule 

module	and8 (A,B,C,D,E,F,G,H, Y);

   input A,B,C,D,E,F,G,H;
   output Y;
   
   and u1 (Y,A,B,C,D,E,F,G,H);
   
endmodule 

//NAND

module	nand2 (A, B, Y);

   input A, B;
   output Y;
   
   nand u1 (Y,A,B);
   
endmodule 

module	nand3 (A, B, C, Y);

   input A, B,C;
   output Y;
   
   nand u1 (Y,A,B,C);
   
endmodule 

module	nand4 (A,B,C,D, Y);

   input A,B,C,D;
   output Y;
   
   nand u1 (Y,A,B,C,D);
   
endmodule 

module	nand5 (A,B,C,D,E, Y);

   input A,B,C,D,E;
   output Y;
   
   nand u1 (Y,A,B,C,D,E);
   
endmodule 

module	nand8 (A,B,C,D,E,F,G,H, Y);

   input A,B,C,D,E,F,G,H;
   output Y;
   
   nand u1 (Y,A,B,C,D,E,F,G,H);
   
endmodule 

//XOR

module	xor2 (A, B, Y);

   input A, B;
   output Y;
   
   xor u1 (Y,A,B);
   
endmodule 

module	xor3 (A, B, C, Y);

   input A, B,C;
   output Y;
   
   xor u1 (Y,A,B,C);
   
endmodule 

module	xor4 (A,B,C,D, Y);

   input A,B,C,D;
   output Y;
   
   xor u1 (Y,A,B,C,D);
   
endmodule 

module	xor5 (A,B,C,D,E, Y);

   input A,B,C,D,E;
   output Y;
   
   xor u1 (Y,A,B,C,D,E);
   
endmodule 

module	xor8 (A,B,C,D,E,F,G,H, Y);

   input A,B,C,D,E,F,G,H;
   output Y;
   
   xor u1 (Y,A,B,C,D,E,F,G,H);
   
endmodule 

//NOR

module	nor2 (A, B, Y);

   input A, B;
   output Y;
   
   nor u1 (Y,A,B);
   
endmodule 

//OR

module	or2 (A, B, Y);

   input A, B;
   output Y;
   
   or u1 (Y,A,B);
   
endmodule 

module	or8 (A,B,C,D,E,F,G,H, Y);

   input A,B,C,D,E,F,G,H;
   output Y;
   
   or u1 (Y,A,B,C,D,E,F,G,H);
   
endmodule 