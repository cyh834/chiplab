

verilog:
	$(MAKE) -C soc verilog

clean:
	$(MAKE) -C soc clean

mill_install:
	sh -c "curl -L https://github.com/com-lihaoyi/mill/releases/download/0.11.6/0.11.6 > /usr/local/bin/mill && chmod +x /usr/local/bin/mill"

dev-init:
	$(MAKE) -C soc dev-init

.PHONY: verilog clean