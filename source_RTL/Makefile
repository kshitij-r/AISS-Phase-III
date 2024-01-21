SRC_FILES := fsm_top.sv fsm_driver.sv memory_controller.sv fifo_buffer.sv memory_module.v \
             min_security_module.sv sha_top.sv sha256_puf_256.v camellia_top.sv camellia.v \
             gpio.v gpio_regmap.v oh_dsync.v io.v packet2emesh.v pcm.sv c1908.v primitives.v \
             puf.v fsm_top_testing_tb.sv lec25dscc25.v

FLAGS := -sverilog -R +vcs+vcdpluson

MCSEtest:
	vcs $(SRC_FILES) $(FLAGS)

.PHONY: MCSEtest
