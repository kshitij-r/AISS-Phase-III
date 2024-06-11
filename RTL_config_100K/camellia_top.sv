

module camellia_top(
    input [127:0] data_in,
    input [255:0] key,
    input [0:1] k_len,
    input clk,
    input rst,
    input enc_dec,
    input data_rdy,
    input key_rdy,
    output [127:0] data_out,
    output data_acq,
    output key_acq,
    output output_rdy,
    output [255:0] pufout
);
 

camellia camellia_instance(
    .clk(clk),
    .reset(rst),
    .data_in(data_in),
    .key(key),
    .k_len(k_len),
    .enc_dec(enc_dec),
    .data_rdy(data_rdy),
    .key_rdy(key_rdy),
    .data_out(data_out),
    .data_acq(data_acq),
    .key_acq(key_acq),
    .output_rdy(output_rdy)
    
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