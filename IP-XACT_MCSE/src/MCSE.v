


module sentry #(
)(

    // ----- Device ID port ----------------------------------------------------

    // Device ID
    input  wire [`DEVICE_ID_SIZE_BITS-1             :0] I_did_hw_devid,
    input  wire                                         I_did_hw_valid,

    // ----- System requestor / controller port  -------------------------------

    // AHB requestor / controller port
    output wire                                         sys_ctrl_hclk_out,
    output wire [`SENTRY_SYS_CTRL_ADDR_SIZE_BITS-1   :0] sys_ctrl_haddr,
    output wire [`SENTRY_SYS_CTRL_HBURST_SIZE_BITS-1 :0] sys_ctrl_hburst,
    output wire                                         sys_ctrl_hmastlock,
    output wire [`SENTRY_SYS_CTRL_HPROT_SIZE_BITS-1  :0] sys_ctrl_hprot,
    output wire                                         sys_ctrl_hnonsec,
    output wire [`SENTRY_SYS_CTRL_HSIZE_SIZE_BITS-1  :0] sys_ctrl_hsize,
    output wire [`SENTRY_SYS_CTRL_HTRANS_SIZE_BITS-1 :0] sys_ctrl_htrans,
    output wire [`SENTRY_SYS_CTRL_DATA_SIZE_BITS-1   :0] sys_ctrl_hwdata,
    output wire                                         sys_ctrl_hwrite,
    input  wire [`SENTRY_SYS_CTRL_DATA_SIZE_BITS-1   :0] sys_ctrl_hrdata,
    input  wire                                         sys_ctrl_hready,
    input  wire                                         sys_ctrl_hresp,

    // ----- Security peripheral signals ---------------------------------------

    output wire                                         O_sysctl_secure_boot_done,

    // ----- Clock and reset ---------------------------------------------------

    // Clock and reset
    input  wire                                         clk_in,
    input  wire                                         rst_n
);

endmodule
