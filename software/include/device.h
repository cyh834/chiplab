#ifndef DEVICE_H__
#define DEVICE_H__

#include <loongarch32r.h>

// SRAM
#define SRAM_BASE 0x1c000000
#define SRAM_SIZE 0x40000
#define SRAM_BEGIN SRAM_BASE
#define SRAM_END (SRAM_BASE + SRAM_SIZE)

// GPIO
#define GPIO_BASE 0x1fd10000
#define GPIO_SIZE 0x10
#define GPIO_BEGIN GPIO_BASE
#define GPIO_END (GPIO_BASE + GPIO_SIZE)

#define LED_ADDR GPIO_BASE
#define LED_NUM 6
#define BTN_ADDR (GPIO_BASE + 0x4)
#define BTN_NUM 4

// Timer
#define TIMER_BASE 0xbfed0000
#define TIMER_SIZE 0x10
#define TIMER_BEGIN TIMER_BASE
#define TIMER_END (TIMER_BASE + TIMER_SIZE)

typedef struct{
  volatile unsigned int cfg;
  volatile unsigned int cnt;
  volatile unsigned int cmp;
  volatile unsigned int step;
} HW_TIMER_t;

typedef struct{
  volatile unsigned char en;      // 0x00 中断使能寄存器. 1= 中断使能
  volatile unsigned char edge;    // 0x01 中断边沿寄存器. 1 ，0= 边沿，电平触发
  volatile unsigned char pol;     // 0x02 中断极性寄存器. 1= 高电平/ 上升沿触发
  volatile unsigned char clr;     // 0x03 中断清除寄存器. 写1 清除中断状态
  volatile unsigned char set;     // 0x04 中断置位寄存器. 边沿模式下写1 置位
  volatile unsigned char out;     // 0x05 中断输出寄存器. 1= 中断触发
  volatile unsigned char srprot;  // 0x06 运行状态及保护寄存器
} HW_INTC_t;

#define g_timer ((HW_TIMER_t *)TIMER_BASE) // 获取定时器寄存器
#define intc    ((HW_INTC_t  *)INTC_BASE)  // 获取中断寄存器


#endif