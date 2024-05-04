#include <am.h>
#include <klib.h>
#include <klib-macros.h>
#include <stdarg.h>
#include <string.h>

#if !defined(__ISA_NATIVE__) || defined(__NATIVE_USE_KLIB__)


typedef struct
{
    uint32_t    begin;
    uint32_t    end;
} TIMER_COUNT;

typedef struct
{
    uint32_t    TimeStart;
    uint32_t    TimeInter;

} tsTimeType;

void delay_us(uint32_t x)  //us单位
{
  AM_TIMER_UPTIME_T begin = io_read(AM_TIMER_UPTIME);
  AM_TIMER_UPTIME_T end = io_read(AM_TIMER_UPTIME);

  printf("begin:%x\tend:%x\n",begin.us,end.us);
  while((end.us - begin.us) <= x){
    printf("begin:%x\tend:%x\n",begin.us,end.us);
    end = io_read(AM_TIMER_UPTIME);
  }
}

void delay_ms(uint32_t x)  	//ms单位
{
    delay_us(x * 1000);
}

void delay_s(uint32_t x)  	//s单位
{
    delay_ms(x * 1000); //8*1000*1000
}

#endif