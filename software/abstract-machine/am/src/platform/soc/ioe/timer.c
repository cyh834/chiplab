#include <am.h>
#include <soc.h>
#include <klib.h>
#include <klib-macros.h>

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

void __am_timer_init() {
    outl(TIMER_CFG, 0);// 定时器配置复位
    outl(TIMER_CNT, 0);// 定时器计数值清空

    //outl(TIMER_CMP, 50000000);// 首次进入定时器中断的计数次数为 50M
    //outl(TIMER_STEP, 8000000);

    //outl(TIMER_CFG, 0x07);// 开启周期触发，中断使能，开始计数
}
