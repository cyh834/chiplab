#--------------------------------------------------------------------
# Sources
#--------------------------------------------------------------------

base_dir = $(abspath ../..)
generated_dir = $(base_dir)/generated
sim_dir = .
gowin = $(base_dir)/fpga/gowin
IP = $(base_dir)/IP
TB = $(gowin)/testbench/testbench.v

# Verilog sources

bb_vsrcs = \
  $(shell find $(generated_dir) -name "*.v") \
  $(shell find $(IP)/myCPU -name "*.v") \
	$(shell find $(gowin)/gowin_ip/ -name "*.v") \

sim_vsrcs = \
	$(TB) \
	$(shell find $(gowin)/gowin_sim_ip/ -name "*.v") \
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

VCS_OPTS = -notice -line +lint=all,noVCDE,noONGS,noUI,noNS,noOUDPE -error=PCWM-L -timescale=1ns/10ps -quiet \
	+rad +v2k +vcs+lic+wait \
	+vc+list -CC "-I$(VCS_HOME)/include" \
	-sverilog +v2k \
	+incdir+$(generated_dir) \
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


run: $(simv)
debug: $(simv_debug)

verdi:
	verdi $(sim_vsrcs) -ssf $(simv).fsdb &

clean:
	rm -rf $(output_dir) simv* csrc *.key DVE* *.h *.a *.daidir verdiLog *.conf *.rc *.log

.PHONY: run debug clean verilog