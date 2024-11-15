# vhdl files
TOPLEVEL 	= svnr
FILES 		= ../rtl/alu_n.vhd \
			../rtl/aserial.vhd \
			../rtl/clkreset.vhd \
			../rtl/display_top.vhd \
			../rtl/increment_n.vhd \
			../rtl/mem_init_package.vhd \
			../rtl/mux_2_n.vhd \
			../rtl/mux_4_n.vhd \
			../rtl/ram_to_bit.vhd \
			../rtl/register_en.vhd \
			../rtl/slice_n.vhd \
			../rtl/steuerautomat_n.vhd \
			../rtl/svnr_mem.vhd \
			../rtl/svnr.vhd 
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
NEXTPNR_OPT = --freq 50 --hx8k --package $(PACKAGE)

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
