#set search_path "/WORK"

# Suppress warnings about undeclared wires
#set suppress_errors {VER-936}

## Setting up target libraries
set_app_var target_library {
    lec25dscc25.db
}
define_design_lib WORK -path ./WORK
## Setting up link libraries
set_app_var link_library $target_library

set my_files [list sha256_puf_256.v primitives.v packet2emesh.v min_security_module.sv gpio_regmap.v camellia_top.sv sha_top.sv puf.v pcm.v oh_dsync.v io.v gpio.v camellia.v c1908.v secure_memory.sv mcse_top.sv mcse_control_unit.sv lifecycle_protection.sv lc_memory.sv secure_boot_control.sv data_worker.sv bus_translation.sv error_correction.v fw_auth.sv scan_protection.sv polymorphic_top_w_wrapper.v apc_wrapper.sv]

analyze -f sverilog $my_files 

set my_toplevel mcse_top 

elaborate $my_toplevel

set_max_area 0


ungroup -all -flatten -force
compile_ultra

report_area
report_power
report_hierarchy
report_reference

write -format verilog -hierarchy -output mcse_netlist.v mcse_top

quit