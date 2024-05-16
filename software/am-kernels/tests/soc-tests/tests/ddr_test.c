#include "trap.h"

#define DDR_BEGIN  0x40000000
#define DDR_END    0x40000000 + 0x20000000

static inline uint8_t  inb(uintptr_t addr) { return *(volatile uint8_t  *)addr; }
static inline uint16_t inw(uintptr_t addr) { return *(volatile uint16_t *)addr; }
static inline uint32_t inl(uintptr_t addr) { return *(volatile uint32_t *)addr; }

static inline void outb(uintptr_t addr, uint8_t  data) { *(volatile uint8_t  *)addr = data; }
static inline void outw(uintptr_t addr, uint16_t data) { *(volatile uint16_t *)addr = data; }
static inline void outl(uintptr_t addr, uint32_t data) { *(volatile uint32_t *)addr = data; }

int main(){
    //volatile uint32_t state = 0b000001;
    //io_write(AM_GPIO_WRITE, ~state);
    //state++;
    //outl(DDR_BEGIN, state);

    //while(1){
    //    uint32_t in = inl(DDR_BEGIN);
    //    io_write(AM_GPIO_WRITE, ~in);
    //    for(volatile int i=0;i<1000000;i++);
    //    state++;
    //    io_write(AM_GPIO_WRITE, ~state);
    //    outl(DDR_BEGIN, state);
    //    for(volatile int i=0;i<1000000;i++);
    //}
    //return 0;
    
    uint32_t num = 0;
    io_write(AM_GPIO_WRITE, 0);
    while(1){
        outl(DDR_BEGIN, num);
        outl(DDR_BEGIN+4, 0x44444444);
        outl(DDR_BEGIN+8,  0x88888888);
        outl(DDR_BEGIN+12, 0x12121212);
        outl(DDR_BEGIN+16, 0x16161616);
        outl(DDR_BEGIN+20, 0x20202020);
        outl(DDR_BEGIN+24, 0x24242424);
        outl(DDR_BEGIN+28, 0x28282828);

        io_write(AM_GPIO_WRITE, num);
        uint32_t in = inl(DDR_BEGIN);
        printf("num:%d %x\n",num, in);
        num++;
        for(volatile int i=0;i<1000000;i++);
    }
}