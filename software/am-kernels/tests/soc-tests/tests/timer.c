#include "trap.h"

//开启定时器中断
void timer_interrupt()
{
  AM_TIMER_CONFIG_T g_timer;
  // 定时器配置、中断配置如下
  g_timer.cfg = 0; // 定时器配置复位
  g_timer.cnt = 0; // 定时器计数值清空

  //sim
  //g_timer.cmp = 50000; 
  //g_timer.step = 80000;

  //fpga
  g_timer.cmp = 16000000;
  g_timer.step = 8000000;

  ioe_write(AM_TIMER_CONFIG, &g_timer);

  g_timer.cfg = 0x07;// 开启周期触发，中断使能，开始计数
  ioe_write(AM_TIMER_CONFIG, &g_timer);

  AM_INTC_CONFIG_T intc;
  intc.en = 0x01;// 开启定时器全局中断
  ioe_write(AM_INTC_CONFIG, &intc);
}

//中断异常处理函数
volatile uint32_t state = 0x0;
static Context* do_event(Event e, Context* c) {
  Context* next = c;
  switch (e.event) {
    case EVENT_IRQ_TIMER:
      if(io_read(AM_TIMER_CHECKIRQ).set){
        state = (state == 0) ? 0x3f : 0x0;
        io_write(AM_GPIO_WRITE, state);
        io_write(AM_TIMER_CLEARIRQ, 0xff);
        //printf("In timer interrupt handler\n");
      }
      break;
    default: while(1);
  }
  
  io_write(AM_INTC_CLEAR, 0x01);
  return next;
}


int main()
{
  cte_init(do_event);

  iset(true);
  timer_interrupt();
  while(1);
  return 0;
}
