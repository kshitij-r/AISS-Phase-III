module sha_top(
    input [511:0] block,
    input clk,
    input rst,
    input init,
    input next,
    input sel,
    output [255:0] digest,
    output ready,
    output digest_valid,
    output [255:0] pufout
);

 sha256 sha_instance(
    .clk(clk),
    .rst(rst),
    .block(block),
    .init(init),
    .next(next),
    .sel(sel),
    .digest(digest),
    .ready(ready),
    .digest_valid(digest_valid)
    // .pufout(pufout)
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
assign pufout = 'h442A472D4B6150645367566B59703273357638792F423F4528482B4D62516554; 

endmodule
