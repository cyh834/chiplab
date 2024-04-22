#--------------------------------------------------------------------
# Sources
#--------------------------------------------------------------------

base_dir = $(abspath ../..)
soc = $(base_dir)/soc
sim_dir = .
gowin = $(base_dir)/fpga/gowin
IP = $(base_dir)/IP
TB = $(gowin)/testbench/testbench.v

# Verilog sources

bb_vsrcs = \
  $(shell find $(soc)/build -name "*.v") \
  $(shell find $(IP)/myCPU -name "*.v") \
	$(shell find $(gowin)/gowin_ip/ -name "*.v") \

sim_vsrcs = \
	$(TB) \
	$(shell find $(gowin)/gowin_sim_ip/ -name "*.v") \
  $(shell find $(soc)/perip -name "*.v" -or -name "*.sv") \
	$(bb_vsrcs)

sim_csrcs ?=

#--------------------------------------------------------------------
# Build Verilog
#--------------------------------------------------------------------

verilog:
	$(MAKE) -C $(base_dir) verilog

#--------------------------------------------------------------------
# Build rules
#--------------------------------------------------------------------

VCS = vcs -full64 -LDFLAGS -Wl,--no-as-needed

VCS_OPTS = -notice -line +lint=all,noVCDE,noONGS,noUI,noNS,noOUDPE -error=PCWM-L -timescale=1ns/1ns -quiet \
	+rad +v2k +vcs+lic+wait \
	+vc+list -CC "-I$(VCS_HOME)/include" \
	-sverilog +v2k \
	+incdir+$(soc)/perip/spi/rtl \
	+incdir+$(soc)/perip/uart16550/rtl \
	+incdir+$(IP)/myCPU/ \
	+define+CLOCK_PERIOD=2 $(sim_vsrcs) $(sim_csrcs) \
	+define+RANDOMIZE_MEM_INIT \
	+define+RANDOMIZE_GARBAGE_ASSIGN \
	+define+RANDOMIZE_INVALID_ASSIGN \
	+define+RANDOMIZE_DELAY=0.1 \
	+libext+.v \

#--------------------------------------------------------------------
# Build the simulator
#--------------------------------------------------------------------

simv = $(sim_dir)/simv_soc
$(simv) : $(sim_vsrcs) $(sim_csrcs)
	cd $(sim_dir) && \
	rm -rf csrc && \
	$(VCS) $(VCS_OPTS) -o $(simv) \
	-debug_acc+pp+f+fn+dmptf -debug_region+cell+encrypt
	./simv_soc

simv_debug = $(sim_dir)/simv_soc_debug
$(simv_debug) : $(sim_vsrcs) $(sim_csrcs)
	cd $(sim_dir) && \
	rm -rf csrc && \
	$(VCS) $(VCS_OPTS) -o $(simv_debug) \
	+define+DEBUG -debug_acc+pp+f+fn+dmptf -debug_region+cell+encrypt \

#--------------------------------------------------------------------
# Run
#--------------------------------------------------------------------

seed = $(shell date +%s)
exec_simv = $(simv) +permissive -q +ntb_random_seed_automatic +permissive-off
exec_simv_debug = $(simv_debug) +permissive -q +ntb_random_seed_automatic +permissive-off


run: verilog $(simv)
debug: $(simv_debug)

verdi:
	verdi $(sim_vsrcs) -ssf $(simv).fsdb &

clean:
	rm -rf $(output_dir) simv* csrc *.key DVE* *.h *.a *.daidir verdiLog *.conf *.rc *.log

.PHONY: run debug clean verilog
