# vhdl files
TESTBENCH=svnr_tb
FILES = ../rtl/*vhd
VHDLEX = .vhd

# testbench
TESTBENCHFILE = ${TESTBENCH}$(VHDLEX)


#GHDL CONFIG
GHDL_CMD = ghdl
GHDL_FLAGS  = 

SIMDIR = simulation
STOP_TIME = 10us
GHDL_SIM_OPT = --stop-time=$(STOP_TIME) --stop-delta=100000

WAVEFORM_VIEWER = gtkwave

.PHONY: clean

all: clean compile run view

compile:
	@mkdir -p $(SIMDIR)
	@$(GHDL_CMD) -i $(GHDL_FLAGS) --workdir=$(SIMDIR) --work=work ./$(TESTBENCHFILE) $(FILES)
	@$(GHDL_CMD) -m $(GHDL_FLAGS) --workdir=$(SIMDIR) --work=work -o $(SIMDIR)/$(TESTBENCH) $(TESTBENCH)


run:
	@cd $(SIMDIR) && $(GHDL_CMD) -r --workdir=./ --work=work $(TESTBENCH) --wave=$(TESTBENCH).ghw $(GHDL_SIM_OPT)

view:
	$(WAVEFORM_VIEWER) --dump=$(SIMDIR)/$(TESTBENCH).ghw --save ./$(TESTBENCH).gtkw 

clean:
	@rm -rf $(SIMDIR)
