`define GPIO_IDATA 6'h5
`define GPIO_ODATA 6'h0

`define SYS_BUS_WAKEUP 24'b1000000
`define RST_Request 24'b1
`define Operation_Release_to_Host 24'b10000
`define Fw_AUTH_SUCCESS_ACK_to_Host 24'b1000000000000000
`define Fw_AUTH_FAILURE_ACK_to_Host 24'b10000000000000000

`define IPID_START_BITS 16'h7A7A
`define IPID_STOP_BITS 16'hB9B9

`define CHIP_ID_ADDR 'h0
`define SECURE_COMMUNICATION_KEY_ADDR 'h2

`define LC_AUTHENTICATION_ID_ADDR_START 'h8 // end at 'hc

`define IPID_ADDR_MAP {32'h43C00000}

`define IPID_N 1
