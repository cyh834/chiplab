#include "trap.h"

#define DDR_BEGIN  0x20000000
#define DDR_END    0x20000000 + 0x20000000

static inline uint8_t  inb(uintptr_t addr) { return *(volatile uint8_t  *)addr; }
static inline uint16_t inw(uintptr_t addr) { return *(volatile uint16_t *)addr; }
static inline uint32_t inl(uintptr_t addr) { return *(volatile uint32_t *)addr; }

static inline void outb(uintptr_t addr, uint8_t  data) { *(volatile uint8_t  *)addr = data; }
static inline void outw(uintptr_t addr, uint16_t data) { *(volatile uint16_t *)addr = data; }
static inline void outl(uintptr_t addr, uint32_t data) { *(volatile uint32_t *)addr = data; }

int main(){
    volatile uint32_t state = 0b000001;
    io_write(AM_GPIO_WRITE, state);
    state++;
    outl(DDR_BEGIN, state);

    while(1){
        uint32_t in = inl(DDR_BEGIN);
        io_write(AM_GPIO_WRITE, in);
        state++;
        outl(DDR_BEGIN, state);
        for(volatile int i=0;i<1000000;i++);
    }
    return 0;
}