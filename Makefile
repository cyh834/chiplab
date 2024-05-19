
verilog:
	$(MAKE) -C soc verilog

clean:
	$(MAKE) -C soc clean

tool_install:
	sudo apt update
	sudo apt install proxychains4 shadowsocks-libev vim wget git tmux make gcc time curl libreadline6-dev libsdl2-dev openjdk-11-jre zlib1g-dev device-tree-compiler flex autoconf bison sqlite3 libsqlite3-dev zstd libzstd-dev
	sudo sh -c "curl -L https://github.com/com-lihaoyi/mill/releases/download/0.11.6/0.11.6 > /usr/local/bin/mill && chmod +x /usr/local/bin/mill"
	pip install bin2coe opencv-python

dev-init:
	$(MAKE) -C soc dev-init

init: tool_install dev-init

.PHONY: verilog clean tool_install dev-init init