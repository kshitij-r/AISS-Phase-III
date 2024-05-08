//-----------------------------------------------------------------------
//
// Copyright (C) 2002-2023, all rights reserved
// Synopsys Inc.
//
// As part of our confidentiality  agreement, Synopsys and
// the Company, as  a  Receiving Party, of  this  information  agrees to
// keep strictly  confidential  all Proprietary Information  so received
// from Synopsys. Such Proprietary Information can be used
// solely for  the  purpose  of evaluating  and/or conducting a proposed
// business  relationship  or  transaction  between  the  parties.  Each
// Party  agrees  that  any  and  all  Proprietary  Information  is  and
// shall remain confidential and the property of Synopsys.
// The  Company  may  not  use  any of  the  Proprietary  Information of
// Synopsys for any purpose other  than  the  above-stated
// purpose  without the prior written consent of Synopsys.
//
//-----------------------------------------------------------------------
//
// Project: DARPA AISS - Automatic Integration of Secure Silicon
//
//-----------------------------------------------------------------------

// `timescale 1ns/1ns
`default_nettype none



`define         AHB_TRANS_IDLE                      2'b00
`define         AHB_DATA_WIDTH_BITS                 32

// Added ELP Macros 
`define			ELP_AHB_TRANS_IDLE 					2'b00
`define 		ELP_AHB_TRANS_BUSY 					2'b01
`define 		ELP_AHB_TRANS_NONSEQ				2'b10
`define 		ELP_AHB_TRANS_SEQ 					2'b11
`define 		ELP_AHB_READ						1'b0
`define 		ELP_AHB_WRITE						1'b1

module data_worker
#(
    parameter   pAHB_ADDR_WIDTH                     = 32,
                pAHB_DATA_WIDTH                     = `AHB_DATA_WIDTH_BITS,
                pAHB_BURST_WIDTH                    = 3,
                pAHB_PROT_WIDTH                     = 4,
                pAHB_SIZE_WIDTH                     = 3,
                pAHB_TRANS_WIDTH                    = 2,
                pAHB_HRESP_WIDTH                    = 2,

                pAHB_HPROT_VALUE                    = (     1 << 0  // [0] : 1 = data access        ( 0 = op code access            )
                                                        |   1 << 1  // [1] : 1 = privileged access  ( 0 = user access               )
                                                        |   0 << 2  // [2] : 0 = not bufferable     ( 1 = bufferable                )
                                                        |   0 << 3), // [3] : 0 = not cacheable      ( 1 = cacheable                 )
                pAHB_HSIZE_VALUE                    =       (`AHB_DATA_WIDTH_BITS == 32 ) ? 3'b010  // (010 = 32-bit    )
                                                        :   (`AHB_DATA_WIDTH_BITS == 64 ) ? 3'b011  // (011 = 64-bit    )
                                                        :   (`AHB_DATA_WIDTH_BITS == 128) ? 3'b110  // (110 = 128-bit   )
                                                        :   3'b010, // Default to 32-bit
                pAHB_HBURST_VALUE                   = 3'b011,       // 011 = 4 beat incrementing    ( 111 = 16 beat incrementing    )
                pAHB_HMASTLOCK_VALUE                = 1'b1,         // 1 = locked transfer          ( 0 = unlocked transfer         )
                pAHB_HNONSEC_VALUE                  = 1'b0,         // 0 = Secure transfer          ( 1 = non secure transfer       )

    parameter   pPAYLOAD_SIZE_BITS                  = 128,
                pMAX_TRANSFER_WAIT_COUNT            = 16,
                pREVERSE_WORD_ORDER                 = 1,
                pREVERSE_BYTE_ORDER                 = 0
)
(
    // ------------------------------------------------------------------

    // System side AHB requester port
    output  logic   [pAHB_ADDR_WIDTH-1        :0]   O_haddr,
    output  logic   [pAHB_BURST_WIDTH-1       :0]   O_hburst,
    output  logic                                   O_hmastlock,
    output  logic   [pAHB_PROT_WIDTH-1        :0]   O_hprot,
    output  logic                                   O_hnonsec,
    output  logic   [pAHB_SIZE_WIDTH-1        :0]   O_hsize,
    output  logic   [pAHB_TRANS_WIDTH-1       :0]   O_htrans,
    output  logic   [pAHB_DATA_WIDTH-1        :0]   O_hwdata,
    output  logic                                   O_hwrite,
    input   wire    [pAHB_DATA_WIDTH-1        :0]   I_hrdata,
    input   wire                                    I_hready,
    input   wire    [pAHB_HRESP_WIDTH-1       :0]   I_hresp,
    input   wire                                    I_hreadyout,

    // ------------------------------------------------------------------

    // Internal data port
    input   wire    [pAHB_ADDR_WIDTH-1          :0] I_int_addr,             // Target address for write operations
    input   wire    [pPAYLOAD_SIZE_BITS-1       :0] I_int_wdata,            // Outbound data for write operations
    output  logic   [pPAYLOAD_SIZE_BITS-1       :0] O_int_rdata,            // Inbound data for read operations

    input   wire                                    I_int_write,            // 0 = Read, 1 = Write
    output  logic                                   O_int_rdata_valid,      // High if rdata is valid, low otherwise
//    output  reg                                     O_int_ready,            // Ready to accept new transaction

    // ------------------------------------------------------------------

    // Job control signals
    input   wire                                    I_go,                   // Assert high until transfer is done (O_done == 1)
    output  logic                                   O_done,                 // Pulse high, when transfer is done.

    // System Pins
    input   wire                                    clk,
    input   wire /* asynchronous, active low */     rst_n

);



typedef enum logic [4:0] {

    ahb_state_idle                              = 5'b00000,                 // AHB bus idle
    ahb_state_busy                              = 5'b00001,                 // AHB bus busy
    ahb_state_read_nonseq                       = 5'b00010,                 // AHB bus non sequential read transfer
    ahb_state_read_seq                          = 5'b00011,                 // AHB bus sequential read transfer
    ahb_state_write_seq                         = 5'b00100,                 // AHB bus sequential write transfer
    ahb_state_done                              = 5'b00101                  // AHB bus transfer done

} ahb_state_e;



localparam pBeatsPerPayload                         = pPAYLOAD_SIZE_BITS / pAHB_DATA_WIDTH;
localparam pBeatsPerPayloadMinusOne                 = pBeatsPerPayload - 1;
localparam pMaxWaitCount                            = pMAX_TRANSFER_WAIT_COUNT;
localparam pAddressIncrement                        = pAHB_DATA_WIDTH >> 3;



// Datapath
logic   [pAHB_ADDR_WIDTH-1          :0]             r_read_addr;
logic   [pAHB_ADDR_WIDTH-1          :0]             r_write_addr;
logic   [pPAYLOAD_SIZE_BITS-1       :0]             r_read_data;
logic   [pPAYLOAD_SIZE_BITS-1       :0]             r_write_data;
logic                                               r_read_data_valid;

assign  O_int_rdata                                 = r_read_data;
assign  O_int_rdata_valid                           = r_read_data_valid;

// Transfer variables
logic   [15:0]                                      r_beat_counter;
logic   [15:0]                                      r_wait_counter;

// State variables
ahb_state_e                                         r_state;
ahb_state_e                                         r_state_next;






// ----- State machine -----------------------------------------------------------------------------
always_ff @ ( posedge clk or negedge rst_n ) begin : data_worker_fsm

    if ( !rst_n ) begin

        // Clear state variables
        r_state                             = ahb_state_idle;
        r_state_next                        = ahb_state_idle;

        // Clear internal datapath registers
        r_beat_counter                      = 'b0;
        r_wait_counter                      = 'b0;
        r_read_addr                         = 'b0;
        r_read_data                         = 'b0;
        r_read_data_valid                   = 'b0;
        r_write_data                        = 'b0;
        r_write_data                        = 'b0;

        // Clear internal data port
        O_done                              = 'b0;

        // Clear AHB port
        O_haddr                             = 'b0;
        O_hburst                            = pAHB_HBURST_VALUE;
        O_hmastlock                         = pAHB_HMASTLOCK_VALUE;
        O_hprot                             = pAHB_HPROT_VALUE;
        O_hnonsec                           = pAHB_HNONSEC_VALUE;
        O_hsize                             = pAHB_HSIZE_VALUE;
        O_htrans                            = `ELP_AHB_TRANS_IDLE;
        O_hwdata                            = 'b0;
        O_hwrite                            = 'b0;

    end
    else begin

    // ----- Change state ------------------------------------------------------

    r_state                                 = r_state_next;

    // ----- Default in all states ---------------------------------------------

    O_hburst                                = pAHB_HBURST_VALUE;
    O_hmastlock                             = pAHB_HMASTLOCK_VALUE;
    O_hprot                                 = pAHB_HPROT_VALUE;
    O_hnonsec                               = pAHB_HNONSEC_VALUE;
    O_hsize                                 = pAHB_HSIZE_VALUE;

    // ----- Current state action ----------------------------------------------

    case (r_state)

        ahb_state_idle:begin

            // Clear done signal whether it was asserted or not
            O_done                          = 0;

            // Set bus to idle by default
            O_htrans                        = `ELP_AHB_TRANS_IDLE;

            // ----- New transfer - setup common parameters --------------------

            if ( I_go ) begin
                // Setup transfer
                r_beat_counter              = 0;
                r_wait_counter              = 0;

                // Change transaction type to non-sequential
//                O_htrans                    = `ELP_AHB_TRANS_NONSEQ;

                // ----- New read operation ----------------------------------------

                if ( !I_int_write ) begin

                    // Sample input wires
                    r_read_addr             = I_int_addr;

                    // Setup transfer
                    O_haddr                 = r_read_addr;
                    O_hwrite                = `ELP_AHB_READ;

                    // Clear data valid signal
                    r_read_data_valid       = 0;

                    // Next state
                    r_state_next            = ahb_state_read_nonseq;

//                    $display( "data_worker : rd @ 0x%h", r_read_addr );
                end

                // ----- New write operation ---------------------------------------

                else if ( I_int_write ) begin

                    // Sample input wires
                    r_write_addr            = I_int_addr;
                    r_write_data            = I_int_wdata;

                    // Setup transfer
                    O_haddr                 = r_write_addr;
                    O_hwrite                = `ELP_AHB_WRITE;

                    // Next state
                    r_state_next            = ahb_state_write_seq;

//                    $display( "data_worker : wr = 0x%h", r_write_data );
                end
            end
            // Idle state - go signal is not asserted, make sure outputs are clear, ports are disabled
            else begin

                // Remain in idle
                r_state_next                = ahb_state_idle;
            end
        end

        // ----- Read wait cycle -----------------------------------------------

        ahb_state_read_nonseq:begin

            // Give the subordinate one cycle to set up the requested data. Move to next state
            r_state_next                    = ahb_state_read_seq;

            // Change transaction type to non-sequential
            O_htrans                        = `ELP_AHB_TRANS_NONSEQ;

            // Increase address by number of bytes in a data word
//            O_haddr                         = O_haddr + pAddressIncrement;

        end

        // ----- Read data -----------------------------------------------------

        ahb_state_read_seq:begin

            // Change transaction type to sequential
            O_htrans                        = `ELP_AHB_TRANS_SEQ;

            if ( !I_hreadyout ) begin
                // Wait state, remain in this state
                r_state_next                = ahb_state_read_seq;

                // Check and increase wait counter
                if ( r_wait_counter > pMaxWaitCount ) begin
                    r_state_next            = ahb_state_done;
                    O_done                  = 1;

                    $display( "data_worker : rd timeout @ 0x%h", r_read_addr );
                end
                else begin
                    r_wait_counter          = r_wait_counter + 1;
                end

            end
            else begin

                // Sample input data from AHB port
                if ( pREVERSE_WORD_ORDER ) begin
                    if ( pREVERSE_BYTE_ORDER )  r_read_data[ (pAHB_DATA_WIDTH * (pBeatsPerPayload - r_beat_counter) - 1) -: pAHB_DATA_WIDTH ] = { I_hrdata[0+:8], I_hrdata[8+:8], I_hrdata[16+:8], I_hrdata[24+:8] };
                    else                        r_read_data[ (pAHB_DATA_WIDTH * (pBeatsPerPayload - r_beat_counter) - 1) -: pAHB_DATA_WIDTH ] = I_hrdata;
                end
                else begin
                    if ( pREVERSE_BYTE_ORDER )  r_read_data[ (pAHB_DATA_WIDTH * r_beat_counter) +: pAHB_DATA_WIDTH ] = { I_hrdata[0+:8], I_hrdata[8+:8], I_hrdata[16+:8], I_hrdata[24+:8] };
                    else                        r_read_data[ (pAHB_DATA_WIDTH * r_beat_counter) +: pAHB_DATA_WIDTH ] = I_hrdata;
                end

                r_beat_counter              = r_beat_counter + 1;

                // If one beat remaining
//                if ( r_beat_counter == pBeatsPerPayloadMinusOne ) begin
                if ( r_beat_counter == pBeatsPerPayload ) begin
                    // Set bus to idle
                    O_htrans                = `ELP_AHB_TRANS_IDLE;

                    // Increase address by number of bytes in a data word
                    O_haddr                 = O_haddr + pAddressIncrement;
                end
                // If more than one beat remaining
                else if ( r_beat_counter < pBeatsPerPayload ) begin

                    // Increase address by number of bytes in a data word
                    O_haddr                 = O_haddr + pAddressIncrement;

                    // Remain in this state
                    r_state_next            = ahb_state_read_seq;
                end
                else begin
                    // Set bus to idle
                    O_htrans                = `ELP_AHB_TRANS_IDLE;
                    r_state_next            = ahb_state_done;
                    O_done                  = 1;

                    // Assert data valid signal
                    r_read_data_valid       = 1;
//                    $display( "data_worker : rd = 0x%h", r_read_data );
                end
            end
        end

        // ----- Write data -----------------------------------------------------

        ahb_state_write_seq:begin

            if ( !I_hreadyout ) begin
                // Wait state, remain in this state
                r_state_next                = ahb_state_write_seq;

                // Check and increase wait counter
                if ( r_wait_counter > pMaxWaitCount ) begin
                    // Set bus to idle
                    O_htrans                = `ELP_AHB_TRANS_IDLE;
                    r_state_next            = ahb_state_done;
                    O_done                  = 1;
                    $display( "data_worker : wr timeout @ 0x%h", r_write_addr );
                end
                else begin
                    r_wait_counter          = r_wait_counter + 1;
                end

            end
            else begin

                // Increase wait counter
                r_wait_counter              = 0;

                // Produce data word to AHB port
                if ( pREVERSE_WORD_ORDER ) begin
                    O_hwdata                = r_write_data[ (pAHB_DATA_WIDTH * (pBeatsPerPayload - r_beat_counter) - 1) -: pAHB_DATA_WIDTH ];
//                    $display( "data_worker : [%3d-:%2d] = 0x%h", (pAHB_DATA_WIDTH * (pBeatsPerPayload - r_beat_counter) - 1), pAHB_DATA_WIDTH, O_hwdata );
                end
                else begin
                    O_hwdata                = r_write_data[ (pAHB_DATA_WIDTH * r_beat_counter) +: pAHB_DATA_WIDTH ];
                end

                r_beat_counter              = r_beat_counter + 1;

                // If more data in transfer
                if ( r_beat_counter < pBeatsPerPayload ) begin

                    // Increase address by number of bytes in a data word
                    O_haddr                 = O_haddr + pAddressIncrement;

                    // Remain in this state
                    r_state_next            = ahb_state_write_seq;
                end
                else begin
                    // Set bus to idle
                    O_htrans                = `ELP_AHB_TRANS_IDLE;
                    r_state_next            = ahb_state_done;
                    O_done                  = 1;

//                    $display( "data_worker : wr @ 0x%h", r_write_addr );
                end
            end
        end

        // ----- Done ----------------------------------------------------------

        ahb_state_done:begin

            // Set bus to idle
            O_htrans                        = `ELP_AHB_TRANS_IDLE;

            // Go to idle state
            r_state_next                    = ahb_state_idle;

            // Keep done signal high
            O_done                          = 1;
//            $display( "data_worker : done" );
        end

        // ----- Default -------------------------------------------------------

        default:begin
            // Unknown state
            r_state_next                    = ahb_state_idle;
        end
    endcase
    end // not !rst_n

end // data_worker_fsm






endmodule

`default_nettype wire