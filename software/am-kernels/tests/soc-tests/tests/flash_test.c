#include "trap.h"

#define FLASH_BEGIN  0x00000000
#define FLASH_END    0x00000000 + 0x10000000

static inline uint8_t  inb(uintptr_t addr) { return *(volatile uint8_t  *)addr; }
static inline uint16_t inw(uintptr_t addr) { return *(volatile uint16_t *)addr; }
static inline uint32_t inl(uintptr_t addr) { return *(volatile uint32_t *)addr; }

static inline void outb(uintptr_t addr, uint8_t  data) { *(volatile uint8_t  *)addr = data; }
static inline void outw(uintptr_t addr, uint16_t data) { *(volatile uint16_t *)addr = data; }
static inline void outl(uintptr_t addr, uint32_t data) { *(volatile uint32_t *)addr = data; }

int main(){
    for(uint32_t i = FLASH_BEGIN; i < FLASH_END; i+=4){
        uint32_t in = inl(i);
        printf("addr:0x%x data:%x\n",i, in);
        for(volatile int i=0;i<1000000;i++);
    }
}