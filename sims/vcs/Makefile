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
	$(shell find $(gowin)/gowin_ip/ -name "*.v" -or -name "*.vo" -not -name "SRAM_SDPB_tmp.v") \

sim_vsrcs = \
	$(TB) \
	$(shell find $(gowin)/gowin_sim_ip/ -name "*.v" -or -name "*.vo") \
  $(shell find $(soc)/perip -name "*.v" -or -name "*.sv") \
	$(bb_vsrcs)

sim_csrcs ?=

MEM_HEX = '"$(IMG).mem"'
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

clean_mi:
	$(MAKE) -C $(base_dir)/software clean

#自动删除生成IP的示例文件
deltmp:
	-rm -f $(base_dir)/fpga/gowin/gowin_ip/gowin_sdpb/SRAM_SDPB_tmp.v
#--------------------------------------------------------------------
# Build rules
#--------------------------------------------------------------------

VCS = vcs -full64 -LDFLAGS -Wl,--no-as-needed

VCS_OPTS = -line +lint=all -timescale=1ns/1ns -quiet \
	+rad +v2k +vcs+lic+wait \
	+vc+list -CC "-I$(VCS_HOME)/include" \
	-sverilog +v2k \
	+incdir+$(soc)/perip/spi/rtl \
	+incdir+$(soc)/perip/uart16550/rtl \
	+incdir+$(IP)/open-la500 \
	+incdir+$(soc)/perip/sdram \
	+define+CLOCK_PERIOD=20 $(sim_vsrcs) $(sim_csrcs) \
	+define+RANDOMIZE_MEM_INIT \
	+define+RANDOMIZE_GARBAGE_ASSIGN \
	+define+RANDOMIZE_INVALID_ASSIGN \
	+define+RANDOMIZE_DELAY=0.1 \
	+define+MEM_HEX=$(MEM_HEX) \
	+libext+.v \
	-top tb

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


run: clean verilog $(simv)

verdi:
	verdi $(sim_vsrcs) -ssf $(simv).fsdb \
	+incdir+$(soc)/perip/spi/rtl \
	+incdir+$(soc)/perip/uart16550/rtl \
	+incdir+$(IP)/open-la500 \
	&

clean:
	rm -rf $(output_dir) simv* csrc *.key DVE* *.h *.a *.daidir verdiLog *.conf *.rc *.log

.PHONY: run clean verilog
