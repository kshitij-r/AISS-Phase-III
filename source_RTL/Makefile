SRC_FILES := mcse_top.sv mcse_control_unit.sv secure_memory.sv secure_boot_control.sv lifecycle_protection.sv lc_memory.sv \
             min_security_module.sv sha_top.sv sha256_puf_256.v camellia_top.sv camellia.v \
             gpio.v gpio_regmap.v oh_dsync.v io.v packet2emesh.v c1908.v primitives.v \
             puf.v mcse_top_tb.sv lec25dscc25.v

SRC_FILES_AHB := data_worker.v data_worker_tb.sv

SRC_FILES_NETLIST := mcse_netlist.v mcse_top_netlist_tb.sv lec25dscc25.v

FLAGS := -sverilog -R +vcs+vcdpluson

TCL_SCRIPT = compiledc.tcl

MCSEtest: clean
	vcs $(SRC_FILES) $(FLAGS)

AHBtest: clean 
	vcs $(SRC_FILES_AHB) $(FLAGS)

NETLISTtest: clean 
	vcs $(SRC_FILES_NETLIST) $(FLAGS)

synthesis: clean 
	dc_shell -f compiledc.tcl

.PHONY: MCSEtest AHBtest NETLISTtest synthesis 

.PHONY: clean
clean: 
	rm -rf simv.daidir/ $(WORK_DIR) WORK/

