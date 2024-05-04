#include <am.h>
#include <soc.h>
#include <klib.h>
#include <klib-macros.h>

//定时器
#define TIMER_CFG  (TIMER_ADDR+0x00)
#define TIMER_CNT  (TIMER_ADDR+0x04)
#define TIMER_CMP  (TIMER_ADDR+0x08)
#define TIMER_STEP (TIMER_ADDR+0x0C)

void __am_timer_config(AM_TIMER_CONFIG_T *cfg) {
    outl(TIMER_CNT, cfg->cnt);
    outl(TIMER_CMP, cfg->cmp);
    outl(TIMER_STEP, cfg->step);
    outl(TIMER_CFG, cfg->cfg);
}

void __am_timer_checkirq(AM_TIMER_CHECKIRQ_T * irq){
    irq->set = inl(TIMER_CFG)&0x100;
}

void __am_timer_clearirq(AM_TIMER_CLEARIRQ_T * clr){
    outl(TIMER_CFG,inl(TIMER_CFG)|0x100);
}



//cpu内部计时器
static uint64_t boot_time = 0;

static uint64_t read_time() {
    // 获取计数器中的值
    uint32_t tem_count = 0;
    asm volatile("rdtimel.w	%0, $r0":"=r" (tem_count));
    return tem_count;
}

void __am_timer_uptime(AM_TIMER_UPTIME_T *uptime) {
  uptime->us = (read_time() - boot_time) / 25;  //25MHz
  //uptime->us = 0;
}

void __am_timer_rtc(AM_TIMER_RTC_T *rtc) {
  rtc->second = 0;
  rtc->minute = 0;
  rtc->hour   = 0;
  rtc->day    = 0;
  rtc->month  = 0;
  rtc->year   = 1900;
}

void __am_timer_init() {
    outl(TIMER_CFG, 0);// 定时器配置复位
    outl(TIMER_CNT, 0);// 定时器计数值清空

    //outl(TIMER_CMP, 50000000);// 首次进入定时器中断的计数次数为 50M
    //outl(TIMER_STEP, 8000000);

    //outl(TIMER_CFG, 0x07);// 开启周期触发，中断使能，开始计数

    //open_count
    asm ("li.w $r12, 0x10; csrxchg $r0, $r12, 0xaf;":::"$r12");
    boot_time = read_time();// 获取当前时间

    //close_count
    //asm ("li.w $r12, 0x10; csrxchg $r12, $r12, 0xaf;":::"$r12");
}
