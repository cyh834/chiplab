AM_SRCS := platform/soc/trm.c \
           platform/soc/ioe/ioe.c \
           platform/soc/ioe/timer.c \
           platform/soc/ioe/input.c \
           platform/soc/ioe/gpu.c \
           platform/soc/ioe/audio.c \
           platform/soc/ioe/disk.c \
           platform/soc/ioe/gpio.c \
					 platform/soc/ioe/uart.c \
					 platform/soc/ioe/intc.c \
           platform/soc/mpe.c 

CFLAGS    += -fdata-sections -ffunction-sections

##LDFLAGS   += -T $(AM_HOME)/scripts/linker.ld \
	             --defsym=_pmem_start=0x1c000000 --defsym=_entry_offset=0x0
##LDFLAGS		+= -T $(AM_HOME)/scripts/linker_ddr.ld
LDFLAGS		+= -T $(AM_HOME)/scripts/linker_flash.ld 

LDFLAGS   += --gc-sections -e _start -Map $(IMAGE).map
##$(eval NAVY := $(shell find -L $(NAVY_HOME)/fsimg/bin -type f))

CFLAGS += -DMAINARGS=\"$(mainargs)\"
CFLAGS += -I$(AM_HOME)/am/src/platform/soc/include

LIBGCC += $(TOOLCHAINS)/loongarch32r-linux-gnusf-v2.0/lib/gcc/loongarch32r-linux-gnusf/8.3.0/libgcc.a

.PHONY: $(AM_HOME)/am/src/platform/soc/trm.c

image: $(IMAGE).elf
	@$(OBJDUMP) -alD $(IMAGE).elf > $(IMAGE).txt
	@echo + OBJCOPY "->" $(IMAGE_REL).bin
	@$(OBJCOPY) -S --set-section-flags .bss=alloc,contents -O binary $(IMAGE).elf $(IMAGE).bin
	@hexdump -v -e '1/4 "%08x" "\n"' $(IMAGE).bin > $(IMAGE).mem
	@$(SIZE) $(IMAGE).elf

mi: image
	@bin2coe -i $(IMAGE).bin -w 32 -o $(IMAGE).coe
	@mkdir -p $(UTILS_HOME)/build
	@gcc $(UTILS_HOME)/coe2mi.c -o $(UTILS_HOME)/build/coe2mi
	@$(UTILS_HOME)/build/coe2mi -i $(IMAGE).coe -o $(IMAGE).mi -w 32 -d 65536  

run:mi 
	$(MAKE) -C $(SIM_HOME) run IMG=$(IMAGE)

verdi:
	$(MAKE) -C $(SIM_HOME) verdi IMG=$(IMAGE)