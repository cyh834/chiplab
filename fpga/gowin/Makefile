project=jcs
project_dir=system_run/jcs

FS= $(project_dir)/impl/pnr/$(project).fs

openFPGALoader_dir=../../toolchains/openFPGALoader
openFPGALoader=$(openFPGALoader_dir)/build/openFPGALoader

detect:
	sudo $(openFPGALoader) --detect

install:
	sudo $(openFPGALoader) -b tangmega138k -f $(FS)
