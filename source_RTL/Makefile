SRC_FILES := mcse_top.sv mcse_control_unit.sv secure_memory.sv secure_boot_control.sv lifecycle_protection.sv lc_memory.sv \
             min_security_module.sv sha_top.sv sha256_puf_256.v camellia_top.sv camellia.v \
             gpio.v gpio_regmap.v oh_dsync.v io.v packet2emesh.v c1908.v primitives.v \
             puf.v bus_translation.sv data_worker.sv error_correction.v mcse_top_tb.sv lec25dscc25.v

SRC_FILES_AHB := data_worker.sv data_worker_tb.sv

SRC_FILES_NETLIST := mcse_netlist.v mcse_top_netlist_tb.sv lec25dscc25.v

SRC_FILES_SHA := sha_top.sv lec25dscc25.v sha256_puf_256.v sha_top_tb.sv

FLAGS := -sverilog -suppress -R +vcs+vcdpluson +vcs+lic+wait

TCL_SCRIPT = compiledc.tcl



MCSEtest: clean mcse_configuration
	vcs $(SRC_FILES) $(FLAGS) 

AHBtest: clean 
	vcs $(SRC_FILES_AHB) $(FLAGS)

NETLISTtest: clean mcse_configuration
	vcs  $(FLAGS) $(SRC_FILES_NETLIST) 
	
SHAtest : clean	
	vcs  $(FLAGS) $(SRC_FILES_SHA) 

synthesis: clean mcse_configuration
	dc_shell -f compiledc.tcl

.PHONY: MCSEtest AHBtest NETLISTtest synthesis 

mcse_configuration:
	python mcse_configuration.py 

.PHONY: clean
clean: 
	rm -rf simv.daidir/ $(WORK_DIR) WORK/

