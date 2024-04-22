## 1. Basic Setup and Checks
NAME ?= led

### Check: environment variable `$NAME` must be in the supported list
NAMES = $(basename $(notdir $(shell ls ./src)))
ifeq ($(filter $(NAMES), $(NAME)), )
  $(error Expected $$NAME in {$(NAMES)}, Got "$(NAME)")
endif

## 2. General Compilation Targets:

### Create the destination directory (`build/$NAME`)
WORK_DIR  = $(shell pwd)
DST_DIR   = $(WORK_DIR)/build/$(NAME)
$(shell mkdir -p $(DST_DIR))

### Compilation targets (a binary image or archive)
IMAGE_REL = $(WORK_DIR)/build/$(NAME)
IMAGE     = $(abspath $(IMAGE_REL))
IMAGE_MAP = $(WORK_DIR)/build/$(NAME).map


### Collect the files to be linked: object files (`.o`) and libraries (`.a`)
SRCS = $(shell find src/$(NAME) -name "*.c" -or -name "*.cc" -or -name "*.cpp" -or -name "*.S")
OBJS      = $(addprefix $(DST_DIR)/, $(addsuffix .o, $(basename $(SRCS))))
LIBS = ../toolchains/system_newlib/
LINKAGE   = $(OBJS)

LD_SCRIPT = ./src/$(NAME)/ld.script

## 3. General Compilation Flags

CROSS_COMPILE_DIR = ../toolchains/loongarch32r-linux-gnusf-v2.0
CROSS_COMPILE=  $(CROSS_COMPILE_DIR)/bin/loongarch32r-linux-gnusf-

AS        = $(CROSS_COMPILE)gcc
CC        = $(CROSS_COMPILE)gcc
CXX       = $(CROSS_COMPILE)g++
LD        = $(CROSS_COMPILE)ld
AR        = $(CROSS_COMPILE)ar
OBJCOPY   = $(CROSS_COMPILE)objcopy
OBJDUMP   = $(CROSS_COMPILE)objdump
READELF   = $(CROSS_COMPILE)readelf
STRIP     = $(CROSS_COMPILE)strip
SIZE	  = $(CROSS_COMPILE)size


### Compilation flags

INC_PATH += $(CROSS_COMPILE_DIR)/lib/gcc/loongarch32r-linux-gnusf/8.3.0/include \
						../toolchains/system_newlib/loongarch32-unknown-elf/include
INCFLAGS += $(addprefix -I, $(INC_PATH))

COMMON_FLAGS  := -fno-pic
CFLAGS        += $(COMMON_FLAGS) 
ASFLAGS       += $(COMMON_FLAGS)

CFLAGS 	+= -std=gnu99 -O2 -ffunction-sections -fdata-sections -msoft-float -fsched-pressure -fno-builtin \
					  -MMD -Wall -Werror $(INCFLAGS) \
            -fno-asynchronous-unwind-tables  -fno-stack-protector \
            -Wno-main -U_FORTIFY_SOURCE -fvisibility=hidden -static -nostdlib -nostdinc 
CXXFLAGS +=  $(CFLAGS) -ffreestanding -fno-rtti -fno-exceptions
ASFLAGS  += -MMD -O0 $(INCFLAGS)
LDFLAGS  += -static -T $(LD_SCRIPT) -Map $(IMAGE_MAP) -L $(LIBS) ## --gc-sections

### Fall back to native gcc/binutils if there is no cross compiler
ifeq ($(wildcard $(shell which $(CC))),)
  $(error #  $(CC) not found)
endif

## 5. Compilation Rules

### Rule (compile): a single `.c` -> `.o` (gcc)
$(DST_DIR)/%.o: %.c
	@mkdir -p $(dir $@) && echo + CC $<
	@$(CC) -std=gnu11 $(CFLAGS) -c -o $@ $(realpath $<)

### Rule (compile): a single `.cc` -> `.o` (g++)
$(DST_DIR)/%.o: %.cc
	@mkdir -p $(dir $@) && echo + CXX $<
	@$(CXX) -std=c++17 $(CXXFLAGS) -c -o $@ $(realpath $<)

### Rule (compile): a single `.cpp` -> `.o` (g++)
$(DST_DIR)/%.o: %.cpp
	@mkdir -p $(dir $@) && echo + CXX $<
	@$(CXX) -std=c++17 $(CXXFLAGS) -c -o $@ $(realpath $<)

### Rule (compile): a single `.S` -> `.o` (gcc, which preprocesses and calls as)
$(DST_DIR)/%.o: %.S
	@mkdir -p $(dir $@) && echo + AS $<
	@$(AS) $(ASFLAGS) -c -o $@ $(realpath $<)

### Rule (link): objects (`*.o`) -> `IMAGE.elf`, the final ELF binary to be packed into image (ld)
$(IMAGE).elf: $(OBJS) $(LIBS)
	@echo + LD "->" $(IMAGE_REL).elf
	$(LD) $(LDFLAGS) -o $(IMAGE).elf --start-group $(LINKAGE) --end-group


## 6. Miscellaneous
### Build order control
image: image-dep
image-dep: $(OBJS) $(LIBS)
	@echo \# Creating image [$(NAME)]
.PHONY: image image-dep run $(LIBS)

### Clean a single project (remove `build/`)
clean:
	rm -rf $(WORK_DIR)/build/
.PHONY: clean

# **********************************************
# Image file names and map file
# **********************************************
image: $(IMAGE).elf
	@$(OBJDUMP) -alD $(IMAGE).elf > $(IMAGE).txt
	@echo + OBJCOPY "->" $(IMAGE).bin
	@$(OBJCOPY) -S --set-section-flags .bss=alloc,contents -O binary $(IMAGE).elf $(IMAGE).bin
	@$(SIZE) $(IMAGE).elf

mi: image
	bin2coe -i $(IMAGE).bin -w 32 -o $(IMAGE).coe
	gcc utils/coe2mi.c -o $(WORK_DIR)/build/coe2mi
## sram : 65536x32
	$(WORK_DIR)/build/coe2mi -i $(IMAGE).coe -o $(IMAGE).mi -w 32 -d 65536   


test:
	echo $(INCFLAGS)