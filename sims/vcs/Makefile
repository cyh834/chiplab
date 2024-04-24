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
  $(shell find $(IP)/open-la500 -name "*.v") \
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
# Build Software
#--------------------------------------------------------------------

#生成mi文件，需要用高云eda初始化sram
mi:
	$(MAKE) -C $(base_dir)/software mi
#--------------------------------------------------------------------
# Build rules
#--------------------------------------------------------------------

VCS = vcs -full64 -LDFLAGS -Wl,--no-as-needed

VCS_OPTS = -line +lint=all,noVCDE,noONGS,noUI,noNS,noOUDPE -error=PCWM-L -timescale=1ns/1ns -quiet \
	+rad +v2k +vcs+lic+wait \
	+vc+list -CC "-I$(VCS_HOME)/include" \
	-sverilog +v2k \
	+incdir+$(soc)/perip/spi/rtl \
	+incdir+$(soc)/perip/uart16550/rtl \
	+incdir+$(IP)/open-la500 \
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
	-debug_acc+pp+f+fn+dmptf -debug_region+cell+encrypt > build.log
	./simv_soc

#--------------------------------------------------------------------
# Run
#--------------------------------------------------------------------

seed = $(shell date +%s)
exec_simv = $(simv) +permissive -q +ntb_random_seed_automatic +permissive-off


run: verilog $(simv)

verdi:
	verdi $(sim_vsrcs) -ssf $(simv).fsdb \
	+incdir+$(soc)/perip/spi/rtl \
	+incdir+$(soc)/perip/uart16550/rtl \
	+incdir+$(IP)/open-la500 \
	&

clean:
	rm -rf $(output_dir) simv* csrc *.key DVE* *.h *.a *.daidir verdiLog *.conf *.rc *.log

.PHONY: run clean verilog
