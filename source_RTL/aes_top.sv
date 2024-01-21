module aes_top(
    input [127:0] state,
    input [255:0] key,
    input clk,
    input rst,
    input start,
    input sel,
    output [127:0] out,
    output out_valid,
    output [255:0] pufout
);

aes_256 aes_instance(
    .clk(clk),
    .rst(rst),
    .state(state),
    .key(key),
    .start(start),
    .out(out),
    .out_valid(out_valid)
);

/* 256-bit PUF signature for simulation. 
     For FPGA, this assignment is removed and PUF signature value is taken from embedded PUF elements.
     Ex:   INVX1 puf_0_instance_0 ( .A(puf_0_wire_1), .Y(n1934));
           INVX1 puf_0_instance_1 ( .A(puf_0_wire_3), .Y(n1935));
      .............................................................
      This goes from puf_0 instance to puf_255 instance for 256-bit PUF signature
           INVX1 puf_255_instance_5 ( .A(puf_255_wire_7), .Y(puf_255_wire_3));
      This signal is only sent via puf_out when the PUF select (sel) is asserted to the module.
    */
assign pufout = 'h3F442A472D4B6150645367566B59703373367639792442264529482B4D625165; 

endmodule
