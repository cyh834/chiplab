FINAL_V = rocket-chip/out/emulator/freechips.rocketchip.system.TestHarness/freechips.rocketchip.system.DefaultConfig/mfccompiler/compile.dest/TestHarness.sv
SOC_TOP_V = generated/soc_top.v
ROCKET_CHIP_SOC_PATH  = rocket-chip/src/main/scala/SoC

$(SOC_TOP_V):
	cp $(abspath soc)/* $(ROCKET_CHIP_SOC_PATH)
	$(MAKE) -C rocket-chip verilog
	cp $(FINAL_V) $@
	sed -i -e 's/_\(aw\|ar\|w\|r\|b\)_\(\|bits_\)/_\1/g' $@
	sed -i '/firrtl_black_box_resource_files.f/, $$d' $@

verilog: $(SOC_TOP_V)

clean:
	-$(MAKE) -C rocket-chip clean
	-rm $(SOC_TOP_V)

.PHONY: verilog $(SOC_TOP_V) clean