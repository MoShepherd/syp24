# vhdl files
TOPLEVEL 	= top
FILES 		= ../rtl/bootloader/mux_4_1.vhd \
			  ../rtl/bootloader/UART_TX.vhd \
			  ../rtl/bootloader/UART_RX.vhd \
			  ../rtl/bootloader/tx_buffer.vhd \
			  ../rtl/bootloader/fifo_3.vhd \
			  ../rtl/bootloader/fifo_3_type.vhd \
			  ../rtl/bootloader/decoder.vhd \
			  ../rtl/bootloader/dpram.vhd \
			  ../rtl/bootloader/breakpoint_controller.vhd \
			  ../rtl/bootloader/single_step.vhd \
			  ../rtl/bootloader/runner.vhd \
			  ../rtl/bootloader/bootloader_top.vhd \
			  ../rtl/top.vhd \
			  ../rtl/svnr/alu_n.vhd \
			  ../rtl/svnr/aserial.vhd \
			  ../rtl/svnr/clkreset.vhd \
			  ../rtl/svnr/display_top.vhd \
			  ../rtl/svnr/increment_n.vhd \
			  ../rtl/svnr/mem_buffer.vhd \
			  ../rtl/svnr/mem_init_package.vhd \
			  ../rtl/svnr/mux_2_n.vhd \
			  ../rtl/svnr/mux_4_n.vhd \
			  ../rtl/svnr/ram_to_bit.vhd \
			  ../rtl/svnr/register_en.vhd \
			  ../rtl/svnr/slice_n.vhd \
			  ../rtl/svnr/steuerautomat_n.vhd \
			  ../rtl/svnr/svnr_mem.vhd \
			  ../rtl/svnr/svnr.vhd \
			  #../rtl/UART_feedback_fifo_fpga.vhd 
VHDLEX 		= .vhd

# Physical Constraint File
PCFFILE 	= svnr.pcf

#GHDL CONFIG
GHDL_CMD 	= ghdl
GHDL_FLAGS  = 

#YOSYS CONFIG
YOSYS_CMD 	= yosys -m ghdl 

#NEXTPNR CONFIG
NEXTPNR_CMD = nextpnr-ice40
PACKAGE 	= tq144:4k
NEXTPNR_OPT = --freq 12 --hx8k --package $(PACKAGE)
# NEXTPNR_OPT = --freq 50 --hx8k --package $(PACKAGE)

SYNDIR 		= synthesis
STOP_TIME 	= 10us
GHDL_SIM_OPT = --stop-time=$(STOP_TIME) --stop-delta=100000

.PHONY: clean

all: clean binary 

compile:
	@mkdir -p $(SYNDIR)
	@$(GHDL_CMD) -i $(GHDL_FLAGS) --workdir=$(SYNDIR) --work=work $(FILES)
	@$(GHDL_CMD) -m $(GHDL_FLAGS) --workdir=$(SYNDIR) --work=work $(TOPLEVEL)


synthesize: compile
	@$(YOSYS_CMD) -p 'ghdl --workdir='$(SYNDIR)' '$(TOPLEVEL)'; synth_ice40 -json '$(SYNDIR)/$(TOPLEVEL)'.json'  

placeandroute: synthesize
	$(NEXTPNR_CMD) $(NEXTPNR_OPT)  --pcf $(PCFFILE) --asc $(SYNDIR)/$(TOPLEVEL).asc --json $(SYNDIR)/$(TOPLEVEL).json

binary: placeandroute
	@icepack $(SYNDIR)/$(TOPLEVEL).asc $(SYNDIR)/$(TOPLEVEL).bin

program: $(SYNDIR)/$(TOPLEVEL).bin
	@iceprog $(SYNDIR)/$(TOPLEVEL).bin

clean:
	@rm -rf $(SYNDIR)
