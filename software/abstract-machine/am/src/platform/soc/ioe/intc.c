#include <am.h>
#include <soc.h>
#include <klib.h>
#include <klib-macros.h>

#define INTC_EN     (INTC_ADDR + 0x00)
#define INTC_EDGE   (INTC_ADDR + 0x01)
#define INTC_POL    (INTC_ADDR + 0x02)
#define INTC_CLR    (INTC_ADDR + 0x03)
#define INTC_SET    (INTC_ADDR + 0x04)
#define INTC_OUT    (INTC_ADDR + 0x05)
#define INTC_SRPROT (INTC_ADDR + 0x06) //硬件未实现

void __am_intc_init(){
  outb(INTC_EN, 0x0);
}

void __am_intc_config(AM_INTC_CONFIG_T * cfg){
  outb(INTC_EN, cfg->en);
  //其他配置以后再说
}

void __am_intc_clear(AM_INTC_CLEAR_T * clr){
  outb(INTC_CLR, clr->mask);
}