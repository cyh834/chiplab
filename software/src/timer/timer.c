#include <stdio.h>
#include <stdint.h>
#include <loongarch32r.h>
#include <device.h>

void timer_interrupt()
{
  // 定时器配置、中断配置如下
  g_timer->cfg = 0; // 定时器配置复位
  g_timer->cnt = 0; // 定时器计数值清空

  g_timer->cmp = 50000000; // 首次进入定时器中断的计数次数为 50M

  g_timer->step = 8000000;

  g_timer->cfg = 0x07;
  intc->en |= 0x01;
  // 开启周期触发，中断使能，开始计数
  // 开启定时器全局中断
}

volatile int state = 0;
void intc_handler(void)
{
  uint8_t IntReg = INT_OUT;
  if (IntReg & IRQ_TIMER) // Timer
  {
    if (TIM_GetITStatus(TIM_FLAG_Trigger))
    {
      // state = ~state;// false
      state = !state; // right
      gpio_write(20, state);
      TIM_ClearIT(TIM_FLAG_Trigger);
    }
  }
  INT_CLR = 0xff;
}

int main()
{
  //启用定时器中断
  timer_interrupt();
  while(1);
  return 0;
}
