#include "trap.h"

#define DDR_BEGIN  0x20000000 + 0x10000
#define DDR_END    0x20000000 + 0x11000

static inline uint8_t  inb(uintptr_t addr) { return *(volatile uint8_t  *)addr; }
static inline uint16_t inw(uintptr_t addr) { return *(volatile uint16_t *)addr; }
static inline uint32_t inl(uintptr_t addr) { return *(volatile uint32_t *)addr; }

static inline void outb(uintptr_t addr, uint8_t  data) { *(volatile uint8_t  *)addr = data; }
static inline void outw(uintptr_t addr, uint16_t data) { *(volatile uint16_t *)addr = data; }
static inline void outl(uintptr_t addr, uint32_t data) { *(volatile uint32_t *)addr = data; }

int main(){
  for(int i = DDR_BEGIN; i < DDR_END; i += 4) {
      outl(i, i);
  }
  for(int i = DDR_BEGIN; i < DDR_END; i += 4) {
      int in = inl(i);
      if(in != i) {
          return -1;
      }
  }
  return 0;
}