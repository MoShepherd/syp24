# vhdl files
TESTBENCH 	= bootloader_runner_top_tb
FILES 		= ../../rtl/bootloader/mux_4_1.vhd \
			  ../../rtl/bootloader/UART_TX.vhd \
			  ../../rtl/bootloader/UART_RX.vhd \
			  ../../rtl/bootloader/tx_buffer.vhd \
			  ../../rtl/bootloader/fifo_3.vhd \
			  ../../rtl/bootloader/fifo_3_type.vhd \
			  ../../rtl/bootloader/decoder.vhd \
			  ../../rtl/bootloader/dpram.vhd \
			  ../../rtl/bootloader/breakpoint_controller.vhd \
			  ../../rtl/bootloader/single_step.vhd \
			  ../../rtl/bootloader/runner.vhd \
			  ../../rtl/bootloader/bootloader_top.vhd \
			  ../../rtl/top.vhd \
			  ../../rtl/svnr/alu_n.vhd \
			  ../../rtl/svnr/aserial.vhd \
			  ../../rtl/svnr/clkreset.vhd \
			  ../../rtl/svnr/display_top.vhd \
			  ../../rtl/svnr/increment_n.vhd \
			  ../../rtl/svnr/mem_buffer.vhd \
			  ../../rtl/svnr/mem_init_package.vhd \
			  ../../rtl/svnr/mux_2_n.vhd \
			  ../../rtl/svnr/mux_4_n.vhd \
			  ../../rtl/svnr/ram_to_bit.vhd \
			  ../../rtl/svnr/register_en.vhd \
			  ../../rtl/svnr/slice_n.vhd \
			  ../../rtl/svnr/steuerautomat_n.vhd \
			  ../../rtl/svnr/svnr_mem.vhd \
			  ../../rtl/svnr/svnr.vhd \
			  #../rtl/UART_feedback_fifo_fpga.vhd 
VHDLEX 		= .vhd

# testbench
TESTBENCHFILE = ${TESTBENCH}$(VHDLEX)


#GHDL CONFIG
GHDL_CMD = ghdl
GHDL_FLAGS  = 

SIMDIR = simulation
STOP_TIME = 275ms #268 um an die 1023 stellen zu kommen
GHDL_SIM_OPT = --stop-time=$(STOP_TIME) --stop-delta=100000 --ieee-asserts=disable

WAVEFORM_VIEWER = gtkwave

.PHONY: clean

all: clean compile run view

compile:
	mkdir -p $(SIMDIR)
	$(GHDL_CMD) -i $(GHDL_FLAGS) --workdir=$(SIMDIR) --work=work ./$(TESTBENCHFILE) $(FILES)
	$(GHDL_CMD) -m $(GHDL_FLAGS) -o $(SIMDIR)/$(TESTBENCH) --workdir=$(SIMDIR) --work=work $(TESTBENCH)

run:
	cd $(SIMDIR) && $(GHDL_CMD) -r --workdir=./ --work=work $(TESTBENCH) --wave=$(TESTBENCH).ghw $(GHDL_SIM_OPT)

view:
	$(WAVEFORM_VIEWER) --dump=$(SIMDIR)/$(TESTBENCH).ghw --save $(TESTBENCH).gtkw
	
clean:
	rm -rf $(SIMDIR)
