# **********************************************
# Tools
# **********************************************
CROSS_COMPILE= ../toolchains/loongarch32r-linux-gnusf*/bin/loongarch32r-linux-gnusf-

CC        = $(CROSS_COMPILE)gcc
LD        = $(CROSS_COMPILE)ld
OBJCOPY   = $(CROSS_COMPILE)objcopy
OBJDUMP   = $(CROSS_COMPILE)objdump
STRIP     = $(CROSS_COMPILE)strip
SIZE	  = $(CROSS_COMPILE)size

# **********************************************
# Directories
# **********************************************
ifeq ($(PROG),)
    $(error program variable is not set)
endif

ABS_PROG =$(abspath $(PROG))
BUILD_DIR = $(ABS_PROG)/build
IMAGENAME = $(notdir $(PROG))


# **********************************************
# Image file names and map file
# **********************************************
IMAGE_ELF = $(BUILD_DIR)/$(IMAGENAME).elf
IMAGE_BIN = $(BUILD_DIR)/$(IMAGENAME).bin
IMAGE_MAP = $(BUILD_DIR)/$(IMAGENAME).map
IMAGE_S   = $(BUILD_DIR)/$(IMAGENAME).s

# **********************************************
# Compiler and linker options
# **********************************************
INCLUDE	+= 


FLAGS   = -std=gnu99 -O0 -ffunction-sections -fdata-sections -msoft-float -fsched-pressure -fno-builtin

CC_OPTS	 = $(DEBUG) $(FLAGS) $(INCLUDE) 
CC_COPTS = $(DEBUG) $(FLAGS) $(INCLUDE) 

LD_SCRIPT = $(ABS_PROG)/ld.script
LD_OPTS   = -G 0 -static -T $(LD_SCRIPT) -Map $(IMAGE_MAP) --gc-sections

# **********************************************
# Files to be compiled
# **********************************************
SRC_C  = $(foreach dir, $(ABS_PROG), $(wildcard $(dir)/*.c))
SRC_S  = $(foreach dir, $(ABS_PROG), $(wildcard $(dir)/*.S))
SRC    = $(SRC_C) $(SRC_S)
OBJ_C  = $(addprefix build/, $(notdir $(patsubst %.c, %.o, $(SRC_C))))
OBJ_S  = $(addprefix build/, $(filter-out start.o, $(notdir $(patsubst %.S, %.o, $(SRC_S)))))
LS1C1X_OBJ = $(OBJ_S) $(OBJ_C)


# **********************************************
# Rules
# **********************************************


.PHONY : all
all : $(IMAGE_BIN) 
$(IMAGE_BIN):$(LS1C1X_OBJ) 
	$(LD) $(LD_OPTS) -o $(IMAGE_ELF) $^ -Map $(IMAGE_MAP)
	$(OBJCOPY) -O binary $(IMAGE_ELF) $(IMAGE_BIN)
	$(SIZE) $(IMAGE_ELF)
	$(OBJDUMP) -alD $(IMAGE_ELF) > $(IMAGE_S)

$(OBJ_C) :%.o : %.c 
	$(CC) $(CC_COPTS) -c -o $@ $^

$(OBJ_S) : %.o : %.S
	$(CC) $(CC_OPTS) -c -o $@ $^


.PHONY : clean 
clean :
	rm -rf $(BUILD_DIR)/*