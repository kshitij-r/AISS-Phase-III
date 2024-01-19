module jtag_interface#(
    parameter concatenated_input_data_width = 8,
    parameter concatenated_output_data_width = 8,
    parameter tap_width = 8,
    parameter tap_id = 0,
    parameter tap_version = 0,
    parameter tap_part = 0,
    parameter tap_man_num = 0,
    parameter tap_sync_mode = 0,
    parameter tap_tst_mode = 1,
	parameter instruction_width = 8 // change as needed

)(

    // Clock and reset signals
   //input clk,
   /// input rst_n,

    // JTAG interface signals
    input tck,
    input trst_n,
    input tms,
    input tdi,
    input mode,
    output tdo,
    output tdo_en,
    input bypass_sel,
    input [tap_width-2 : 0] sentinel_val,

    // Normal IP signals
    input [concatenated_input_data_width-1 : 0] input_data, IP_output_data,
    output [concatenated_output_data_width-1 : 0] output_data, IP_input_data

);


// TAP signals

// input inst_tck;
// input inst_trst_n;
// input inst_tms;
// input inst_tdi;
// input inst_so;
;

wire clock_dr_inst;
wire shift_dr_inst;
wire update_dr_inst;
// output tdo_inst;

wire [15 : 0] tap_state_inst;
wire extest_inst;
wire samp_load_inst;
wire [instruction_width-1 : 0] instructions_inst;
wire sync_capture_en_inst;
wire sync_update_dr_inst;
wire inst_test;

wire [concatenated_input_data_width+concatenated_output_data_width-1 : 0] concat_data;
wire [concatenated_input_data_width+concatenated_output_data_width-1 : 0] bc_sio;
wire tap_so;
assign tap_so = samp_load_inst == 1'b1 ? bc_sio[concatenated_input_data_width+concatenated_output_data_width-1] : 1'b0;

    // Instance of DW_tap
    DW_tap #(tap_width,
             tap_id,
             tap_version,
             tap_part,
             tap_man_num,
             tap_sync_mode)
	     //    tap_tst_mode)
	  tap_inst (  .tck(tck),
                .trst_n(trst_n),
                .tms(tms),
                .tdi(tdi),
                .so(tap_so),
                .bypass_sel(bypass_sel),
                .sentinel_val(sentinel_val),
                .clock_dr(clock_dr_inst),
                .shift_dr(shift_dr_inst),
                .update_dr(update_dr_inst),
                .tdo(tdo),
                .tdo_en(tdo_en),
                .tap_state(tap_state_inst),
                .extest(extest_inst),
                .samp_load(samp_load_inst),
                .instructions(instructions_inst),
                .sync_capture_en(sync_capture_en_inst),
                .sync_update_dr(sync_update_dr_inst),
                .test(inst_test) );


    // Boundary scan signals

//     input inst_capture_clk;
//   input inst_update_clk;
//   input inst_capture_en;
//   input inst_update_en;
//   input inst_shift_dr;
//   input inst_mode;
//   input inst_si;
//   input inst_data_in;
//   output data_out_inst;
//   output so_inst;

  // Instance of DW_bc_1
  


    genvar i;


    assign concat_data = {input_data, IP_output_data};

    for(i=0; i<concatenated_input_data_width+concatenated_output_data_width; i=i+1) begin : bc_genvar
        wire si;
        wire bc_data_in, bc_data_out;
        if(i == 0) begin
            assign si = tdi;
        end else begin
            assign si = bc_sio[i-1];
        end

        if(i < concatenated_input_data_width) begin
            assign bc_data_in = concat_data[i];
            assign IP_input_data[i] = bc_data_out;
        end else begin
            assign bc_data_in = IP_output_data[i-concatenated_input_data_width];
            assign output_data[i-concatenated_input_data_width] = bc_data_out; 
        end

        DW_bc_1 bc_inst (.capture_clk(clock_dr_inst),   .update_clk(update_dr_inst),
        .capture_en(1'b0),   .update_en(1'b1),
        .shift_dr(shift_dr_inst),   .mode(mode),   .si(si),
        .data_in(bc_data_in),   .data_out(bc_data_out),   .so(bc_sio[i]) );      
    end


endmodule

