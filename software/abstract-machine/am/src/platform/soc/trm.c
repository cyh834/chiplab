#include <am.h>
#include <string.h>
#include <stdio.h>
#include <soc.h>

extern char _heap_start;

//extern char p_start, p_load_start, p_load_end;
//
//extern char _ram_start;
//
//extern char _ssbl_start, _ssbl_load_start, _ssbl_load_end;
//
//extern char _bss_start,  _bss_end;


int main(const char *args);

Area heap = RANGE(&_heap_start, RAM_END);
#ifndef MAINARGS
#define MAINARGS ""
#endif
static const char mainargs[] = MAINARGS;

void putch(char ch) {
  io_write(AM_UART_TX, ch);
}

void halt(int code) {
  soc_trap(code);

  // should not reach here
  while (1);
}

////将数据段加载到内存
//void putch_num(size_t num){
//  //char hex[16] = "0123456789abcdef";
//  char ans[20];
//  int cnt=0;
//  while(num){
//    if(num%16<10)
//      ans[cnt++]=num%16+'0';
//    else
//      ans[cnt++]=num%16-10+'a';
//    num/=16;
//  }
//  for(int i=0;i<cnt;i++){
//    putch(ans[cnt-i-1]);
//  }
//  putch('\n');
//}

#pragma GCC push_options
#pragma GCC optimize("O0")
//void fsbl(){
//  volatile uint32_t *prog = (volatile uint32_t *)&_ssbl_start;
//  volatile uint32_t *pmem = (volatile uint32_t *)&_ssbl_load_start;
//  while((uint32_t)pmem < (uint32_t)&_ssbl_load_end){
//    *pmem++ = *prog++;
//  }
//}
//
//void ssbl() {
//
//  volatile uint32_t *prog = (volatile uint32_t *)&p_start;
//  volatile uint32_t *pmem = (volatile uint32_t *)&p_load_start;
//  while((uint32_t)pmem < (uint32_t)&p_load_end){
//    *pmem++ = *prog++;
//  }
//}
//
//void _init_bss(){
//  char* iteration = &_bss_start;
//  
//  while (iteration != &_bss_end)
//  {
//    *iteration = 0;
//    iteration++;
//  }
//  
//}

#pragma GCC pop_options

void _trm_init() {
  //fsbl();
  //ssbl();
  //_init_bss();
  //printf("heap: [%p, %p]\n", heap.start, heap.end);
  ioe_init();
  int ret = main(mainargs);
  halt(ret);
}