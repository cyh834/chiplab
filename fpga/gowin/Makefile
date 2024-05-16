project_dir=system_run/jcs

FS= $(project_dir)/impl/pnr/jcs.fs
BIN= /home/cyh/chiplab/software/am-kernels/tests/soc-tests/build/ddr_test-loongarch32r-soc.bin 
## FS= $(project_dir)/impl/pnr/ao_0.fs

openFPGALoader_dir=../../toolchains/openFPGALoader
openFPGALoader=$(openFPGALoader_dir)/build/openFPGALoader

detect:
	sudo $(openFPGALoader) --detect

install:
	sudo $(openFPGALoader) -b tangmega138k -f $(FS)

program:
	sudo $(openFPGALoader) -b tangmega138k --external-flash $(BIN) $(FS)
