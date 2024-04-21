

verilog:
	$(MAKE) -C soc verilog

clean:
	$(MAKE) -C soc clean

dev-init:
	$(MAKE) -C soc dev-init

.PHONY: verilog clean