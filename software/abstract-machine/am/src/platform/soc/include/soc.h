#ifndef SOC_H__
#define SOC_H__

#include <klib-macros.h>

#include ISA_H // the macro `ISA_H` is defined in CFLAGS
               // it will be expanded as "x86/x86.h", "mips/mips32.h", ...

#if defined(__ISA_LOONGARCH32R__)
# define soc_trap(code) asm volatile("move $a0, %0; break 0" : :"r"(code))
#elif
# error unsupported ISA __ISA__
#endif

#define GPIO_ADDR          0xa0000000
#define TIMER_ADDR         0xa0010000
#define INTC_ADDR          0xa0020000
#define UART_ADDR          0xa0030000
#define FLASH_ADDR         0x1c000000
#define SRAM_ADDR          0x1b000000
//#define SDRAM_ADDR         0x40000000

#define SPI_master_ADDR    0x10001000

#define KBD_ADDR           0x0
#define RTC_ADDR           0x0
#define AUDIO_ADDR         0x0
#define SCREEN_ADDR        0x0
#define FB_ADDR            0x0

extern char _ram_start, _ram_end;
#define RAM_START ((uintptr_t)&_ram_start)
#define RAM_END  ((uintptr_t)&_ram_end)

#define SOC_PADDR_SPACE RANGE(RAM_START, RAM_END)
 //RANGE(FB_ADDR, FB_ADDR + 0x200000), 
 //RANGE(MMIO_BASE, MMIO_BASE + 0x1000) /* serial, rtc, screen, keyboard */

typedef uintptr_t PTE;

#define PGSIZE    4096

#endif
