SRC_FILES := mcse_top.sv mcse_control_unit.sv secure_memory.sv secure_boot_control.sv lifecycle_protection.sv lc_memory.sv fw_auth.sv scan_protection.sv \
             min_security_module.sv sha_top.sv sha256_puf_256.v camellia_top.sv camellia.v \
             gpio.v gpio_regmap.v oh_dsync.v io.v packet2emesh.v c1908.v primitives.v \
             puf.v bus_translation.sv data_worker.sv error_correction.v mcse_top_tb.sv lec25dscc25.v

SRC_FILES_AHB := data_worker.sv data_worker_tb.sv

SRC_FILES_NETLIST := mcse_netlist.v mcse_top_netlist_tb.sv lec25dscc25.v

FLAGS := -sverilog -suppress -R +vcs+vcdpluson

TCL_SCRIPT = compiledc.tcl

MCSEtest: 
	vcs $(SRC_FILES) $(FLAGS) 

AHBtest: clean 
	vcs $(SRC_FILES_AHB) $(FLAGS)	

NETLISTtest: clean
	vcs  $(FLAGS) $(SRC_FILES_NETLIST) 
	
synthesis: clean 
	dc_shell -f compiledc.tcl

clean: 
	rm -rf simv.daidir/ $(WORK_DIR) WORK/

.PHONY: MCSEtest AHBtest NETLISTtest synthesis

.PHONY: clean
