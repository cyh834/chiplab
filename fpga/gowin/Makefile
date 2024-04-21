project=jcs
project_dir=system_run/jcs

FS= $(project_dir)/impl/pnr/$(project).fs

openFPGALoader=../../toolchains/openFPGALoader/build/openFPGALoader

detect:
	sudo $(openFPGALoader) --detect

install:
	sudo $(openFPGALoader) -b tangmega138k -f $(FS)

