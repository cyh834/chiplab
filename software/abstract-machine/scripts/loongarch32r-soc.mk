include $(AM_HOME)/scripts/isa/loongarch32r.mk
include $(AM_HOME)/scripts/platform/soc.mk
CFLAGS  += -DISA_H=\"loongarch/loongarch32r.h\"

AM_SRCS += loongarch/soc/start.S \
           loongarch/soc/cte.c \
           loongarch/soc/trap.S \
           loongarch/soc/vme.c
