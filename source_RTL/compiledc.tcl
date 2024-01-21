#define_design_lib WORK -path ./WORK
#set search_path "src/"

# Suppress warnings about undeclared wires
set suppress_errors {VER-936}

## Setting up target libraries
set_app_var target_library {
    lec25dscc25.db
    dft_jtag.sldb
    dw_foundation.sldb
}

## Setting up link libraries
set_app_var link_library $target_library

set filelist "
jtag_interface.sv
DW_tap.v
DW_bc_1.v
"

set synthetic_library [list dw_foundation.sldb]

analyze -f sverilog $filelist

elaborate jtag_interface

read_sdc sdc_name.sdc
check_design
check_timing

set_max_area 0
compile -ungroup_all -area_effort high -map_effort high

write -f verilog -o ../outputs/demo_synth_netlist.v
write_sdc ../outputs/demo_synth_netlist.sdc
write -f ddc -o ../outputs/demo_synth.ddc
report_area > ../outputs/demo_synth_area.rpt
report_timing > ../outputs/demo_synth_timing.rpt
report_power > ../outputs/demo_synth_power.rpt
report_qor > ../outputs/demo_synth_qor.rpt
report_cell > ../outputs/demo_synth_cells.rpt
report_disable_timing > ../outputs/demo_synth_disabled_timing_arcs.rpt

quit
