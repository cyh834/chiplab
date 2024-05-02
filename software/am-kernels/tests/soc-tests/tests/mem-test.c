#include "trap.h"

#define SRAM_BEGIN 0x1c000000
#define SRAM_END   0x1c040000

static inline uint8_t  inb(uintptr_t addr) { return *(volatile uint8_t  *)addr; }
static inline uint16_t inw(uintptr_t addr) { return *(volatile uint16_t *)addr; }
static inline uint32_t inl(uintptr_t addr) { return *(volatile uint32_t *)addr; }

static inline void outb(uintptr_t addr, uint8_t  data) { *(volatile uint8_t  *)addr = data; }
static inline void outw(uintptr_t addr, uint16_t data) { *(volatile uint16_t *)addr = data; }
static inline void outl(uintptr_t addr, uint32_t data) { *(volatile uint32_t *)addr = data; }

int main() {
    //前面存放代码段什么的，不能覆盖
    for(int i = SRAM_BEGIN+0x20000; i < SRAM_END; i += 4) {
        outl(i, i);
    }
    for(int i = SRAM_BEGIN+0x20000; i < SRAM_END; i += 4) {
        int in = inl(i);
        if(in != i) {
            return -1;
        }
    }
    return 0;
}
